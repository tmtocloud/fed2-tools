--[[
Shared Table Renderer for fed2-tools

Provides a declarative API for rendering formatted tables with automatic
column width calculation, styling, and data formatting.

Usage:
  f2t_render_table({
    columns = {
      {header = "Name", field = "name"},
      {header = "Age", field = "age", align = "right", format = "number"}
    },
    data = {
      {name = "Alice", age = 30},
      {name = "Bob", age = 25}
    }
  })
]]--

-- =============================================================================
-- BUILT-IN FORMATTERS
-- =============================================================================

-- Format large numbers compactly (1000 -> 1K, 1000000 -> 1.00M, 1000000000 -> 1.00B, 1000000000000 -> 1.00T)
function f2t_format_compact(num)
    if not num or type(num) ~= "number" then
        return tostring(num or "")
    end

    local sign = num < 0 and "-" or ""
    local n = math.abs(num)

    if n >= 1000000000000 then
        return string.format("%s%.2fT", sign, n / 1000000000000)
    elseif n >= 1000000000 then
        return string.format("%s%.2fB", sign, n / 1000000000)
    elseif n >= 1000000 then
        return string.format("%s%.2fM", sign, n / 1000000)
    elseif n >= 1000 then
        return string.format("%s%dK", sign, math.floor(n / 1000))
    else
        return sign .. tostring(n)
    end
end

-- Format decimal to percentage (0.75 -> 75%)
function f2t_format_percent(num)
    if not num or type(num) ~= "number" then
        return "0%"
    end
    return string.format("%d%%", math.floor(num * 100))
end

-- Format boolean to Y/N
function f2t_format_boolean(bool)
    return bool and "Y" or "N"
end

-- Map of format types to formatter functions
local FORMATTERS = {
    string = function(val) return tostring(val or "") end,
    number = function(val) return tostring(math.floor(val or 0)) end,
    compact = f2t_format_compact,
    percent = f2t_format_percent,
    boolean = f2t_format_boolean
}

-- =============================================================================
-- AGGREGATION FUNCTIONS
-- =============================================================================

local AGGREGATORS = {
    sum = function(values)
        local total = 0
        for _, v in ipairs(values) do
            if v ~= nil and type(v) == "number" then
                total = total + v
            end
        end
        return total
    end,

    avg = function(values)
        local total, count = 0, 0
        for _, v in ipairs(values) do
            if v ~= nil and type(v) == "number" then
                total = total + v
                count = count + 1
            end
        end
        return count > 0 and (total / count) or 0
    end,

    min = function(values)
        local min_val = nil
        for _, v in ipairs(values) do
            if v ~= nil and type(v) == "number" then
                if min_val == nil or v < min_val then
                    min_val = v
                end
            end
        end
        return min_val or 0
    end,

    max = function(values)
        local max_val = nil
        for _, v in ipairs(values) do
            if v ~= nil and type(v) == "number" then
                if max_val == nil or v > max_val then
                    max_val = v
                end
            end
        end
        return max_val or 0
    end,

    count = function(values)
        local count = 0
        for _, v in ipairs(values) do
            if v ~= nil then count = count + 1 end
        end
        return count
    end
}

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Strip color codes for width calculation
local function strip_colors(text)
    if not text then return "" end
    -- Remove Mudlet color codes like <green>, <reset>, etc.
    return text:gsub("<[^>]+>", "")
end

-- Align text within given width
function f2t_align_text(text, width, align)
    local stripped = strip_colors(text)
    local len = #stripped

    if len >= width then
        return stripped:sub(1, width)
    end

    local padding = width - len

    if align == "right" then
        return string.rep(" ", padding) .. text
    elseif align == "center" then
        local left_pad = math.floor(padding / 2)
        local right_pad = padding - left_pad
        return string.rep(" ", left_pad) .. text .. string.rep(" ", right_pad)
    else  -- left (default)
        return text .. string.rep(" ", padding)
    end
end

-- Apply color codes to text
function f2t_colorize_cell(text, color)
    if not color or color == "" then
        return text
    end
    return string.format("<%s>%s<reset>", color, text)
end

-- Format a cell value according to column configuration
function f2t_format_cell(value, column, row)
    -- Handle nil values
    if value == nil then
        return ""
    end

    -- Use custom formatter if provided
    if column.formatter then
        return tostring(column.formatter(value, row))
    end

    -- Use built-in formatter based on format type
    local format_type = column.format or "string"
    local formatter = FORMATTERS[format_type] or FORMATTERS.string
    local formatted = formatter(value)

    -- Handle truncation
    if column.truncate ~= false and column.max_width then
        local stripped = strip_colors(formatted)
        if #stripped > column.max_width then
            local ellipsis = column.ellipsis or "..."
            formatted = stripped:sub(1, column.max_width - #ellipsis) .. ellipsis
        end
    end

    return formatted
end

-- =============================================================================
-- WIDTH CALCULATION
-- =============================================================================

-- Calculate minimum width for a column
local function calculate_min_width(column, data)
    local min_w = column.min_width or #column.header

    -- If fixed width specified, use it as min
    if column.width then
        return column.width
    end

    return math.max(min_w, #column.header)
end

-- Calculate desired width from data content
local function calculate_content_width(column, data)
    -- If fixed width, return it
    if column.width then
        return column.width
    end

    local max_width = #column.header

    -- Sample first 20 rows
    local sample_size = math.min(20, #data)
    for i = 1, sample_size do
        local value = data[i][column.field]
        local formatted = f2t_format_cell(value, column, data[i])
        local stripped = strip_colors(formatted)
        max_width = math.max(max_width, #stripped)
    end

    -- Sample every 10th row for larger datasets
    if #data > 20 then
        for i = 30, #data, 10 do
            local value = data[i][column.field]
            local formatted = f2t_format_cell(value, column, data[i])
            local stripped = strip_colors(formatted)
            max_width = math.max(max_width, #stripped)
        end
    end

    -- Respect max_width if specified
    if column.max_width then
        max_width = math.min(max_width, column.max_width)
    end

    return max_width
end

-- Calculate optimal column widths (includes footer row if present)
function f2t_calculate_column_widths(columns, data, max_width, footer_row)
    local min_widths = {}
    local desired_widths = {}
    local fixed_columns = {}

    -- Calculate min and desired widths for each column
    for i, col in ipairs(columns) do
        if not col.hidden then
            min_widths[i] = calculate_min_width(col, data)
            desired_widths[i] = calculate_content_width(col, data)

            -- Also check footer row width if present
            if footer_row and footer_row[col.field] then
                local footer_value = footer_row[col.field]
                local formatted = f2t_format_cell(footer_value, col, footer_row)
                local stripped = strip_colors(formatted)
                desired_widths[i] = math.max(desired_widths[i], #stripped)
            end

            if col.width then
                fixed_columns[i] = true
            end
        else
            min_widths[i] = 0
            desired_widths[i] = 0
        end
    end

    -- Count visible columns for spacing
    local visible_count = 0
    for i, col in ipairs(columns) do
        if not col.hidden then
            visible_count = visible_count + 1
        end
    end

    -- Calculate total width needed (with spaces between columns)
    local spacing = visible_count > 1 and (visible_count - 1) or 0
    local total_desired = spacing
    for i, w in ipairs(desired_widths) do
        total_desired = total_desired + w
    end

    -- If we fit, use desired widths
    if total_desired <= max_width then
        return desired_widths
    end

    -- Otherwise, shrink flexible columns proportionally
    local final_widths = {}
    local fixed_total = spacing
    local flexible_indices = {}

    -- Calculate total width used by fixed columns
    for i, col in ipairs(columns) do
        if fixed_columns[i] then
            final_widths[i] = desired_widths[i]
            fixed_total = fixed_total + desired_widths[i]
        else
            table.insert(flexible_indices, i)
        end
    end

    -- Distribute remaining space to flexible columns
    local available = max_width - fixed_total

    if #flexible_indices > 0 then
        -- Calculate total desired width of flexible columns
        local flexible_total = 0
        for _, i in ipairs(flexible_indices) do
            flexible_total = flexible_total + desired_widths[i]
        end

        -- Distribute proportionally, respecting minimums
        for _, i in ipairs(flexible_indices) do
            local proportion = desired_widths[i] / flexible_total
            local allocated = math.floor(available * proportion)
            final_widths[i] = math.max(allocated, min_widths[i])
        end
    end

    return final_widths
end

-- =============================================================================
-- RENDERING FUNCTIONS
-- =============================================================================

-- Render a single row
function f2t_render_row(row, columns, widths)
    local parts = {}

    for i, col in ipairs(columns) do
        if not col.hidden then
            -- Get raw value
            local value = row[col.field]

            -- Format value
            local formatted = f2t_format_cell(value, col, row)

            -- Align text
            local align = col.align or "left"
            local aligned = f2t_align_text(formatted, widths[i], align)

            -- Apply color
            local color = col.color
            if col.color_fn then
                color = col.color_fn(value, row)
            end
            local colored = f2t_colorize_cell(aligned, color)

            table.insert(parts, colored)
        end
    end

    -- Join with spaces
    cecho(table.concat(parts, " ") .. "\n")
end

-- Calculate aggregations for footer
function f2t_calculate_aggregations(data, aggregations, columns)
    if not aggregations then
        return nil
    end

    local agg_row = {}

    for _, agg in ipairs(aggregations) do
        local field = agg.field
        local method = agg.method or "sum"
        local aggregator = AGGREGATORS[method]

        if aggregator then
            -- Collect values for this field
            local values = {}
            for _, row in ipairs(data) do
                table.insert(values, row[field])
            end

            -- Calculate aggregation
            agg_row[field] = aggregator(values)
        end
    end

    return agg_row
end

-- Render footer with aggregations
function f2t_render_footer(footer_config, agg_row, columns, widths)
    if not footer_config or not agg_row then
        return
    end

    local parts = {}

    for i, col in ipairs(columns) do
        if not col.hidden then
            local value = agg_row[col.field]

            if value ~= nil then
                -- Format the aggregated value
                local formatted = f2t_format_cell(value, col, agg_row)
                local align = col.align or "left"
                local aligned = f2t_align_text(formatted, widths[i], align)

                -- Apply color from aggregation config if provided
                local color = nil
                if footer_config.aggregations then
                    for _, agg in ipairs(footer_config.aggregations) do
                        if agg.field == col.field and agg.color_fn then
                            color = agg.color_fn(value, agg_row)
                            break
                        end
                    end
                end

                local colored = f2t_colorize_cell(aligned, color)
                table.insert(parts, colored)
            else
                -- Empty cell for non-aggregated columns
                table.insert(parts, string.rep(" ", widths[i]))
            end
        end
    end

    cecho(table.concat(parts, " ") .. "\n")
end

-- =============================================================================
-- MAIN RENDERING FUNCTION
-- =============================================================================

function f2t_render_table(config)
    -- Validate required fields
    if not config.columns or #config.columns == 0 then
        cecho("\n<red>[Table Renderer]<reset> Error: No columns defined\n")
        return
    end

    if not config.data then
        config.data = {}
    end

    -- Validate columns
    for i, col in ipairs(config.columns) do
        if not col.header then
            cecho(string.format("\n<red>[Table Renderer]<reset> Error: Column %d missing header\n", i))
            return
        end
        if not col.field then
            cecho(string.format("\n<red>[Table Renderer]<reset> Error: Column %d missing field\n", i))
            return
        end
    end

    -- Extract configuration
    local columns = config.columns
    local data = config.data
    local title = config.title
    local max_width = config.max_width or COLS or 100
    local show_header = config.show_header ~= false
    local show_separators = config.show_separators ~= false
    local separator_char = config.separator_char or "-"
    local header_color = config.header_color or "white"

    -- Calculate aggregations first (if configured) so we can include them in width calc
    local agg_row = nil
    if config.footer and config.footer.aggregations then
        agg_row = f2t_calculate_aggregations(data, config.footer.aggregations, columns)
    end

    -- Calculate column widths (including footer row if present)
    local widths = f2t_calculate_column_widths(columns, data, max_width, agg_row)

    -- Calculate table width for separators
    local table_width = 0
    for i, col in ipairs(columns) do
        if not col.hidden then
            table_width = table_width + widths[i]
        end
    end
    -- Add spaces between columns
    local visible_count = 0
    for _, col in ipairs(columns) do
        if not col.hidden then visible_count = visible_count + 1 end
    end
    if visible_count > 1 then
        table_width = table_width + (visible_count - 1)
    end

    -- Render title
    if title then
        cecho(string.format("\n<white>=== %s ===<reset>\n", title))
    end

    -- Render header
    if show_header then
        local header_parts = {}
        for i, col in ipairs(columns) do
            if not col.hidden then
                -- Headers use same alignment as data
                local aligned = f2t_align_text(col.header, widths[i], col.align or "left")
                local colored = f2t_colorize_cell(aligned, header_color)
                table.insert(header_parts, colored)
            end
        end
        cecho("\n" .. table.concat(header_parts, " ") .. "\n")

        if show_separators then
            cecho(string.rep(separator_char, table_width) .. "\n")
        end
    end

    -- Render data rows
    for _, row in ipairs(data) do
        f2t_render_row(row, columns, widths)
    end

    -- Bottom separator (always, not just for footer)
    if show_separators then
        cecho(string.rep(separator_char, table_width) .. "\n")
    end

    -- Render footer if configured
    if config.footer and config.footer.aggregations and agg_row then
        f2t_render_footer(config.footer, agg_row, columns, widths)
    end
end
