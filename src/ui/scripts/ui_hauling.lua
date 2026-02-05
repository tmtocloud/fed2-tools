-- =============================================================================
-- UI Hauling Script - Federation 2 Mudlet Package
-- =============================================================================

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

UI = UI or {}
UI.hauling_jobs = {}
UI.hauling_sort = { column = nil, ascending = true }

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

function rpad(str, len)
    str = tostring(str)
    if #str > len then
        return str:sub(1, len)
    end
    return str .. string.rep(" ", len - #str)
end

function lpad(str, len)
    str = tostring(str)
    if #str > len then
        return str:sub(1, len)
    end
    return string.rep(" ", len - #str) .. str
end

function stripThe(name)
    if not name then return "" end
    local result = string.gsub(name, "^The ", "")
    return result
end

function ui_get_route_distance(planet1, planet2)
    -- Use the map route calculation to get actual distance
    local route_info, err = f2t_map_get_route_info(planet1, planet2)

    if not route_info or not route_info.success then
        return nil
    end

    -- Return space_moves for GTU calculation (spaceship movements only)
    return route_info.space_moves
end
-- =============================================================================
-- SORTING
-- =============================================================================

function ui_sort_jobs()
    if not UI.hauling_sort.column then return end

    local col = UI.hauling_sort.column
    local asc = UI.hauling_sort.ascending

    table.sort(UI.hauling_jobs, function(a, b)
        local valA, valB
        local jobA = tonumber(a.job_number)
        local jobB = tonumber(b.job_number)

        if col == "job" then
            if asc then
                return jobA < jobB
            else
                return jobA > jobB
            end
        elseif col == "origin" then
            valA, valB = a.origin:lower(), b.origin:lower()
        elseif col == "dest" then
            valA, valB = a.dest:lower(), b.dest:lower()
        elseif col == "pay" then
            valA, valB = a.effective_pay, b.effective_pay
        else
            return false
        end

        if valA < valB then
            return asc
        elseif valA > valB then
            return not asc
        else
            return jobA < jobB
        end
    end)
end

function ui_toggle_sort(column)
    if column == "pay" then
        if UI.hauling_sort.column == "pay" then
            return
        end
        UI.hauling_sort.column    = "pay"
        UI.hauling_sort.ascending = false
    elseif UI.hauling_sort.column == column then
        UI.hauling_sort.ascending = not UI.hauling_sort.ascending
    else
        UI.hauling_sort.column    = column
        UI.hauling_sort.ascending = true
    end

    ui_display_hauling_jobs()
end

-- =============================================================================
-- RENDERING
-- =============================================================================

function ui_render_header()
    UI.hauling_window:cecho("<b>Available Work:</b>\n")

    local function header_link(label, column, sortable)
        local isActive = (UI.hauling_sort.column == column)
        local color    = isActive and "<ansiGreen>" or "<white>"
        
        if sortable then
            UI.hauling_window:cechoLink(
                color .. label .. "<reset>",
                function() ui_toggle_sort(column) end,
                "Sort by " .. label,
                true
            )
        else
            UI.hauling_window:cecho(color .. label .. "<reset>")
        end
    end

    header_link("Job", "job", true)
    UI.hauling_window:cecho(" ")
    header_link(rpad("Origin", 9), "origin", true)
    UI.hauling_window:cecho("  ")
    header_link(rpad("Dest", 9), "dest", true)
    header_link(lpad("Moves", 8), "moves", false)
    UI.hauling_window:cecho("    ")
    header_link("Pay", "pay", true)
    UI.hauling_window:cecho("\n")
end

function ui_render_job_line(job)
    -- Job number (right-aligned to 3 chars)
    local job_pad = string.rep(" ", 3 - #job.job_number)

    UI.hauling_window:cecho(job_pad)
    UI.hauling_window:cechoLink(
        "<blue><u>" .. job.job_number .. "</u><reset>",
        function() send("ac " .. job.job_number) end,
        "Accept job " .. job.job_number,
        true
    )
    UI.hauling_window:cecho(" ")

    -- Origin (left-aligned, 9 chars)
    UI.hauling_window:cechoLink(
        "<ansiCyan>" .. rpad(job.origin_display, 9) .. "<reset>",
        function() send("whereis " .. job.origin) end,
        "Find " .. job.origin,
        true
    )

    UI.hauling_window:cecho(" > ")

    -- Dest (left-aligned, 9 chars)
    UI.hauling_window:cechoLink(
        "<ansiCyan>" .. rpad(job.dest_display, 9) .. "<reset>",
        function() send("whereis " .. job.dest) end,
        "Find " .. job.dest,
        true
    )

    -- Moves (right-aligned, total 8 chars including "gtu")
    local dist    = job.distance
    local allowed = job.allowed_moves

    if dist then
        local dist_color

        if dist < allowed then
            dist_color = "<ansiGreen>"
        elseif dist > allowed then
            dist_color = "<ansiRed>"
        else
            dist_color = "<white>"
        end

        local moves     = tostring(allowed) .. "/" .. tostring(dist) .. "gtu"
        local moves_pad = string.rep(" ", 8 - #moves)
        UI.hauling_window:cecho(moves_pad .. "<b>" .. allowed .. "</b>/" .. dist_color .. "<b>" .. dist .. "</b><reset>gtu")
    else
        local moves     = tostring(allowed) .. "gtu"
        local moves_pad = string.rep(" ", 8 - #moves)
        UI.hauling_window:cecho(moves_pad .. "<b>" .. allowed .. "</b>gtu")
    end

    UI.hauling_window:cecho(" ")

    -- Pay (right-aligned to 4 chars)
    local pay_pad = string.rep(" ", 4 - #tostring(job.base_pay))
    UI.hauling_window:cecho(pay_pad .. "<b>" .. job.base_pay .. "</b>ig")

    -- Bonus/Penalty
    if job.pay_type == "bonus" then
        UI.hauling_window:cecho(" (<ansiGreen><b>" .. job.effective_pay .. "</b><reset>ig)")
    elseif job.pay_type == "penalty" then
        UI.hauling_window:cecho(" (<ansiRed><b>" .. job.effective_pay .. "</b><reset>ig)")
    end
    
    UI.hauling_window:cecho("\n")
end

function ui_display_hauling_jobs()
    if not UI.hauling_window then
        cecho("\n<red>Error: UI.hauling_window not found!\n")
        return
    end

    clearWindow("UI.hauling_window")

    if #UI.hauling_jobs == 0 then
        UI.hauling_window:cecho("No hauling jobs available.\n")
        return
    end

    ui_sort_jobs()
    ui_render_header()

    for _, job in ipairs(UI.hauling_jobs) do
        ui_render_job_line(job)
    end
end

-- =============================================================================
-- TRIGGER HANDLERS
-- =============================================================================

function ui_on_hauling_header()
    UI.hauling_jobs = {}
end

function ui_on_hauling_job(job_number, origin, dest, allowed_moves, pay_per_ton)
    local base_pay          = tonumber(pay_per_ton) * 75
    local allowed_moves_num = tonumber(allowed_moves)
    local distance          = ui_get_route_distance(origin, dest)

    local effective_pay, pay_type

    if not distance then
        effective_pay = base_pay
        pay_type      = "unknown"
    elseif distance < allowed_moves_num then
        effective_pay = math.floor(base_pay * 1.20)
        pay_type      = "bonus"
    elseif distance > allowed_moves_num then
        effective_pay = math.floor(base_pay * 0.50)
        pay_type      = "penalty"
    else
        effective_pay = base_pay
        pay_type      = "normal"
    end

    table.insert(UI.hauling_jobs, {
        job_number     = job_number,
        origin         = origin,
        dest           = dest,
        origin_display = stripThe(origin),
        dest_display   = stripThe(dest),
        allowed_moves  = allowed_moves_num,
        base_pay       = base_pay,
        distance       = distance,
        effective_pay  = effective_pay,
        pay_type       = pay_type
    })

    ui_display_hauling_jobs()
end

-- =============================================================================
-- UI BUTTONS
-- =============================================================================

function ui_hauling()
    UI.button_work = Geyser.Label:new(
        {
            name    = "UI.button_work",
            message = "<center>Work</center>"
        },
        UI.hauling_button_bar
    )
    UI.button_work:setStyleSheet(UI.style.button_css)
    UI.button_work:setClickCallback("ui_work")

    UI.button_collect = Geyser.Label:new(
        {
            name    = "UI.button_collect",
            message = "<center>Collect</center>"
        },
        UI.hauling_button_bar
    )
    UI.button_collect:setStyleSheet(UI.style.button_css)
    UI.button_collect:setClickCallback("ui_collect")

    UI.button_deliver = Geyser.Label:new(
        {
            name    = "UI.button_deliver",
            message = "<center>Deliver</center>"
        },
        UI.hauling_button_bar
    )
    UI.button_deliver:setStyleSheet(UI.style.button_css)
    UI.button_deliver:setClickCallback("ui_deliver")
end

function ui_work()
    send("work", false)
end

function ui_collect()
    send("collect", false)
end

function ui_deliver()
    send("deliver", false)
end