-- Special navigation behaviors for Federation 2 mapper
-- Handles on-arrival commands and special exits

-- ========================================
-- Constants
-- ========================================

-- Pending special exit discovery state
F2T_MAP_PENDING_SPECIAL_EXIT = nil

-- Last completed discovery (for reverse command)
F2T_MAP_LAST_DISCOVERY = nil

-- ========================================
-- On-Arrival Command Functions
-- ========================================

-- Arrival command execution types
F2T_MAP_ARRIVAL_TYPE_ALWAYS = "always"       -- Run every time we enter the room (default)
F2T_MAP_ARRIVAL_TYPE_ONCE_ROOM = "once-room" -- Run once per room, then disable
F2T_MAP_ARRIVAL_TYPE_ONCE_AREA = "once-area" -- Run once per area visit, reset when leaving area
F2T_MAP_ARRIVAL_TYPE_ONCE_EVER = "once-ever" -- Run once ever, then disable

-- Tracking for once-area commands
F2T_MAP_ARRIVAL_ONCE_AREA_EXECUTED = F2T_MAP_ARRIVAL_ONCE_AREA_EXECUTED or {}
F2T_MAP_ARRIVAL_LAST_AREA = F2T_MAP_ARRIVAL_LAST_AREA or nil

-- Set on-arrival command for a room
-- @param room_id: Mudlet room ID
-- @param command: Command to execute when arriving in room
-- @param exec_type: Execution type (always, once-room, once-area, once-ever). Defaults to "always"
function f2t_map_special_set_arrival(room_id, command, exec_type)
    if not room_id or not roomExists(room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid room ID: %s", tostring(room_id))
        return false
    end

    if not command or command == "" then
        f2t_debug_log("[map-special] ERROR: Invalid command")
        return false
    end

    -- Default to "always" if not specified
    exec_type = exec_type or F2T_MAP_ARRIVAL_TYPE_ALWAYS

    -- Validate execution type
    if exec_type ~= F2T_MAP_ARRIVAL_TYPE_ALWAYS and
       exec_type ~= F2T_MAP_ARRIVAL_TYPE_ONCE_ROOM and
       exec_type ~= F2T_MAP_ARRIVAL_TYPE_ONCE_AREA and
       exec_type ~= F2T_MAP_ARRIVAL_TYPE_ONCE_EVER then
        f2t_debug_log("[map-special] ERROR: Invalid execution type: %s", tostring(exec_type))
        return false
    end

    setRoomUserData(room_id, "fed2_arrival_cmd", command)
    setRoomUserData(room_id, "fed2_arrival_type", exec_type)

    -- Initialize executed flag for once-room and once-ever
    if exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_ROOM or exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_EVER then
        setRoomUserData(room_id, "fed2_arrival_executed", "false")
    end

    f2t_debug_log("[map-special] Set arrival command for room %d: %s (type: %s)", room_id, command, exec_type)
    return true
end

-- Get on-arrival command for a room and check if it should execute
-- @param room_id: Mudlet room ID
-- @return: command string or nil, exec_type
function f2t_map_special_get_arrival(room_id)
    if not room_id or not roomExists(room_id) then
        return nil, nil
    end

    local command = getRoomUserData(room_id, "fed2_arrival_cmd")
    if command == "" or not command then
        return nil, nil
    end

    local exec_type = getRoomUserData(room_id, "fed2_arrival_type")
    if exec_type == "" or not exec_type then
        exec_type = F2T_MAP_ARRIVAL_TYPE_ALWAYS  -- Default for legacy commands
    end

    return command, exec_type
end

-- Check if an arrival command should execute based on its type
-- @param room_id: Mudlet room ID
-- @param exec_type: Execution type
-- @return: boolean (true if should execute)
function f2t_map_special_should_execute_arrival(room_id, exec_type)
    if not room_id or not exec_type then
        return false
    end

    if exec_type == F2T_MAP_ARRIVAL_TYPE_ALWAYS then
        return true
    end

    if exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_ROOM or exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_EVER then
        local executed = getRoomUserData(room_id, "fed2_arrival_executed")
        if executed == "true" then
            f2t_debug_log("[map-special] Arrival command already executed (type: %s)", exec_type)
            return false
        end
        return true
    end

    if exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_AREA then
        -- Check if we changed areas
        local current_area = getRoomArea(room_id)
        if current_area ~= F2T_MAP_ARRIVAL_LAST_AREA then
            -- Entered new area, reset executed flags
            F2T_MAP_ARRIVAL_ONCE_AREA_EXECUTED = {}
            F2T_MAP_ARRIVAL_LAST_AREA = current_area
            f2t_debug_log("[map-special] Entered new area %d, reset once-area flags", current_area)
        end

        -- Check if already executed in this area
        local room_key = tostring(room_id)
        if F2T_MAP_ARRIVAL_ONCE_AREA_EXECUTED[room_key] then
            f2t_debug_log("[map-special] Arrival command already executed in this area")
            return false
        end

        return true
    end

    return false
end

-- Mark an arrival command as executed
-- @param room_id: Mudlet room ID
-- @param exec_type: Execution type
function f2t_map_special_mark_arrival_executed(room_id, exec_type)
    if not room_id or not exec_type then
        return
    end

    if exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_ROOM or exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_EVER then
        setRoomUserData(room_id, "fed2_arrival_executed", "true")
        f2t_debug_log("[map-special] Marked arrival command as executed (type: %s)", exec_type)
    end

    if exec_type == F2T_MAP_ARRIVAL_TYPE_ONCE_AREA then
        local room_key = tostring(room_id)
        F2T_MAP_ARRIVAL_ONCE_AREA_EXECUTED[room_key] = true
        f2t_debug_log("[map-special] Marked arrival command as executed in area")
    end
end

-- Remove on-arrival command for a room
-- @param room_id: Mudlet room ID
function f2t_map_special_remove_arrival(room_id)
    if not room_id or not roomExists(room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid room ID: %s", tostring(room_id))
        return false
    end

    setRoomUserData(room_id, "fed2_arrival_cmd", "")
    f2t_debug_log("[map-special] Removed arrival command for room %d", room_id)
    return true
end

-- ========================================
-- Special Exit Functions
-- ========================================

-- Create special exit between two rooms
-- @param from_room_id: Source room Mudlet ID
-- @param to_room_id: Destination room Mudlet ID
-- @param command: Command to execute (or "noop" for auto-transit)
-- @return: success (boolean)
function f2t_map_special_set_exit(from_room_id, to_room_id, command)
    if not from_room_id or not roomExists(from_room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid from_room_id: %s", tostring(from_room_id))
        return false
    end

    if not to_room_id or not roomExists(to_room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid to_room_id: %s", tostring(to_room_id))
        return false
    end

    if not command or command == "" then
        f2t_debug_log("[map-special] ERROR: Invalid command")
        return false
    end

    -- Trim whitespace from command
    command = command:match("^%s*(.-)%s*$")

    -- For "noop" (auto-transit), convert to internal format "__move_no_op_<room_id>"
    -- This allows multiple auto-transit exits from the same room
    local exit_command = command
    if command == "noop" then
        exit_command = string.format("__move_no_op_%d", to_room_id)
    end

    -- Create the special exit using Mudlet API
    addSpecialExit(from_room_id, to_room_id, exit_command)

    -- Add custom line for visual feedback (grey dashed line with arrow)
    addCustomLine(from_room_id, to_room_id, exit_command, "dash line", color_table.grey, true)

    f2t_debug_log("[map-special] Created special exit: room %d -> room %d (command: %s)",
        from_room_id, to_room_id, exit_command)

    return true
end

-- Get all special exits from a room
-- @param room_id: Mudlet room ID
-- @return: table of {command = dest_room_id} or empty table
function f2t_map_special_get_all_exits(room_id)
    if not room_id or not roomExists(room_id) then
        return {}
    end

    -- Use Mudlet API to get special exits
    -- getSpecialExits returns: {[dest_room] = {command = exit_id}}
    -- We need to convert to: {command = dest_room}
    local mudlet_exits = getSpecialExits(room_id) or {}
    local exits = {}

    for dest_room_id, commands in pairs(mudlet_exits) do
        if type(commands) == "table" then
            for command, _ in pairs(commands) do
                exits[command] = dest_room_id
            end
        end
    end

    return exits
end

-- Remove special exit from a room
-- @param room_id: Mudlet room ID
-- @param command: Special exit command to remove
-- @return: success (boolean)
function f2t_map_special_remove_exit(room_id, command)
    if not room_id or not roomExists(room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid room ID: %s", tostring(room_id))
        return false
    end

    if not command or command == "" then
        f2t_debug_log("[map-special] ERROR: Invalid command")
        return false
    end

    -- Check if the exit actually exists
    local exits = f2t_map_special_get_all_exits(room_id)
    if not exits or not exits[command] then
        f2t_debug_log("[map-special] No exit found for command '%s' in room %d", command, room_id)
        return false
    end

    -- Remove the special exit using Mudlet API
    removeSpecialExit(room_id, command)

    -- Remove the custom line as well
    removeCustomLine(room_id, command)

    f2t_debug_log("[map-special] Removed special exit from room %d: %s", room_id, command)
    return true
end

-- ========================================
-- Discovery-Based Special Exit Creation
-- ========================================

-- Start discovery process for special exit
-- @param from_room_id: Source room Mudlet ID
-- @param command: Command to test
function f2t_map_special_exit_discovery_start(from_room_id, command)
    if not from_room_id or not roomExists(from_room_id) then
        cecho("\n<red>[map]<reset> Error: Invalid source room\n")
        return false
    end

    -- Store pending state
    F2T_MAP_PENDING_SPECIAL_EXIT = {
        from_room = from_room_id,
        command = command
    }

    local from_name = getRoomName(from_room_id) or string.format("Room %d", from_room_id)

    cecho(string.format("\n<green>[map]<reset> Testing special exit from <white>%s<reset>\n", from_name))

    -- Check if this is "noop" (auto-transit keyword)
    if command == "noop" then
        cecho("\n<dim_grey>  Command: (auto-transit, wait for GMCP)<reset>\n")
        cecho("\n<yellow>[map]<reset> Auto-transit detected. Move to the destination room naturally.\n")
        f2t_debug_log("[map-special] Discovery started (auto-transit): from_room=%d", from_room_id)
    else
        cecho(string.format("\n<dim_grey>  Command: %s<reset>\n", command))
        cecho("\n<dim_grey>Sending command and waiting for room change...<reset>\n")
        f2t_debug_log("[map-special] Discovery started: from_room=%d, command=%s", from_room_id, command)

        -- Send the command to test it
        send(command)
    end

    return true
end

-- Complete discovery process (called by GMCP event handler on room change)
-- @param to_room_id: Destination room Mudlet ID
function f2t_map_special_exit_discovery_complete(to_room_id)
    if not F2T_MAP_PENDING_SPECIAL_EXIT then
        return false
    end

    local from_room = F2T_MAP_PENDING_SPECIAL_EXIT.from_room
    local command = F2T_MAP_PENDING_SPECIAL_EXIT.command

    -- Validate rooms are different
    if from_room == to_room_id then
        cecho("\n<yellow>[map]<reset> Warning: Command did not change rooms\n")
        cecho("\n<dim_grey>Special exit not created (source and destination are the same)<reset>\n")
        F2T_MAP_PENDING_SPECIAL_EXIT = nil
        f2t_debug_log("[map-special] Discovery failed: rooms are the same")
        return false
    end

    -- Create the special exit
    local success = f2t_map_special_set_exit(from_room, to_room_id, command)

    if success then
        local from_name = getRoomName(from_room) or string.format("Room %d", from_room)
        local to_name = getRoomName(to_room_id) or string.format("Room %d", to_room_id)

        if command == "noop" then
            cecho(string.format("\n<green>[map]<reset> Special exit created: <white>%s<reset> -> <white>%s<reset>\n",
                from_name, to_name))
            cecho("\n<dim_grey>  Command: (auto-transit, wait for GMCP)<reset>\n")
        else
            cecho(string.format("\n<green>[map]<reset> Special exit created: <white>%s<reset> -> <white>%s<reset>\n",
                from_name, to_name))
            cecho(string.format("\n<dim_grey>  Command: %s<reset>\n", command))
        end

        -- Store last discovery for reverse command
        F2T_MAP_LAST_DISCOVERY = {
            from_room = from_room,
            to_room = to_room_id,
            command = command
        }

        f2t_debug_log("[map-special] Discovery complete: created exit from %d to %d (command: %s)",
            from_room, to_room_id, command)
    else
        cecho("\n<red>[map]<reset> Failed to create special exit\n")
        f2t_debug_log("[map-special] Discovery failed: could not create exit")
    end

    -- Clear pending state
    F2T_MAP_PENDING_SPECIAL_EXIT = nil

    return success
end

-- ========================================
-- Reverse Special Exit Creation
-- ========================================

-- Create reverse special exit (swap source and destination)
-- @param from_room_id: Original source room Mudlet ID
-- @param to_room_id: Original destination room Mudlet ID
-- @param command: Command to use for reverse exit (defaults to same command)
-- @return: success (boolean)
function f2t_map_special_create_reverse(from_room_id, to_room_id, command)
    if not from_room_id or not roomExists(from_room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid from_room_id for reverse: %s", tostring(from_room_id))
        return false
    end

    if not to_room_id or not roomExists(to_room_id) then
        f2t_debug_log("[map-special] ERROR: Invalid to_room_id for reverse: %s", tostring(to_room_id))
        return false
    end

    -- Create exit in opposite direction (swap from/to)
    local success = f2t_map_special_set_exit(to_room_id, from_room_id, command)

    if success then
        f2t_debug_log("[map-special] Created reverse special exit: room %d -> room %d (command: %s)",
            to_room_id, from_room_id, command)
    end

    return success
end

-- Reverse last discovery exit
-- @param current_room_id: Current room Mudlet ID (must be the destination of last discovery)
-- @param command: Optional command override (defaults to same command used in discovery)
-- @return: success (boolean), error_message (string), from_room_id, to_room_id, command
function f2t_map_special_reverse_exit(current_room_id, command)
    if not current_room_id or not roomExists(current_room_id) then
        return false, "Invalid room", nil, nil, nil
    end

    -- Check if we have a last discovery
    if not F2T_MAP_LAST_DISCOVERY then
        return false, "No recent discovery to reverse. Use discovery method first.", nil, nil, nil
    end

    -- Verify we're in the destination room of the last discovery
    if current_room_id ~= F2T_MAP_LAST_DISCOVERY.to_room then
        local expected_name = getRoomName(F2T_MAP_LAST_DISCOVERY.to_room) or
                             string.format("Room %d", F2T_MAP_LAST_DISCOVERY.to_room)
        return false, string.format("Not in destination room. Navigate to %s first.", expected_name),
               nil, nil, nil
    end

    -- Use provided command or default to discovery command
    local reverse_command = command or F2T_MAP_LAST_DISCOVERY.command

    -- Create reverse exit: destination -> source
    local from_room_id = F2T_MAP_LAST_DISCOVERY.to_room  -- Current room (destination)
    local dest_room_id = F2T_MAP_LAST_DISCOVERY.from_room  -- Original source

    local success = f2t_map_special_create_reverse(F2T_MAP_LAST_DISCOVERY.from_room,
                                                     F2T_MAP_LAST_DISCOVERY.to_room,
                                                     reverse_command)
    if not success then
        return false, "Failed to create reverse exit", nil, nil, nil
    end

    return true, nil, from_room_id, dest_room_id, reverse_command
end

-- ========================================
-- Display Functions
-- ========================================

-- List all rooms with on-arrival commands
function f2t_map_special_list_arrivals()
    local rooms_with_arrivals = {}

    -- Scan all rooms for arrival commands
    local all_rooms = getRooms()
    for room_id, _ in pairs(all_rooms) do
        local arrival_cmd, exec_type = f2t_map_special_get_arrival(room_id)
        if arrival_cmd then
            table.insert(rooms_with_arrivals, {
                id = room_id,
                name = getRoomName(room_id) or "unnamed",
                command = arrival_cmd,
                exec_type = exec_type or F2T_MAP_ARRIVAL_TYPE_ALWAYS
            })
        end
    end

    -- Sort by room name
    table.sort(rooms_with_arrivals, function(a, b)
        return a.name < b.name
    end)

    cecho("\n<green>[map]<reset> Rooms with on-arrival commands\n")

    if #rooms_with_arrivals == 0 then
        cecho("\n<dim_grey>No on-arrival commands configured.<reset>\n")
        return
    end

    for _, room in ipairs(rooms_with_arrivals) do
        local hash = f2t_map_generate_hash_from_room(room.id) or "unknown"
        cecho(string.format("\n<white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
            room.name, room.id, hash))
        cecho(string.format("  <yellow>%s<reset> <cyan>(%s)<reset>\n", room.command, room.exec_type))
    end

    cecho(string.format("\n<dim_grey>Total: %d room(s)<reset>\n", #rooms_with_arrivals))
end

-- List all special behaviors for a room
-- @param room_id: Mudlet room ID
function f2t_map_special_list(room_id)
    if not room_id or not roomExists(room_id) then
        cecho("\n<red>[map]<reset> Invalid room\n")
        return
    end

    local room_name = getRoomName(room_id)
    local hash = f2t_map_generate_hash_from_room(room_id)

    cecho(string.format("\n<green>[map]<reset> Special behaviors for room %d (<white>%s<reset>)\n",
        room_id, room_name or "unnamed"))

    if hash then
        cecho(string.format("<dim_grey>Hash: %s<reset>\n", hash))
    end

    -- On-arrival command
    local arrival_cmd = f2t_map_special_get_arrival(room_id)
    if arrival_cmd then
        cecho(string.format("\n<cyan>On-Arrival Command:<reset>\n"))
        cecho(string.format("  <white>%s<reset>\n", arrival_cmd))
    end

    -- Special exits
    local exits = f2t_map_special_get_all_exits(room_id)
    if exits and next(exits) ~= nil then
        cecho(string.format("\n<cyan>Special Exits:<reset>\n"))
        for command, dest_room_id in pairs(exits) do
            local dest_name = getRoomName(dest_room_id) or "unnamed"
            local dest_hash = f2t_map_generate_hash_from_room(dest_room_id) or "unknown"

            -- Check if this is a __move_no_op command (prefixed with room ID)
            if command:match("^__move_no_op_%d+$") then
                cecho(string.format("  <yellow>%s<reset> <dim_grey>(auto-transit, wait for GMCP)<reset> -> <white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
                    command, dest_name, dest_room_id, dest_hash))
            else
                cecho(string.format("  <yellow>%s<reset> -> <white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
                    command, dest_name, dest_room_id, dest_hash))
            end
        end
    end

    -- Show message if no special behaviors
    if not arrival_cmd and (not exits or next(exits) == nil) then
        cecho("\n<dim_grey>No special behaviors configured for this room.<reset>\n")
    end
end

f2t_debug_log("[map-special] Special navigation system initialized")
