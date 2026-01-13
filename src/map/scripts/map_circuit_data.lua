-- Circuit data storage and retrieval
-- Manages circuit route metadata in areaUserData and station markers in roomUserData

-- Save circuit route definition to map area
function f2t_map_circuit_save(area_name, circuit_id, circuit_data)
    if not area_name or not circuit_id or not circuit_data then
        f2t_debug_log("[map-circuit] save failed: missing parameters")
        return false
    end

    -- Convert area name to area ID
    local area_id = f2t_map_get_area_id(area_name)
    if not area_id then
        f2t_debug_log("[map-circuit] save failed: area '%s' not found", area_name)
        return false
    end

    local key = string.format("f2t_circuit_%s", circuit_id)
    local json = yajl.to_string(circuit_data)
    setAreaUserData(area_id, key, json)

    f2t_debug_log("[map-circuit] Saved circuit '%s' to area '%s' (ID %d)", circuit_id, area_name, area_id)
    return true
end

-- Load circuit route definition from map area
function f2t_map_circuit_load(area_name, circuit_id)
    if not area_name or not circuit_id then
        f2t_debug_log("[map-circuit] load failed: missing parameters")
        return nil
    end

    -- Convert area name to area ID
    local area_id = f2t_map_get_area_id(area_name)
    if not area_id then
        f2t_debug_log("[map-circuit] load failed: area '%s' not found", area_name)
        return nil
    end

    local key = string.format("f2t_circuit_%s", circuit_id)
    local json = getAreaUserData(area_id, key)

    if not json or json == "" then
        f2t_debug_log("[map-circuit] Circuit '%s' not found in area '%s'", circuit_id, area_name)
        return nil
    end

    local circuit_data = yajl.to_value(json)
    f2t_debug_log("[map-circuit] Loaded circuit '%s' from area '%s' (ID %d)", circuit_id, area_name, area_id)
    return circuit_data
end

-- Delete circuit route definition from map area
function f2t_map_circuit_delete(area_name, circuit_id)
    if not area_name or not circuit_id then
        f2t_debug_log("[map-circuit] delete failed: missing parameters")
        return false
    end

    -- Convert area name to area ID
    local area_id = f2t_map_get_area_id(area_name)
    if not area_id then
        f2t_debug_log("[map-circuit] delete failed: area '%s' not found", area_name)
        return false
    end

    local key = string.format("f2t_circuit_%s", circuit_id)
    setAreaUserData(area_id, key, "")

    f2t_debug_log("[map-circuit] Deleted circuit '%s' from area '%s' (ID %d)", circuit_id, area_name, area_id)
    return true
end

-- List all circuits in an area
function f2t_map_circuit_list(area_name)
    if not area_name then
        f2t_debug_log("[map-circuit] list failed: missing area_name")
        return {}
    end

    -- Convert area name to area ID
    local area_id = f2t_map_get_area_id(area_name)
    if not area_id then
        f2t_debug_log("[map-circuit] list failed: area '%s' not found", area_name)
        return {}
    end

    local all_data = getAllAreaUserData(area_id)
    local circuits = {}

    if all_data then
        for key, _ in pairs(all_data) do
            if key:match("^f2t_circuit_") then
                local circuit_id = key:gsub("^f2t_circuit_", "")
                table.insert(circuits, circuit_id)
            end
        end
    end

    f2t_debug_log("[map-circuit] Found %d circuits in area '%s' (ID %d)", #circuits, area_name, area_id)
    return circuits
end

-- Mark a room as a circuit stop
function f2t_map_circuit_mark_stop(room_id, circuit_id, stop_name)
    if not room_id or not circuit_id or not stop_name then
        f2t_debug_log("[map-circuit] mark_stop failed: missing parameters")
        return false
    end

    local marker = string.format("%s:%s", circuit_id, stop_name)
    setRoomUserData(room_id, "f2t_circuit_stop", marker)

    f2t_debug_log("[map-circuit] Marked room %d as stop '%s' for circuit '%s'", room_id, stop_name, circuit_id)
    return true
end

-- Get circuit stop marker from a room
function f2t_map_circuit_get_stop(room_id)
    if not room_id then
        return nil
    end

    local marker = getRoomUserData(room_id, "f2t_circuit_stop")

    if not marker or marker == "" then
        return nil
    end

    local circuit_id, stop_name = marker:match("^([^:]+):(.+)$")
    return circuit_id, stop_name
end

-- Remove circuit stop marker from a room
function f2t_map_circuit_unmark_stop(room_id)
    if not room_id then
        return false
    end

    setRoomUserData(room_id, "f2t_circuit_stop", "")
    f2t_debug_log("[map-circuit] Unmarked room %d as circuit stop", room_id)
    return true
end

-- Get the vehicle room number for a circuit
function f2t_map_circuit_get_vehicle_room(area_name, circuit_id)
    local circuit = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit then
        return nil
    end
    return circuit.vehicle_room
end

-- Find stop data by name in circuit
function f2t_map_circuit_find_stop(circuit_data, stop_name)
    if not circuit_data or not circuit_data.stops then
        return nil
    end

    for _, stop in ipairs(circuit_data.stops) do
        if stop.name == stop_name then
            return stop
        end
    end

    return nil
end

-- Get stop index in circuit route
function f2t_map_circuit_get_stop_index(circuit_data, stop_name)
    if not circuit_data or not circuit_data.stops then
        return nil
    end

    for i, stop in ipairs(circuit_data.stops) do
        if stop.name == stop_name then
            return i
        end
    end

    return nil
end

-- Check if circuit is a loop (returns to start)
function f2t_map_circuit_is_loop(circuit_data)
    if not circuit_data then
        return false
    end
    return circuit_data.is_loop == true
end
