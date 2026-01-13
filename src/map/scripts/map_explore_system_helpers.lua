-- ================================================================================
-- SYSTEM EXPLORATION HELPERS
-- ================================================================================
-- Helper functions for Layer 2 (system) exploration mode.
-- ================================================================================

-- ========================================
-- Check Room for Planets (Brief Mode Early Exit)
-- ========================================

function f2t_map_explore_system_check_room_for_planets(room_id)
    -- Called after discovering/entering a room during Phase 1 space exploration
    -- In brief mode: checks if room is an orbit room for an expected planet
    -- Stops Phase 1 exploration if all expected planets found
    --
    -- This is the system-level equivalent of brief mode's flag checking

    -- Only check if system exploration is active with brief mode
    if not F2T_MAP_EXPLORE_STATE.active then
        return
    end

    if not F2T_MAP_EXPLORE_STATE.system_mode or F2T_MAP_EXPLORE_STATE.system_mode ~= "brief" then
        return
    end

    -- Only check during Phase 1 (exploring space)
    if F2T_MAP_EXPLORE_STATE.system_phase ~= "exploring_space" then
        return
    end

    -- Only check if we have expected planets
    if not F2T_MAP_EXPLORE_STATE.expected_planets or not F2T_MAP_EXPLORE_STATE.expected_planets_remaining then
        return
    end

    -- Check if this room has a planet (orbit room check)
    local planet_name = getRoomUserData(room_id, "fed2_planet")

    if not planet_name or planet_name == "" then
        -- Not an orbit room
        return
    end

    f2t_debug_log("[map-explore-system] Room %d is orbit for planet: %s", room_id, planet_name)

    -- Check if this is one of our expected planets
    if F2T_MAP_EXPLORE_STATE.expected_planets[planet_name] then
        -- Check if we've already found it
        if not F2T_MAP_EXPLORE_STATE.expected_planets_found[planet_name] then
            -- New expected planet found!
            F2T_MAP_EXPLORE_STATE.expected_planets_found[planet_name] = true
            F2T_MAP_EXPLORE_STATE.expected_planets_remaining = F2T_MAP_EXPLORE_STATE.expected_planets_remaining - 1

            cecho(string.format("  <green>✓<reset> Found orbit for expected planet: <yellow>%s<reset>\n", planet_name))

            -- Debug: Log tracking status (what we expect, what we know, what we're still searching for)
            local expected_list = f2t_table_get_sorted_keys(F2T_MAP_EXPLORE_STATE.expected_planets)
            local found_list = {}
            local searching_list = {}
            for planet, _ in pairs(F2T_MAP_EXPLORE_STATE.expected_planets) do
                if F2T_MAP_EXPLORE_STATE.expected_planets_found[planet] then
                    table.insert(found_list, planet)
                else
                    table.insert(searching_list, planet)
                end
            end
            table.sort(found_list)
            table.sort(searching_list)

            f2t_debug_log("[map-explore-system] Brief mode Phase 1 - planet tracking update:")
            f2t_debug_log("[map-explore-system]   Expected planets: %s", table.concat(expected_list, ", "))
            f2t_debug_log("[map-explore-system]   Known planets: %s (%d)",
                #found_list > 0 and table.concat(found_list, ", ") or "none", #found_list)
            f2t_debug_log("[map-explore-system]   Still searching for: %s (%d)",
                #searching_list > 0 and table.concat(searching_list, ", ") or "none", #searching_list)

            -- Check if all expected planets found
            if F2T_MAP_EXPLORE_STATE.expected_planets_remaining == 0 then
                f2t_debug_log("[map-explore-system] All expected planets found! Triggering immediate Phase 1 completion")
                cecho("\n<green>[map-explore]<reset> All expected planets found! Space exploration complete.\n\n")

                -- Immediately complete Phase 1 - don't wait for timer
                -- Clear the frontier to stop further exploration
                F2T_MAP_EXPLORE_STATE.frontier_stack = {}

                -- Call completion directly (no timer delay)
                f2t_debug_log("[map-explore-system] Calling space complete callback (early exit)")
                f2t_map_explore_system_space_complete()
                return
            end
        else
            f2t_debug_log("[map-explore-system] Planet %s already found (duplicate orbit room)", planet_name)
        end
    else
        f2t_debug_log("[map-explore-system] Planet %s not in expected list (extra planet)", planet_name)
    end
end

f2t_debug_log("[map] Loaded map_explore_system_helpers.lua")
