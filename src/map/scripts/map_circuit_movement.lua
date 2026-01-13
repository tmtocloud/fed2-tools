-- Circuit movement state machine
-- Handles the waiting/boarding/riding/exiting sequence for circuit-based transport

-- Global state for circuit travel
F2T_MAP_CIRCUIT_STATE = {
    active = false,
    circuit_id = nil,
    area_name = nil,
    vehicle_room = nil,
    destination_stop = nil,
    destination_room = nil,
    destination_pattern = nil,
    board_command = nil,
    exit_command = nil,
    boarding_pattern = nil,
    phase = nil,  -- "waiting_arrival", "waiting_destination"
    boarding_trigger_id = nil,
    arrival_trigger_id = nil
}

-- Create boarding trigger only
function f2t_map_circuit_create_boarding_trigger()
    if not F2T_MAP_CIRCUIT_STATE.active then
        return
    end

    -- Boarding trigger
    if F2T_MAP_CIRCUIT_STATE.boarding_pattern then
        local pattern = F2T_MAP_CIRCUIT_STATE.boarding_pattern

        f2t_debug_log("[map-circuit] Creating boarding trigger with pattern: [%s]", pattern)
        f2t_debug_log("[map-circuit] Pattern type: %s, length: %d", type(pattern), #pattern)

        F2T_MAP_CIRCUIT_STATE.boarding_trigger_id = tempRegexTrigger(
            pattern,
            function()
                f2t_debug_log("[map-circuit] Boarding trigger fired")
                f2t_map_circuit_handle_boarding()
            end)

        f2t_debug_log("[map-circuit] Boarding trigger ID: %s", tostring(F2T_MAP_CIRCUIT_STATE.boarding_trigger_id))
    else
        -- Generic boarding announcement (any circuit)
        local boarding_pattern = "^A canned voice announces"

        F2T_MAP_CIRCUIT_STATE.boarding_trigger_id = tempRegexTrigger(boarding_pattern, function()
            f2t_debug_log("[map-circuit] Generic boarding trigger fired")
            f2t_map_circuit_handle_boarding()
        end)

        f2t_debug_log("[map-circuit] Created generic boarding trigger")
    end
end

-- Create arrival trigger (called after boarding)
function f2t_map_circuit_create_arrival_trigger()
    if not F2T_MAP_CIRCUIT_STATE.active then
        return
    end

    -- Arrival trigger - match destination pattern directly
    F2T_MAP_CIRCUIT_STATE.arrival_trigger_id = tempRegexTrigger(
        F2T_MAP_CIRCUIT_STATE.destination_pattern,
        function()
            f2t_debug_log("[map-circuit] Arrival trigger fired")
            f2t_map_circuit_handle_arrival()
        end)

    f2t_debug_log("[map-circuit] Created arrival trigger: %s", F2T_MAP_CIRCUIT_STATE.destination_pattern)
end

-- Delete temporary triggers
function f2t_map_circuit_delete_triggers()
    if F2T_MAP_CIRCUIT_STATE.boarding_trigger_id then
        killTrigger(F2T_MAP_CIRCUIT_STATE.boarding_trigger_id)
        f2t_debug_log("[map-circuit] Deleted boarding trigger")
        F2T_MAP_CIRCUIT_STATE.boarding_trigger_id = nil
    end

    if F2T_MAP_CIRCUIT_STATE.arrival_trigger_id then
        killTrigger(F2T_MAP_CIRCUIT_STATE.arrival_trigger_id)
        f2t_debug_log("[map-circuit] Deleted arrival trigger")
        F2T_MAP_CIRCUIT_STATE.arrival_trigger_id = nil
    end
end

-- Begin circuit travel (called by speedwalk)
function f2t_map_circuit_begin(circuit_command)
    -- Parse command: __circuit:circuit_id:destination_stop
    local circuit_id, dest_stop = circuit_command:match("^__circuit:([^:]+):(.+)$")

    if not circuit_id or not dest_stop then
        cecho("\n<red>[map]<reset> Invalid circuit command format\n")
        f2t_debug_log("[map-circuit] Invalid command: %s", circuit_command)
        return false
    end

    -- Get area name from current Mudlet room ID (NOT gmcp.room.info.num!)
    -- Location is guaranteed to be known since f2t_map_navigate() already checked
    local current_room_id = F2T_MAP_CURRENT_ROOM_ID

    local area_id = getRoomArea(current_room_id)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit data
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found\n", circuit_id))
        return false
    end

    -- Find destination stop
    local dest_stop_data = f2t_map_circuit_find_stop(circuit_data, dest_stop)
    if not dest_stop_data then
        cecho(string.format("\n<red>[map]<reset> Stop '%s' not found in circuit\n", dest_stop))
        return false
    end

    -- Convert hash to room ID
    local dest_room_id = f2t_map_get_room_by_hash(dest_stop_data.hash)
    if not dest_room_id then
        cecho(string.format("\n<red>[map]<reset> Stop '%s' (hash %s) not found in map\n",
            dest_stop, dest_stop_data.hash))
        return false
    end

    -- Initialize state
    F2T_MAP_CIRCUIT_STATE = {
        active = true,
        circuit_id = circuit_id,
        area_name = area_name,
        vehicle_room = circuit_data.vehicle_room,  -- Hash of vehicle room
        destination_stop = dest_stop,
        destination_room = dest_room_id,
        destination_pattern = dest_stop_data.arrival_pattern,
        board_command = circuit_data.board_command or "in",
        exit_command = circuit_data.exit_command or "out",
        boarding_pattern = circuit_data.boarding_pattern,
        phase = "waiting_arrival",
        boarding_trigger_id = nil,
        arrival_trigger_id = nil
    }

    -- Create boarding trigger only (arrival trigger created after boarding)
    f2t_map_circuit_create_boarding_trigger()

    f2t_debug_log("[map-circuit] Started circuit travel: %s -> %s (hash %s, room %d)",
        circuit_id, dest_stop, dest_stop_data.hash, dest_room_id)

    cecho(string.format("\n<green>[map]<reset> Waiting for circuit to %s...\n", dest_stop))

    return true
end

-- Handle boarding announcement (called by trigger or manual boarding detection)
-- skip_send: if true, don't send board command (already on vehicle)
function f2t_map_circuit_handle_boarding(skip_send)
    if not F2T_MAP_CIRCUIT_STATE.active then
        return
    end

    if F2T_MAP_CIRCUIT_STATE.phase ~= "waiting_arrival" then
        return
    end

    f2t_debug_log("[map-circuit] Boarding circuit to %s", F2T_MAP_CIRCUIT_STATE.destination_stop)

    -- Delete boarding trigger (no longer needed)
    if F2T_MAP_CIRCUIT_STATE.boarding_trigger_id then
        killTrigger(F2T_MAP_CIRCUIT_STATE.boarding_trigger_id)
        f2t_debug_log("[map-circuit] Deleted boarding trigger")
        F2T_MAP_CIRCUIT_STATE.boarding_trigger_id = nil
    end

    -- Board the vehicle (unless already on it)
    if not skip_send then
        send(F2T_MAP_CIRCUIT_STATE.board_command)
    end

    -- Update state
    F2T_MAP_CIRCUIT_STATE.phase = "waiting_destination"

    cecho(string.format("\n<green>[map]<reset> Riding circuit to %s...\n",
        F2T_MAP_CIRCUIT_STATE.destination_stop))

    -- Create arrival trigger after delay to avoid matching boarding announcement text
    tempTimer(0.5, function()
        if F2T_MAP_CIRCUIT_STATE.active and F2T_MAP_CIRCUIT_STATE.phase == "waiting_destination" then
            f2t_map_circuit_create_arrival_trigger()
        end
    end)
end

-- Handle arrival announcement (called by trigger)
function f2t_map_circuit_handle_arrival()
    if not F2T_MAP_CIRCUIT_STATE.active then
        return
    end

    if F2T_MAP_CIRCUIT_STATE.phase ~= "waiting_destination" then
        return
    end

    f2t_debug_log("[map-circuit] Arrived at destination: %s", F2T_MAP_CIRCUIT_STATE.destination_stop)

    -- Delete arrival trigger immediately to prevent multiple firings
    if F2T_MAP_CIRCUIT_STATE.arrival_trigger_id then
        killTrigger(F2T_MAP_CIRCUIT_STATE.arrival_trigger_id)
        f2t_debug_log("[map-circuit] Deleted arrival trigger")
        F2T_MAP_CIRCUIT_STATE.arrival_trigger_id = nil
    end

    -- Exit the vehicle
    send(F2T_MAP_CIRCUIT_STATE.exit_command)

    -- Verify arrival and resume speedwalk after brief delay
    tempTimer(0.5, function()
        f2t_map_circuit_verify_and_resume()
    end)
end

-- Verify we arrived at correct destination and resume speedwalk
function f2t_map_circuit_verify_and_resume()
    -- Use Mudlet room ID, not Fed2 room number!
    local current_room = F2T_MAP_CURRENT_ROOM_ID

    if current_room == F2T_MAP_CIRCUIT_STATE.destination_room then
        cecho(string.format("\n<green>[map]<reset> Arrived at %s\n",
            F2T_MAP_CIRCUIT_STATE.destination_stop))

        -- Delete any remaining triggers (arrival trigger already deleted in handle_arrival)
        f2t_map_circuit_delete_triggers()

        -- Clear state BEFORE resuming speedwalk
        F2T_MAP_CIRCUIT_STATE = {active = false}

        -- Resume speedwalk (now that circuit is inactive, it will process normally)
        f2t_debug_log("[map-circuit] Resuming speedwalk after circuit completion")
        f2t_map_speedwalk_on_room_change()
    else
        cecho(string.format("\n<red>[map]<reset> Error: Expected room %d, but in room %d\n",
            F2T_MAP_CIRCUIT_STATE.destination_room, current_room))

        -- Delete any remaining triggers
        f2t_map_circuit_delete_triggers()

        -- Clear state and stop speedwalk
        F2T_MAP_CIRCUIT_STATE = {active = false}
        f2t_map_speedwalk_stop()
    end
end

-- Manually stop circuit travel
function f2t_map_circuit_stop()
    if not F2T_MAP_CIRCUIT_STATE.active then
        cecho("\n<yellow>[map]<reset> No active circuit travel\n")
        return
    end

    cecho("\n<yellow>[map]<reset> Circuit travel stopped\n")

    -- Delete triggers
    f2t_map_circuit_delete_triggers()

    F2T_MAP_CIRCUIT_STATE = {active = false}
    f2t_map_speedwalk_stop()
end

-- Get current circuit state (for debugging)
function f2t_map_circuit_status()
    if not F2T_MAP_CIRCUIT_STATE.active then
        cecho("\n<yellow>[map]<reset> No active circuit travel\n")
        return
    end

    cecho("\n<green>[map]<reset> Circuit Travel Status:\n")
    cecho(string.format("  Circuit: <yellow>%s<reset>\n", F2T_MAP_CIRCUIT_STATE.circuit_id))
    cecho(string.format("  Destination: <yellow>%s<reset> (room %d)\n",
        F2T_MAP_CIRCUIT_STATE.destination_stop, F2T_MAP_CIRCUIT_STATE.destination_room))
    cecho(string.format("  Phase: <yellow>%s<reset>\n", F2T_MAP_CIRCUIT_STATE.phase))
end
