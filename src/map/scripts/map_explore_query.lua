-- Map exploration query functions
-- Check if systems/planets are fully mapped

-- ========================================
-- Check if Area Has Unlocked Stub Exits
-- ========================================

function f2t_map_explore_has_unlocked_stubs(area_id)
    -- Returns true if area has any unlocked stub exits (incomplete exploration)
    -- Returns false if all stubs are locked or no stubs exist (complete)

    local rooms_in_area = getAreaRooms(area_id)
    if not rooms_in_area then
        return false
    end

    for _, room_id in pairs(rooms_in_area) do
        local stubs = getExitStubs(room_id)

        if stubs then
            -- Check each stub - if any are unlocked, area is incomplete
            for _, stub_dir_num in pairs(stubs) do
                local direction = f2t_map_explore_direction_number_to_name(stub_dir_num)

                if direction and not hasExitLock(room_id, direction) then
                    -- Found unlocked stub
                    f2t_debug_log("[map-explore-query] Area %d has unlocked stub: room %d, direction %s",
                        area_id, room_id, direction)
                    return true
                end
            end
        end
    end

    -- No unlocked stubs found
    return false
end

-- ========================================
-- Check if Planet Has Required Flags
-- ========================================

function f2t_map_explore_planet_has_flags(area_id, required_flags)
    -- Returns true if planet area has all required flags in at least one room
    -- required_flags is array like {"shuttlepad", "exchange"}

    local rooms_in_area = getAreaRooms(area_id)
    if not rooms_in_area then
        return false
    end

    local found_flags = {}

    -- Check all rooms for flags
    for _, room_id in pairs(rooms_in_area) do
        for _, flag in ipairs(required_flags) do
            if not found_flags[flag] then
                local flag_key = string.format("fed2_flag_%s", flag)
                local has_flag = getRoomUserData(room_id, flag_key)

                if has_flag == "true" then
                    found_flags[flag] = true
                    f2t_debug_log("[map-explore-query] Area %d has flag '%s' at room %d",
                        area_id, flag, room_id)
                end
            end
        end
    end

    -- Check if all required flags found
    for _, flag in ipairs(required_flags) do
        if not found_flags[flag] then
            f2t_debug_log("[map-explore-query] Area %d missing flag: %s", area_id, flag)
            return false
        end
    end

    return true
end

-- ========================================
-- Check if System is Fully Mapped
-- ========================================

function f2t_map_explore_is_system_fully_mapped(system_name)
    -- Check if system is fully mapped for brief mode exploration
    -- Requirements:
    --   - Space area fully mapped (no unlocked stubs)
    --   - All planets have required flags (shuttlepad + brief_additional_flags)
    --
    -- NOTE: System and cartel modes ONLY do brief discovery (flag finding)
    -- There is no "full" mode for system/cartel exploration

    f2t_debug_log("[map-explore-query] Checking if system '%s' is fully mapped", system_name)

    -- Check if space area exists
    local space_area_name = f2t_map_get_system_space_area_actual(system_name)
    if not space_area_name then
        f2t_debug_log("[map-explore-query] System '%s' space area not found", system_name)
        return false
    end

    local space_area_id = f2t_map_get_area_id(space_area_name)
    if not space_area_id then
        f2t_debug_log("[map-explore-query] Could not get area ID for '%s'", space_area_name)
        return false
    end

    -- Check if space area is fully mapped (no unlocked stubs)
    if f2t_map_explore_has_unlocked_stubs(space_area_id) then
        f2t_debug_log("[map-explore-query] System '%s' space has unlocked stubs", system_name)
        return false
    end

    -- Get all orbit rooms (planets) in system
    local orbit_rooms = {}
    local rooms_in_area = getAreaRooms(space_area_id)

    for _, room_id in pairs(rooms_in_area) do
        local planet = getRoomUserData(room_id, "fed2_planet")
        if planet then
            -- Found orbit room
            local planet_area_name = planet  -- Planet name is area name
            local planet_area_id = f2t_map_get_area_id(planet_area_name)

            if planet_area_id then
                table.insert(orbit_rooms, {
                    name = planet,
                    area_id = planet_area_id
                })
                f2t_debug_log("[map-explore-query] Found planet in system: %s (area %d)",
                    planet, planet_area_id)
            end
        end
    end

    if #orbit_rooms == 0 then
        f2t_debug_log("[map-explore-query] System '%s' has no planets", system_name)
        return false
    end

    -- Get required flags for brief mode
    local required_flags = {"shuttlepad"}  -- Always require shuttlepad

    -- Add additional flags from settings
    local additional_flags_str = f2t_settings_get("map", "brief_additional_flags") or "exchange"
    for flag in string.gmatch(additional_flags_str, "[^,]+") do
        local trimmed = flag:match("^%s*(.-)%s*$")
        if trimmed ~= "" and trimmed ~= "shuttlepad" then
            table.insert(required_flags, trimmed)
        end
    end

    f2t_debug_log("[map-explore-query] Required flags: %s", table.concat(required_flags, ", "))

    -- Check each planet has required flags
    for _, planet in ipairs(orbit_rooms) do
        if not f2t_map_explore_planet_has_flags(planet.area_id, required_flags) then
            f2t_debug_log("[map-explore-query] Planet '%s' missing required flags", planet.name)
            return false
        end
    end

    f2t_debug_log("[map-explore-query] System '%s' is fully mapped", system_name)
    return true
end

f2t_debug_log("[map] Loaded map_explore_query.lua")
