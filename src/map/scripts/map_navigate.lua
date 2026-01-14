-- Navigation function
-- Central navigation logic that can be called from aliases or other scripts

-- Navigate to a destination (room ID, hash, planet, system, or flag)
-- Returns: true if navigation started, false if failed
function f2t_map_navigate(destination)
    if not destination or destination == "" then
        cecho("\n<red>[map]<reset> No destination specified\n")
        return false
    end

    -- Store original destination for case-sensitive operations (e.g., hashes)
    local original_arg = destination

    -- Normalize input (case-insensitive) for most operations
    local arg = string.lower(destination)
    local target_id = nil

    -- Known flags (for disambiguating "area flag" vs multi-word destinations)
    local KNOWN_FLAGS = {
        shuttlepad = true,
        exchange = true,
        link = true,
        orbit = true
    }

    -- Flag shortcuts
    local FLAG_SHORTCUTS = {
        ex = "exchange",
        sp = "shuttlepad"
    }

    -- Try resolving as saved destination first (before any other resolution)
    local dest_hash = f2t_map_destination_get(arg)
    if dest_hash then
        -- Destination found, try to get room by hash
        target_id = f2t_map_get_room_by_hash(dest_hash)

        if target_id then
            f2t_debug_log("[map] Nav format: destination '%s' -> hash %s -> room %d",
                arg, dest_hash, target_id)
        else
            cecho(string.format("\n<red>[map]<reset> Destination '%s' points to unmapped room (%s)\n",
                arg, dest_hash))
            cecho("\n<dim_grey>Visit the location first to add it to the map<reset>\n")
            return false
        end
    end

    -- Try parsing as Mudlet room ID (pure number) only if not a bookmark
    local room_num = nil
    if not target_id then
        room_num = tonumber(arg)
    end
    if room_num then
        -- Format 1: Direct Mudlet room ID navigation
        if not roomExists(room_num) then
            cecho(string.format("\n<red>[map]<reset> Room %d does not exist in the map\n", room_num))
            return false
        end
        target_id = room_num
        f2t_debug_log("[map] Nav format: room ID %d", room_num)

    -- Try parsing as Fed2 hash (system.area.num)
    elseif string.match(arg, "^[^%.]+%.[^%.]+%.%d+$") then
        -- Format 2: Fed2 hash lookup (use original case-sensitive input)
        local hash = original_arg
        target_id = f2t_map_get_room_by_hash(hash)

        if not target_id then
            cecho(string.format("\n<red>[map]<reset> Room with hash '%s' not found\n", hash))
            return false
        end

        f2t_debug_log("[map] Nav format: Fed2 hash %s -> room %d", hash, target_id)

    -- Try parsing as "area flag" (multiple words where last word is a known flag)
    -- Extract potential flag (last word) and check if it's a known flag
    elseif string.match(arg, "%s") then
        local words = {}
        for word in string.gmatch(arg, "%S+") do
            table.insert(words, word)
        end

        local last_word = words[#words]
        local is_area_flag_format = false

        -- Check if last word is a known flag (including shortcuts)
        if KNOWN_FLAGS[last_word] or FLAG_SHORTCUTS[last_word] then
            is_area_flag_format = true
        end

        if is_area_flag_format and #words >= 2 then
            -- Format 4: Area + flag lookup
            -- Everything except last word is the area name
            local flag = last_word

            -- Apply flag shortcut if applicable
            if FLAG_SHORTCUTS[flag] then
                flag = FLAG_SHORTCUTS[flag]
            end

            table.remove(words, #words)  -- Remove flag from words
            local area_name = table.concat(words, " ")

            f2t_debug_log("[map] Nav format: area flag (%s + %s)", area_name, flag)

            -- Special handling for "orbit" flag
            -- Orbit rooms are in system space, not on the planet
            local search_area_name = area_name
            if flag == "orbit" then
                -- Check if area_name is a planet
                local planet_data = f2t_map_lookup_planet(area_name)
                if planet_data and planet_data.system then
                    search_area_name = f2t_map_get_system_space_area_actual(planet_data.system)
                    if not search_area_name then
                        cecho(string.format("\n<red>[map]<reset> System space for planet '%s' not found\n", area_name))
                        return false
                    end
                    f2t_debug_log("[map] Resolved orbit: planet '%s' -> system space '%s'", area_name, search_area_name)
                end
            end

            -- Look up area ID (case-insensitive)
            local area_id = f2t_map_get_area_id(search_area_name)
        if not area_id then
            cecho(string.format("\n<red>[map]<reset> Area '%s' not found\n", search_area_name))
            return false
        end

        -- Get all rooms in the area
        local area_rooms = getAreaRooms(area_id)
        if not area_rooms then
            cecho(string.format("\n<red>[map]<reset> No rooms found in area '%s'\n", search_area_name))
            return false
        end

        -- Filter by flag or planet name (for orbit rooms)
        local flag_key = string.format("fed2_flag_%s", flag)
        local matching_rooms = {}

        if flag == "orbit" then
            -- For orbit, match by fed2_planet instead of flag
            -- Check [0] entry first
            if area_rooms[0] then
                local room_planet = getRoomUserData(area_rooms[0], "fed2_planet")
                if room_planet and string.lower(room_planet) == string.lower(area_name) then
                    table.insert(matching_rooms, area_rooms[0])
                end
            end

            -- Check remaining entries
            for _, room_id in ipairs(area_rooms) do
                local room_planet = getRoomUserData(room_id, "fed2_planet")
                if room_planet and string.lower(room_planet) == string.lower(area_name) then
                    table.insert(matching_rooms, room_id)
                end
            end
        else
            -- Regular flag matching
            -- Check [0] entry first
            if area_rooms[0] then
                local has_flag = getRoomUserData(area_rooms[0], flag_key)
                if has_flag == "true" then
                    table.insert(matching_rooms, area_rooms[0])
                end
            end

            -- Check remaining entries
            for _, room_id in ipairs(area_rooms) do
                local has_flag = getRoomUserData(room_id, flag_key)
                if has_flag == "true" then
                    table.insert(matching_rooms, room_id)
                end
            end
        end

        if #matching_rooms == 0 then
            local search_desc = flag == "orbit" and string.format("orbit for planet '%s'", area_name) or string.format("flag '%s'", flag)
            cecho(string.format("\n<red>[map]<reset> No rooms with %s found in area '%s'\n",
                search_desc, search_area_name))
            return false
        end

        if #matching_rooms > 1 then
            cecho(string.format("\n<yellow>[map]<reset> Found %d rooms with flag '%s' in '%s', using first match\n",
                #matching_rooms, flag, search_area_name))
        end

            target_id = matching_rooms[1]
            f2t_debug_log("[map] Nav format: area flag (%s %s) -> room %d", area_name, flag, target_id)
        else
            -- Multiple words but last word is NOT a known flag
            -- Fall through to try as planet/system (single destination logic)
            -- Don't return here, let it fall through to the single-arg logic below
        end
    end

    -- If we haven't found a target yet, try as single destination (planet/system/flag)
    if not target_id then
        -- Format 3/5/6: Could be planet, system, or flag (single or multi-word)
        local single_arg = arg

        -- Apply flag shortcuts first
        if FLAG_SHORTCUTS[single_arg] then
            single_arg = FLAG_SHORTCUTS[single_arg]
            f2t_debug_log("[map] Applied flag shortcut: %s -> %s", arg, single_arg)
        end

        -- Try as planet first (use configured default destination)
        f2t_debug_log("[map] Trying single_arg '%s' as planet", single_arg)
        local planet_data = f2t_map_lookup_planet(single_arg)
        if planet_data then
            f2t_debug_log("[map] Found planet area for '%s'", single_arg)

            local system_name = planet_data.system
            local area_id = f2t_map_get_area_id(single_arg)

            -- Format 3: nav <planet> - Navigate to planet's default destination (shuttlepad or orbit)
            local planet_dest = F2T_MAP_PLANET_NAV_DEFAULT or "shuttlepad"
            f2t_debug_log("[map] Planet nav default: %s", planet_dest)

            if planet_dest == "orbit" then
                -- Navigate to orbit in system space
                if not system_name then
                    cecho(string.format("\n<red>[map]<reset> Cannot determine system for planet '%s'\n", single_arg))
                    return false
                end

                local space_area_name = f2t_map_get_system_space_area_actual(system_name)
                if not space_area_name then
                    cecho(string.format("\n<red>[map]<reset> System space for planet '%s' not found\n", single_arg))
                    return false
                end

                local space_area_id = f2t_map_get_area_id(space_area_name)
                if not space_area_id then
                    cecho(string.format("\n<red>[map]<reset> System space area '%s' not found\n", space_area_name))
                    return false
                end

                -- Find orbit room with matching planet
                local area_rooms = getAreaRooms(space_area_id)
                if area_rooms then
                    -- Check [0] first
                    local sample_room = area_rooms[0]
                    if sample_room then
                        local room_planet = getRoomUserData(sample_room, "fed2_planet")
                        if room_planet and string.lower(room_planet) == string.lower(single_arg) then
                            target_id = sample_room
                        end
                    end

                    -- Check remaining rooms
                    if not target_id then
                        for _, room_id in ipairs(area_rooms) do
                            local room_planet = getRoomUserData(room_id, "fed2_planet")
                            if room_planet and string.lower(room_planet) == string.lower(single_arg) then
                                target_id = room_id
                                break
                            end
                        end
                    end
                end

                if target_id then
                    f2t_debug_log("[map] Nav format: planet (%s) -> orbit room %d", single_arg, target_id)
                else
                    cecho(string.format("\n<red>[map]<reset> No orbit found for planet '%s'\n", single_arg))
                    return false
                end
            else
                -- Navigate to shuttlepad on planet surface (default behavior)
                local planet_area_id = f2t_map_get_area_id(single_arg)
                f2t_debug_log("[map] Planet area ID: %s", tostring(planet_area_id))

                if planet_area_id then
                    target_id = f2t_map_find_room_with_flag(planet_area_id, "shuttlepad")

                    if target_id then
                        f2t_debug_log("[map] Nav format: planet (%s) -> shuttlepad room %d", single_arg, target_id)
                    else
                        cecho(string.format("\n<red>[map]<reset> No shuttlepad found on planet '%s'\n", single_arg))
                        return false
                    end
                else
                    cecho(string.format("\n<red>[map]<reset> Planet '%s' not yet mapped\n", single_arg))
                    cecho("\n<dim_grey>Visit the planet first to add it to the map<reset>\n")
                    return false
                end
            end
        else
            -- Try as system (look for link in "{System} Space")
            local space_area = f2t_map_get_system_space_area_actual(single_arg)
            if space_area then
                -- Format 6: nav <system> - Navigate to system's link
                -- Get the actual space area name (case-insensitive)

                if space_area then
                    local space_area_id = f2t_map_get_area_id(space_area)
                    target_id = f2t_map_find_room_with_flag(space_area_id, "link")

                    if target_id then
                        f2t_debug_log("[map] Nav format: system (%s) -> link room %d", single_arg, target_id)
                    else
                        cecho(string.format("\n<red>[map]<reset> No link found in '%s'\n", space_area))
                        return false
                    end
                else
                    cecho(string.format("\n<red>[map]<reset> System '%s' not yet mapped\n", single_arg))
                    cecho("\n<dim_grey>Visit the system first to add it to the map<reset>\n")
                    return false
                end
            else
                -- Format 5: Flag in current area with special "link" resolution
                local flag = single_arg

                -- Get current area
                if not f2t_map_ensure_current_location(f2t_map_navigate, {destination}) then
                    return false
                end

                local current_area_id = getRoomArea(F2T_MAP_CURRENT_ROOM_ID)
                if not current_area_id then
                    cecho("\n<red>[map]<reset> Cannot determine current area\n")
                    return false
                end

                local area_name = f2t_map_get_area_name(current_area_id)
                local search_area_id = current_area_id
                local search_area_name = area_name

                -- Special "link" resolution: if on planet surface, resolve to system space
                if flag == "link" then
                    -- Get current location from GMCP (authoritative source)
                    local current_system = gmcp.room and gmcp.room.info and gmcp.room.info.system
                    local current_area_name = gmcp.room and gmcp.room.info and gmcp.room.info.area

                    -- Check if current area is a planet (not "{System} Space")
                    if current_system and current_area_name and not string.match(current_area_name, "Space$") then
                        -- We're on a planet surface, navigate to system space link
                        -- Use case-insensitive lookup to get actual area name
                        local space_area = f2t_map_get_system_space_area_actual(current_system)

                        if space_area then
                            local space_area_id = f2t_map_get_area_id(space_area)
                            if space_area_id then
                                search_area_id = space_area_id
                                search_area_name = space_area
                                f2t_debug_log("[map] Resolved 'link' from planet %s to %s", current_area_name, space_area)
                            end
                        end
                    end
                end

                -- Get all rooms in search area
                local area_rooms = getAreaRooms(search_area_id)
                if not area_rooms then
                    cecho(string.format("\n<red>[map]<reset> No rooms found in area '%s'\n", search_area_name or "unknown"))
                    return false
                end

                -- Filter by flag
                local flag_key = string.format("fed2_flag_%s", flag)
                local matching_rooms = {}

                -- Check [0] entry first
                if area_rooms[0] then
                    local has_flag = getRoomUserData(area_rooms[0], flag_key)
                    if has_flag == "true" then
                        table.insert(matching_rooms, area_rooms[0])
                    end
                end

                -- Check remaining entries
                for _, room_id in ipairs(area_rooms) do
                    local has_flag = getRoomUserData(room_id, flag_key)
                    if has_flag == "true" then
                        table.insert(matching_rooms, room_id)
                    end
                end

                if #matching_rooms == 0 then
                    cecho(string.format("\n<red>[map]<reset> No rooms with flag '%s' found in area '%s'\n",
                        flag, search_area_name or "unknown"))
                    cecho("\n<dim_grey>Try: nav <area> <flag> to search a specific area<reset>\n")
                    return false
                end

                if #matching_rooms > 1 then
                    cecho(string.format("\n<yellow>[map]<reset> Found %d rooms with flag '%s', using first match\n",
                        #matching_rooms, flag))
                end

                target_id = matching_rooms[1]
                f2t_debug_log("[map] Nav format: flag in area (%s in %s) -> room %d", flag, search_area_name, target_id)
            end
        end
    end

    -- Check if we found a valid target
    if not target_id then
        cecho(string.format("\n<red>[map]<reset> Could not find destination: %s\n", destination))
        return false
    end

    -- Verify current location is known before pathfinding
    if not f2t_map_ensure_current_location(f2t_map_navigate, {destination}) then
        return false  -- Retry scheduled after 'look'
    end

    -- Current location is now guaranteed to be known
    local current_room_id = F2T_MAP_CURRENT_ROOM_ID

    -- Check if already at destination
    if current_room_id == target_id then
        cecho("\n<green>[map]<reset> You are already at the destination\n")
        f2t_debug_log("[map] Already at destination (room %d)", target_id)
        return true
    end

    -- Calculate path using Mudlet's pathfinding
    -- getPath() returns: success (boolean), cost (number)
    -- getPath() sets globals: speedWalkDir, speedWalkPath, speedWalkWeight
    f2t_debug_log("[map] Calling getPath(%d, %d)", current_room_id, target_id)
    local success, cost = getPath(current_room_id, target_id)
    f2t_debug_log("[map] getPath returned: success=%s, cost=%s", tostring(success), tostring(cost))

    if not success then
        -- Provide more helpful error messages
        local current_area = getRoomArea(current_room_id)
        local target_area = getRoomArea(target_id)
        local current_area_name = current_area and getRoomAreaName(current_area) or "unknown"
        local target_area_name = target_area and getRoomAreaName(target_area) or "unknown"

        cecho("\n<red>[map]<reset> No path found to destination\n")
        cecho(string.format("\n<dim_grey>Current: Room %d (%s)<reset>\n", current_room_id, current_area_name))
        cecho(string.format("<dim_grey>Target: Room %d (%s)<reset>\n", target_id, target_area_name))

        if current_area ~= target_area then
            cecho("\n<yellow>[map]<reset> Rooms are in different areas - make sure areas are connected\n")
        end

        f2t_debug_log("[map] No path: current=%d (%s), target=%d (%s)",
            current_room_id, current_area_name, target_id, target_area_name)
        return false
    end

    -- Check if path is empty (shouldn't happen since we checked equality above, but be defensive)
    if #speedWalkDir == 0 then
        cecho("\n<green>[map]<reset> Already at destination\n")
        f2t_debug_log("[map] Empty path - already at destination")
        return true
    end

    -- Start speedwalk (processes speedWalkDir global set by getPath)
    doSpeedWalk()
    return true
end
