-- Room query functions for finding rooms by various criteria

-- Find a room with a specific flag in a specific area
-- Returns: room_id or nil
function f2t_map_find_room_with_flag(area_id, flag)
    if not area_id then
        return nil
    end

    local area_rooms = getAreaRooms(area_id)
    if not area_rooms then
        return nil
    end

    local flag_key = string.format("fed2_flag_%s", flag)

    -- Check [0] entry first (Mudlet can use 0-indexed tables)
    if area_rooms[0] then
        local has_flag = getRoomUserData(area_rooms[0], flag_key)
        if has_flag == "true" then
            return area_rooms[0]
        end
    end

    -- Check remaining entries
    for _, room_id in ipairs(area_rooms) do
        local has_flag = getRoomUserData(room_id, flag_key)
        if has_flag == "true" then
            return room_id
        end
    end

    return nil
end

-- Find all rooms with a specific flag in a specific area
-- Returns: array of room_ids
function f2t_map_find_all_rooms_with_flag(area_id, flag)
    if not area_id then
        f2t_debug_log("[map] ERROR: f2t_map_find_all_rooms_with_flag called with nil area_id")
        return {}
    end

    if not flag then
        f2t_debug_log("[map] ERROR: f2t_map_find_all_rooms_with_flag called with nil flag")
        return {}
    end

    local results = {}
    local room_ids = getAreaRooms(area_id)

    if not room_ids then
        return results
    end

    local flag_key = string.format("fed2_flag_%s", flag)

    for _, room_id in ipairs(room_ids) do
        local has_flag = getRoomUserData(room_id, flag_key)
        if has_flag == "true" then
            table.insert(results, room_id)
        end
    end

    f2t_debug_log("[map] Found %d room(s) with flag '%s' in area %d", #results, flag, area_id)
    return results
end

-- Ensure current location is known, with automatic retry if needed
-- Takes an optional callback function to execute after location is confirmed
-- Returns: true if location is known, false if retry was initiated
function f2t_map_ensure_current_location(callback_fn, callback_args)
    -- Check if current location is known
    if F2T_MAP_CURRENT_ROOM_ID and roomExists(F2T_MAP_CURRENT_ROOM_ID) then
        return true  -- Location is known
    end

    -- Location unknown - send 'look' and retry
    cecho("\n<yellow>[map]<reset> Current location unknown - sending 'look' to update...\n")
    f2t_debug_log("[map] Current room ID: %s, exists: %s",
        tostring(F2T_MAP_CURRENT_ROOM_ID),
        F2T_MAP_CURRENT_ROOM_ID and tostring(roomExists(F2T_MAP_CURRENT_ROOM_ID)) or "N/A")

    send("look")

    -- If callback provided, execute it after GMCP updates
    if callback_fn then
        tempTimer(0.5, function()
            f2t_debug_log("[map] Retrying after 'look' command")
            if callback_args then
                callback_fn(unpack(callback_args))
            else
                callback_fn()
            end
        end)
    end

    return false  -- Location was unknown, retry initiated
end

-- Check if a specific room has a specific flag
-- Returns: true if room has the flag, false otherwise
function f2t_map_room_has_flag(room_id, flag)
    if not room_id or not flag then
        return false
    end

    local flag_key = string.format("fed2_flag_%s", flag)
    local has_flag = getRoomUserData(room_id, flag_key)
    return has_flag == "true"
end

f2t_debug_log("[map] Room query functions loaded")
