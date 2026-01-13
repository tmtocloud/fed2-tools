-- Factory Status Table Formatter
-- Uses shared table renderer for display

-- Prepare factory data for display by adding computed fields
function f2t_factory_prepare_for_display(factories)
    for _, factory in ipairs(factories) do
        if factory.missing then
            -- Skip calculations for missing factories
            factory.location = "(No factory)"
        else
            -- Calculate efficiency percentage
            factory.efficiency_pct = factory.efficiency_max > 0
                and math.floor((factory.efficiency / factory.efficiency_max) * 100)
                or 0

            -- Calculate workers percentage
            factory.workers_pct = factory.workers_required > 0
                and math.floor((factory.workers_hired / factory.workers_required) * 100)
                or 0

            -- Calculate storage used percentage
            factory.storage_pct = 0
            if factory.storage_max and factory.storage_max > 0 then
                factory.storage_pct = math.floor(
                    ((factory.storage_max - (factory.storage_available or 0)) / factory.storage_max) * 100
                )
                factory.storage_pct = math.max(0, math.min(100, factory.storage_pct))
            end

            -- Calculate income to expense ratio
            factory.income_expense_ratio = 0
            if factory.expenditure and factory.expenditure > 0 then
                factory.income_expense_ratio = factory.income / factory.expenditure
            end
        end
    end
    return factories
end

-- Display factory data as formatted table
function f2t_factory_display_table()
    local factories = f2t_factory.factories

    -- Count active (non-missing) factories
    local active_count = 0
    for _, factory in ipairs(factories) do
        if not factory.missing then
            active_count = active_count + 1
        end
    end

    if active_count == 0 then
        f2t_debug_log("[factory-status] No active factories found")
        cecho("\n<yellow>[Factory Status]<reset> No factories found.\n")
        return
    end

    f2t_debug_log("[factory-status] Displaying table for %d factories (%d active)", #factories, active_count)

    -- Prepare data with computed fields
    f2t_factory_prepare_for_display(factories)

    -- Helper to format missing values as "-"
    local function missing_dash(val, row)
        if row.missing then return "-" end
        return nil  -- Use default formatting
    end

    -- Helper for missing row color (dim_grey)
    local function missing_color(val, row)
        if row.missing then return "dim_grey" end
        return nil
    end

    -- Configure table (all columns left-aligned)
    local config = {
        title = "Factory Status",
        max_width = COLS or 100,
        columns = {
            {
                header = "#",
                field = "number",
                width = 2,
                format = "number",
                color_fn = missing_color
            },
            {
                header = "Location",
                field = "location",
                max_width = 15,
                truncate = true,
                color_fn = missing_color
            },
            {
                header = "Commodity",
                field = "commodity",
                max_width = 15,
                truncate = true,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return val
                end,
                color_fn = missing_color
            },
            {
                header = "St",
                field = "status",
                width = 2,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return val:sub(1, 1)
                end,
                color_fn = function(val, row)
                    if row.missing then return "dim_grey" end
                    return row.status == "Running" and "green" or "yellow"
                end
            },
            {
                header = "Cap",
                field = "working_capital",
                width = 5,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return f2t_format_compact(val)
                end,
                color_fn = missing_color
            },
            {
                header = "Inc",
                field = "income",
                width = 5,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return f2t_format_compact(val)
                end,
                color_fn = missing_color
            },
            {
                header = "Exp",
                field = "expenditure",
                width = 5,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return f2t_format_compact(val)
                end,
                color_fn = missing_color
            },
            {
                header = "P/L",
                field = "profit",
                width = 5,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return f2t_format_compact(val)
                end,
                color_fn = function(val, row)
                    if row.missing then return "dim_grey" end
                    return val >= 0 and "green" or "red"
                end
            },
            {
                header = "I/E",
                field = "income_expense_ratio",
                width = 4,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    if val == 0 then
                        return "-"
                    else
                        return string.format("%.2f", val)
                    end
                end,
                color_fn = function(val, row)
                    if row.missing then return "dim_grey" end
                    if val == 0 then
                        return "dim_grey"
                    elseif val > 1.0 then
                        return "green"
                    elseif val < 1.0 then
                        return "red"
                    else
                        return "yellow"
                    end
                end
            },
            {
                header = "Ef%",
                field = "efficiency_pct",
                width = 3,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return tostring(math.floor(val))
                end,
                color_fn = missing_color
            },
            {
                header = "Wk%",
                field = "workers_pct",
                width = 3,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return tostring(math.floor(val))
                end,
                color_fn = missing_color
            },
            {
                header = "St%",
                field = "storage_pct",
                width = 3,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return tostring(math.floor(val))
                end,
                color_fn = missing_color
            },
            {
                header = "In",
                field = "inputs_met",
                width = 2,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return val and "Y" or "N"
                end,
                color_fn = function(val, row)
                    if row.missing then return "dim_grey" end
                    return val and "green" or "red"
                end
            },
            {
                header = "Bt%",
                field = "batch_completion",
                width = 3,
                formatter = function(val, row)
                    if row.missing then return "-" end
                    return tostring(math.floor(val))
                end,
                color_fn = missing_color
            }
        },
        data = factories,
        footer = {
            aggregations = {
                {field = "working_capital", method = "sum"},
                {field = "income", method = "sum"},
                {field = "expenditure", method = "sum"},
                {
                    field = "profit",
                    method = "sum",
                    color_fn = function(val)
                        return val >= 0 and "green" or "red"
                    end
                },
                {
                    field = "income_expense_ratio",
                    method = "avg",
                    color_fn = function(val)
                        if val == 0 then
                            return "dim_grey"
                        elseif val > 1.0 then
                            return "green"
                        elseif val < 1.0 then
                            return "red"
                        else
                            return "yellow"
                        end
                    end
                }
            }
        }
    }

    -- Render table using shared renderer
    f2t_render_table(config)

    -- Additional info (no leading newline since table already ends with one)
    -- Uses active_count calculated at start of function
    cecho(string.format("<cyan>Total: %d factories (%d slots)<reset>\n", active_count, #factories))
    cecho("<dim_grey>St=Status I/E=Inc/Exp Ef=Eff% Wk=Work% St=Store% In=Inputs Bt=Batch%<reset>\n\n")
end

-- Complete factory status collection and display
function f2t_factory_complete()
    f2t_factory.capturing = false

    f2t_debug_log("[factory-status] Collection complete, displaying results")

    f2t_factory_display_table()
    f2t_factory_reset()
end
