-- Room search functionality for Federation 2 mapper
-- Allows searching for rooms by name/text across different scopes
-- Uses Mudlet's native searchRoom() function with area filtering

-- ========================================
-- Search Functions
-- ========================================

-- Search for rooms by name in a specific area
-- Returns: array of {room_id, name, hash, system, area}
-- Note: More performant than using searchRoom() + filtering because it only searches the target area
function f2t_map_search_area(area_id, search_text)
    if not area_id then
        f2t_debug_log("[map] ERROR: f2t_map_search_area called with nil area_id")
        return {}
    end

    if not search_text or search_text == "" then
        f2t_debug_log("[map] ERROR: f2t_map_search_area called with empty search_text")
        return {}
    end

    local results = {}
    local room_ids = getAreaRooms(area_id)

    if not room_ids then
        return results
    end

    local search_lower = string.lower(search_text)

    -- Check [0] entry first (Mudlet can use 0-indexed tables)
    if room_ids[0] then
        local room_name = getRoomName(room_ids[0])
        if room_name and string.find(string.lower(room_name), search_lower, 1, true) then
            local hash = f2t_map_generate_hash_from_room(room_ids[0])
            local system = getRoomUserData(room_ids[0], "fed2_system")
            local area = getRoomUserData(room_ids[0], "fed2_area")

            table.insert(results, {
                room_id = room_ids[0],
                name = room_name,
                hash = hash,
                system = system,
                area = area
            })
        end
    end

    -- Check remaining entries
    for _, room_id in ipairs(room_ids) do
        local room_name = getRoomName(room_id)
        if room_name and string.find(string.lower(room_name), search_lower, 1, true) then
            local hash = f2t_map_generate_hash_from_room(room_id)
            local system = getRoomUserData(room_id, "fed2_system")
            local area = getRoomUserData(room_id, "fed2_area")

            table.insert(results, {
                room_id = room_id,
                name = room_name,
                hash = hash,
                system = system,
                area = area
            })
        end
    end

    f2t_debug_log("[map] Found %d room(s) matching '%s' in area %d", #results, search_text, area_id)
    return results
end

-- Search for rooms by name across all areas
-- Returns: array of {room_id, name, hash, system, area}
-- Note: Uses Mudlet's native searchRoom() which is likely optimized in C++ for full-map searches
function f2t_map_search_all(search_text)
    if not search_text or search_text == "" then
        f2t_debug_log("[map] ERROR: f2t_map_search_all called with empty search_text")
        return {}
    end

    local results = {}

    -- Use Mudlet's native searchRoom function (case-insensitive, substring match)
    -- More efficient than Lua iteration when searching entire map
    local matching_rooms = searchRoom(search_text, false, false)

    if not matching_rooms then
        return results
    end

    -- Convert to our result format with metadata
    for room_id, room_name in pairs(matching_rooms) do
        local hash = f2t_map_generate_hash_from_room(room_id)
        local system = getRoomUserData(room_id, "fed2_system")
        local area = getRoomUserData(room_id, "fed2_area")

        table.insert(results, {
            room_id = room_id,
            name = room_name,
            hash = hash,
            system = system,
            area = area
        })
    end

    f2t_debug_log("[map] Found %d room(s) matching '%s' across all areas", #results, search_text)
    return results
end

-- Search for rooms in current area
-- Returns: array of {room_id, name, hash, system, area} or nil if current location unknown
function f2t_map_search_current_area(search_text)
    if not search_text or search_text == "" then
        f2t_debug_log("[map] ERROR: f2t_map_search_current_area called with empty search_text")
        return {}
    end

    -- Get current area
    if not F2T_MAP_CURRENT_ROOM_ID or not roomExists(F2T_MAP_CURRENT_ROOM_ID) then
        f2t_debug_log("[map] ERROR: Current room unknown")
        return nil
    end

    local current_area_id = getRoomArea(F2T_MAP_CURRENT_ROOM_ID)
    if not current_area_id then
        f2t_debug_log("[map] ERROR: Cannot determine current area")
        return nil
    end

    return f2t_map_search_area(current_area_id, search_text)
end

-- Search for rooms in a specific planet or system
-- Returns: array of {room_id, name, hash, system, area} or nil if area not found
function f2t_map_search_planet_or_system(location, search_text)
    if not location or location == "" then
        f2t_debug_log("[map] ERROR: f2t_map_search_planet_or_system called with empty location")
        return nil
    end

    if not search_text or search_text == "" then
        f2t_debug_log("[map] ERROR: f2t_map_search_planet_or_system called with empty search_text")
        return {}
    end

    local results = {}

    -- Try as planet first (search only that planet's area)
    local planet_data = f2t_map_lookup_planet(location)
    if planet_data then
        local planet_area_id = f2t_map_get_area_id(location)
        if planet_area_id then
            f2t_debug_log("[map] Searching planet '%s'", location)
            return f2t_map_search_area(planet_area_id, search_text)
        end
    end

    -- Try as system (search system space AND all planets in that system)
    local system_data = f2t_map_lookup_system(location)
    if system_data then
        local search_lower = string.lower(location)
        f2t_debug_log("[map] Searching system '%s'", location)

        -- Search system space
        local space_area = f2t_map_get_system_space_area_actual(location)
        if space_area then
            local space_area_id = f2t_map_get_area_id(space_area)
            if space_area_id then
                local space_results = f2t_map_search_area(space_area_id, search_text)
                for _, result in ipairs(space_results) do
                    table.insert(results, result)
                end
            end
        end

        -- Search all areas that belong to this system
        -- We do this by checking fed2_system metadata on sample rooms from each area
        local all_areas = getAreaTable()
        for area_name, area_id in pairs(all_areas) do
            -- Skip the space area (already searched)
            if area_name ~= space_area then
                -- Get a sample room to check system
                local area_rooms = getAreaRooms(area_id)
                if area_rooms and next(area_rooms) then
                    local sample_room = area_rooms[0] or area_rooms[1] or area_rooms[next(area_rooms)]
                    local room_system = getRoomUserData(sample_room, "fed2_system")

                    -- If this area belongs to the target system, search it
                    if room_system and string.lower(room_system) == search_lower then
                        local planet_results = f2t_map_search_area(area_id, search_text)
                        for _, result in ipairs(planet_results) do
                            table.insert(results, result)
                        end
                    end
                end
            end
        end

        return results
    end

    -- Not found as planet or system
    f2t_debug_log("[map] Location '%s' not found in map", location)
    return nil
end

-- ========================================
-- Display Functions
-- ========================================

-- Display search results
function f2t_map_search_display(results, search_text, scope)
    if not results then
        cecho("\n<red>[map]<reset> Search location not found or not yet mapped\n")
        cecho("\n<dim_grey>Visit the location first to add it to the map<reset>\n")
        return
    end

    if #results == 0 then
        cecho(string.format("\n<yellow>[map]<reset> No rooms found matching '%s' in %s\n", search_text, scope))
        return
    end

    -- Sort results by system, then area, then name
    table.sort(results, function(a, b)
        if a.system ~= b.system then
            return (a.system or "") < (b.system or "")
        end
        if a.area ~= b.area then
            return (a.area or "") < (b.area or "")
        end
        return (a.name or "") < (b.name or "")
    end)

    cecho(string.format("\n<green>[map]<reset> Found <yellow>%d<reset> room(s) matching '<white>%s<reset>' in %s:\n",
        #results, search_text, scope))

    -- Use table renderer for clean display
    f2t_render_table({
        columns = {
            {header = "ID", field = "room_id", align = "right", width = 6},
            {header = "System", field = "system", width = 15},
            {header = "Area", field = "area", width = 20},
            {header = "Name", field = "name", max_width = 40},
            {header = "Hash", field = "hash", color = "dim_grey", max_width = 30}
        },
        data = results
    })
end

f2t_debug_log("[map] Room search functions loaded")
