-- Map Helper Functions
-- General utilities for accessing GMCP data and querying map data
-- Used by map component and other components (e.g., hauling)

-- ========================================
-- GMCP Location Helpers
-- ========================================

--- Get the current system name from GMCP
--- @return string|nil System name or nil if not available
function f2t_get_current_system()
    if not gmcp or not gmcp.room or not gmcp.room.info then
        return nil
    end
    return gmcp.room.info.system
end

--- Get the current planet/area name from GMCP
--- @return string|nil Planet/area name or nil if not available
function f2t_get_current_planet()
    if not gmcp or not gmcp.room or not gmcp.room.info then
        return nil
    end
    return gmcp.room.info.area
end

--- Get the current room number from GMCP
--- @return string|nil Room number or nil if not available
function f2t_get_current_room_num()
    if not gmcp or not gmcp.room or not gmcp.room.info then
        return nil
    end
    return gmcp.room.info.num
end

--- Get the current Fed2 room hash (system.area.num)
--- @return string|nil Room hash or nil if not available
function f2t_get_current_room_hash()
    if not gmcp or not gmcp.room or not gmcp.room.info then
        return nil
    end

    local info = gmcp.room.info
    if not info.system or not info.area or not info.num then
        return nil
    end

    return string.format("%s.%s.%s", info.system, info.area, info.num)
end

--- Get the current cartel name from map metadata or GMCP
--- Falls back to GMCP cartel field if area metadata not available
--- @return string|nil Cartel name or nil if not available
function f2t_map_get_current_cartel()
    -- Try area user data first (most reliable if available)
    if F2T_MAP_CURRENT_ROOM_ID then
        local area_id = getRoomArea(F2T_MAP_CURRENT_ROOM_ID)
        if area_id then
            local cartel = getAreaUserData(area_id, "fed2_cartel")
            if cartel and cartel ~= "" then
                return cartel
            end
        end
    end

    -- Fall back to GMCP cartel (available directly in gmcp.room.info.cartel)
    if gmcp and gmcp.room and gmcp.room.info and gmcp.room.info.cartel then
        f2t_debug_log("[map_helpers] get_current_cartel() falling back to GMCP cartel: %s", gmcp.room.info.cartel)
        return gmcp.room.info.cartel
    end

    return nil
end

--- Check if current room has a specific flag
--- @param flag string Flag to check for (e.g., "shuttlepad", "exchange", "orbit")
--- @return boolean True if flag is present
function f2t_has_room_flag(flag)
    if not gmcp or not gmcp.room or not gmcp.room.info or not gmcp.room.info.flags then
        return false
    end
    return f2t_has_value(gmcp.room.info.flags, flag)
end

--- Check if currently in a specific system
--- @param system_name string System name to check (e.g., "Sol")
--- @return boolean True if in the specified system
function f2t_is_in_system(system_name)
    local current_system = f2t_get_current_system()
    return current_system == system_name
end

--- Check if currently at a specific planet/area
--- @param planet_name string Planet/area name to check
--- @return boolean True if at the specified planet
function f2t_is_at_planet(planet_name)
    local current_planet = f2t_get_current_planet()
    return current_planet == planet_name
end

-- ========================================
-- Map Data Lookup Helpers
-- ========================================

--- Look up a planet in the map database
--- @param planet_name string Planet/area name to look up
--- @return table|nil Returns {name = "Earth", system = "Sol"} or nil if not found
function f2t_map_lookup_planet(planet_name)
    f2t_debug_log("[map_helpers] lookup_planet(%s) called", planet_name)

    local area_id = f2t_map_get_area_id(planet_name)
    if not area_id then
        f2t_debug_log("[map_helpers] lookup_planet(%s) -> not found", planet_name)
        return nil
    end

    -- Get a sample room from this area to extract the system name
    local area_rooms = getAreaRooms(area_id)
    if area_rooms then
        -- Try [0] first (common), then [1], then any key
        local sample_room = area_rooms[0] or area_rooms[1] or area_rooms[next(area_rooms)]
        if sample_room then
            local system = getRoomUserData(sample_room, "fed2_system")
            f2t_debug_log("[map_helpers] lookup_planet(%s) -> found (system: %s)", planet_name, tostring(system))
            return {name = planet_name, system = system}
        end
    end

    -- Found area but no rooms yet (shouldn't happen)
    f2t_debug_log("[map_helpers] lookup_planet(%s) -> found (no system data)", planet_name)
    return {name = planet_name}
end

--- Look up a system in the map database
--- @param system_name string System name to look up
--- @return table|nil Returns {name = "Sol"} or nil if not found
function f2t_map_lookup_system(system_name)
    f2t_debug_log("[map_helpers] lookup_system(%s) called", system_name)

    -- Check if the system's space area exists
    local space_area = f2t_map_get_system_space_area_actual(system_name)
    if space_area then
        f2t_debug_log("[map_helpers] lookup_system(%s) -> found", system_name)
        return {name = system_name}
    end

    f2t_debug_log("[map_helpers] lookup_system(%s) -> not found", system_name)
    return nil
end

f2t_debug_log("[map] Map helper functions initialized")
