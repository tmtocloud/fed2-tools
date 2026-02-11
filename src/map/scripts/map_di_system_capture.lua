-- ================================================================================
-- DI SYSTEM CAPTURE - Capture planet list from "di system" command
-- ================================================================================
-- Used by system exploration in brief mode to determine expected planets.
-- Follows same pattern as cartel capture (start → capture lines → timer → process).
-- ================================================================================

-- ========================================
-- DI System Capture State
-- ========================================

F2T_MAP_DI_SYSTEM_CAPTURE = F2T_MAP_DI_SYSTEM_CAPTURE or {
    active = false,
    system_name = nil,
    planet_names = {},  -- Planet names captured from output
    timer_id = nil
}

-- Planets to exclude from Sol system exploration
-- These are quest planets without exchanges - leave for players to discover
F2T_MAP_SOL_EXCLUDED_PLANETS = {
    ["graveyard"] = true,
    ["hunt"] = true,
    ["magrathea"] = true,
    ["starbase1"] = true,
}

-- ========================================
-- Start DI System Capture
-- ========================================

function f2t_map_di_system_capture_start(system_name, callback)
    -- Start capturing "di system" output to get expected planet list
    -- callback: function(planet_names) called when capture complete

    F2T_MAP_DI_SYSTEM_CAPTURE = {
        active = true,
        system_name = system_name,
        planet_names = {},
        timer_id = nil,
        callback = callback
    }

    f2t_debug_log("[map-di-system] Starting DI system capture for: %s", system_name)

    -- Send DI system command (include system name so it works from other systems)
    send(string.format("di system %s", system_name), false)
end

-- ========================================
-- Reset Capture Timer
-- ========================================

function f2t_map_di_system_reset_timer()
    -- Kill existing timer
    if F2T_MAP_DI_SYSTEM_CAPTURE.timer_id then
        killTimer(F2T_MAP_DI_SYSTEM_CAPTURE.timer_id)
    end

    -- Start timer to process capture after 0.5s of silence
    F2T_MAP_DI_SYSTEM_CAPTURE.timer_id = tempTimer(0.5, function()
        if F2T_MAP_DI_SYSTEM_CAPTURE.active then
            f2t_debug_log("[map-di-system] Timer expired, processing capture")
            f2t_map_di_system_capture_complete()
        end
    end)
end

-- ========================================
-- Process Captured Output
-- ========================================

function f2t_map_di_system_capture_complete()
    local planet_lines = F2T_MAP_DI_SYSTEM_CAPTURE.planet_names
    local system_name = F2T_MAP_DI_SYSTEM_CAPTURE.system_name
    local callback = F2T_MAP_DI_SYSTEM_CAPTURE.callback

    f2t_debug_log("[map-di-system] Processing %d captured lines for %s", #planet_lines, system_name)

    -- Cleanup capture state
    F2T_MAP_DI_SYSTEM_CAPTURE = {active = false}

    -- Parse planet data (name + whether it has an exchange)
    local planets = {}
    local planet_set = {}  -- For deduplication
    local planets_without_exchange = {}  -- Track planets with no exchange

    -- Process lines in pairs (planet line + detail lines)
    local i = 1
    while i <= #planet_lines do
        local planet_line = planet_lines[i]

        -- Check if this is a planet name line (format: "Name, system, cartel")
        -- Detail lines start with spaces, so they won't match this pattern
        local planet_name = planet_line:match("^([^,]+),")
        if planet_name and not planet_line:match("^%s") then
            planet_name = planet_name:match("^%s*(.-)%s*$")  -- Trim whitespace

            -- Filter out space area (ends with " Space")
            if planet_name:match(" Space$") then
                f2t_debug_log("[map-di-system] Skipping space area: %s", planet_name)
                -- Skip this planet name and its detail line
                i = i + 2
            else
                -- Look ahead for economy info in ALL detail lines for this planet
                local has_exchange = true  -- Assume yes unless proven otherwise
                local detail_index = i + 1

                -- Check all detail lines (lines starting with spaces) until next planet
                while detail_index <= #planet_lines do
                    local detail_line = planet_lines[detail_index]

                    -- Stop if we hit the next planet name (doesn't start with space)
                    if not detail_line:match("^%s") then
                        break
                    end

                    -- Check for "Economy: None" (ONLY indicator of no exchange)
                    if detail_line:match("Economy:%s*None") then
                        has_exchange = false
                        f2t_debug_log("[map-di-system] Planet %s has Economy: None (no exchange)", planet_name)
                    end

                    detail_index = detail_index + 1
                end

                -- Deduplicate and add
                if planet_name ~= "" and not planet_set[planet_name] then
                    table.insert(planets, planet_name)
                    planet_set[planet_name] = true

                    if not has_exchange then
                        planets_without_exchange[planet_name] = true
                    end

                    f2t_debug_log("[map-di-system] Parsed planet: %s (exchange: %s)",
                        planet_name, has_exchange and "yes" or "no")
                end

                -- Skip planet name + all its detail lines
                i = detail_index
            end
        else
            -- Not a planet line (orphaned detail line?), skip it
            i = i + 1
        end
    end

    f2t_debug_log("[map-di-system] Parsed %d unique planets (%d without exchange)",
        #planets, f2t_table_count_keys(planets_without_exchange))

    -- Filter out Sol quest planets (no exchanges, meant for manual discovery)
    if system_name:lower() == "sol" then
        local filtered_planets = {}
        local excluded_count = 0

        for _, planet_name in ipairs(planets) do
            if F2T_MAP_SOL_EXCLUDED_PLANETS[planet_name:lower()] then
                f2t_debug_log("[map-di-system] Excluding Sol quest planet: %s", planet_name)
                planets_without_exchange[planet_name] = nil  -- Clean up if present
                excluded_count = excluded_count + 1
            else
                table.insert(filtered_planets, planet_name)
            end
        end

        if excluded_count > 0 then
            f2t_debug_log("[map-di-system] Excluded %d Sol quest planet(s)", excluded_count)
            planets = filtered_planets
        end
    end

    -- Call callback with results (planets array + no-exchange set)
    if callback then
        callback(planets, planets_without_exchange)
    end
end

f2t_debug_log("[map] Loaded map_di_system_capture.lua")
