-- Circuit builder commands
-- User-facing commands for creating and managing circuit routes

-- Create a new circuit
function f2t_map_circuit_cmd_create(circuit_id)
    if not circuit_id or circuit_id == "" then
        cecho("\n<red>[map]<reset> Usage: map special circuit create <circuit_id>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Check if circuit already exists
    local existing = f2t_map_circuit_load(area_name, circuit_id)
    if existing then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' already exists in %s\n", circuit_id, area_name))
        return
    end

    -- Create new circuit with defaults
    local circuit_data = {
        vehicle_room = nil,  -- Must be set by user (Fed2 hash)
        stops = {},
        board_command = "in",
        exit_command = "out",
        boarding_pattern = nil,  -- Optional
        is_loop = true           -- Default to loop
    }

    -- Save circuit
    if f2t_map_circuit_save(area_name, circuit_id, circuit_data) then
        cecho(string.format("\n<green>[map]<reset> Created circuit '%s' in area %s\n", circuit_id, area_name))
        cecho("\n<dim_grey>Next: Set vehicle room (by hash), add stops, then connect<reset>\n")
    else
        cecho(string.format("\n<red>[map]<reset> Failed to create circuit '%s'\n", circuit_id))
    end
end

-- Set circuit property
function f2t_map_circuit_cmd_set(circuit_id, property, value)
    if not circuit_id or not property or not value then
        cecho("\n<red>[map]<reset> Usage: map special circuit set <circuit_id> <property> <value>\n")
        cecho("\n<dim_grey>Properties: vehicle_room, board_command, exit_command, boarding_pattern, is_loop<reset>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Set property based on type
    if property == "vehicle_room" then
        -- Accept either room number (convert to hash) or hash directly
        local room_num = tonumber(value)
        local hash = nil

        if room_num then
            -- Room number provided, convert to hash
            if not roomExists(room_num) then
                cecho(string.format("\n<red>[map]<reset> Room %d does not exist in map\n", room_num))
                return
            end
            hash = f2t_map_generate_hash_from_room(room_num)
            if not hash then
                cecho(string.format("\n<red>[map]<reset> Could not generate hash for room %d\n", room_num))
                return
            end
        else
            -- Assume it's a hash, validate format
            if not value:match("^[^%.]+%.[^%.]+%.%d+$") then
                cecho(string.format("\n<red>[map]<reset> Invalid hash format: %s\n", value))
                return
            end
            hash = value
        end

        circuit_data.vehicle_room = hash

    elseif property == "board_command" or property == "exit_command" or property == "boarding_pattern" then
        circuit_data[property] = value

    elseif property == "is_loop" then
        local bool_val = value:lower()
        if bool_val == "true" or bool_val == "yes" or bool_val == "1" then
            circuit_data.is_loop = true
        elseif bool_val == "false" or bool_val == "no" or bool_val == "0" then
            circuit_data.is_loop = false
        else
            cecho(string.format("\n<red>[map]<reset> Invalid boolean value: %s\n", value))
            return
        end

    else
        cecho(string.format("\n<red>[map]<reset> Unknown property: %s\n", property))
        return
    end

    -- Save updated circuit
    if f2t_map_circuit_save(area_name, circuit_id, circuit_data) then
        cecho(string.format("\n<green>[map]<reset> Set %s.%s = %s\n", circuit_id, property, tostring(value)))
    else
        cecho(string.format("\n<red>[map]<reset> Failed to update circuit '%s'\n", circuit_id))
    end
end

-- Add current room as a stop
function f2t_map_circuit_cmd_stop_add(circuit_id, stop_name)
    if not circuit_id or not stop_name then
        cecho("\n<red>[map]<reset> Usage: map special circuit stop add <circuit_id> <stop_name>\n")
        return
    end

    -- Get current room
    local current_room = F2T_MAP_CURRENT_ROOM_ID or gmcp.room.info.num
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Check if stop already exists
    for _, stop in ipairs(circuit_data.stops) do
        if stop.name == stop_name then
            cecho(string.format("\n<red>[map]<reset> Stop '%s' already exists in circuit\n", stop_name))
            return
        end
    end

    -- Generate hash for current room
    local hash = f2t_map_generate_hash_from_room(current_room)
    if not hash then
        cecho(string.format("\n<red>[map]<reset> Could not generate hash for room %d\n", current_room))
        return
    end

    -- Add stop
    table.insert(circuit_data.stops, {
        name = stop_name,
        hash = hash,
        arrival_pattern = stop_name  -- Default to stop name
    })

    -- Mark room as stop
    f2t_map_circuit_mark_stop(current_room, circuit_id, stop_name)

    -- Save updated circuit
    if f2t_map_circuit_save(area_name, circuit_id, circuit_data) then
        cecho(string.format("\n<green>[map]<reset> Added stop '%s' (hash: %s, room: %d) to circuit '%s'\n",
            stop_name, hash, current_room, circuit_id))
        cecho(string.format("\n<dim_grey>Stops: %d total<reset>\n", #circuit_data.stops))
    else
        cecho(string.format("\n<red>[map]<reset> Failed to update circuit '%s'\n", circuit_id))
    end
end

-- Set stop property
function f2t_map_circuit_cmd_stop_set(circuit_id, stop_name, property, value)
    if not circuit_id or not stop_name or not property or not value then
        cecho("\n<red>[map]<reset> Usage: map special circuit stop set <circuit_id> <stop_name> <property> <value>\n")
        cecho("\n<dim_grey>Properties: arrival_pattern<reset>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Find stop
    local stop = f2t_map_circuit_find_stop(circuit_data, stop_name)
    if not stop then
        cecho(string.format("\n<red>[map]<reset> Stop '%s' not found in circuit\n", stop_name))
        return
    end

    -- Set property
    if property == "arrival_pattern" then
        stop.arrival_pattern = value
    else
        cecho(string.format("\n<red>[map]<reset> Unknown property: %s\n", property))
        return
    end

    -- Save updated circuit
    if f2t_map_circuit_save(area_name, circuit_id, circuit_data) then
        cecho(string.format("\n<green>[map]<reset> Set %s.%s.%s = %s\n",
            circuit_id, stop_name, property, value))
    else
        cecho(string.format("\n<red>[map]<reset> Failed to update circuit '%s'\n", circuit_id))
    end
end

-- Generate all special exit connections for a circuit
function f2t_map_circuit_cmd_connect(circuit_id)
    if not circuit_id or circuit_id == "" then
        cecho("\n<red>[map]<reset> Usage: map special circuit connect <circuit_id>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Validate circuit data
    if not circuit_data.stops or #circuit_data.stops < 2 then
        cecho(string.format("\n<red>[map]<reset> Circuit needs at least 2 stops (has %d)\n",
            #(circuit_data.stops or {})))
        return
    end

    -- Create special exits from every stop to every other stop
    -- This allows pathfinding to choose the optimal destination
    local connection_count = 0
    local stops = circuit_data.stops

    for i, from_stop in ipairs(stops) do
        -- Convert hash to room ID
        local from_room = f2t_map_get_room_by_hash(from_stop.hash)
        if from_room then
            for j, to_stop in ipairs(stops) do
                -- Skip same room
                if i ~= j then
                    -- Convert hash to room ID
                    local to_room = f2t_map_get_room_by_hash(to_stop.hash)
                    if to_room then
                        local command = string.format("__circuit:%s:%s", circuit_id, to_stop.name)

                        -- Add special exit (fromRoomID, toRoomID, command)
                        addSpecialExit(from_room, to_room, command)

                        -- Add custom line for visual feedback (grey dashed line for circuits)
                        -- addCustomLine(roomID, id_to, direction, style, color, arrow)
                        addCustomLine(from_room, to_room, command, "dash line", color_table.grey, false)

                        connection_count = connection_count + 1

                        f2t_debug_log("[map-circuit] Connected: %s (%s -> %d) -> %s (%s -> %d)",
                            from_stop.name, from_stop.hash, from_room, to_stop.name, to_stop.hash, to_room)
                    else
                        cecho(string.format("\n<yellow>[map]<reset> Warning: Stop '%s' (hash %s) not found in map, skipping\n",
                            to_stop.name, to_stop.hash))
                    end
                end
            end
        else
            cecho(string.format("\n<yellow>[map]<reset> Warning: Stop '%s' (hash %s) not found in map, skipping\n",
                from_stop.name, from_stop.hash))
        end
    end

    cecho(string.format("\n<green>[map]<reset> Created %d circuit connections for '%s'\n",
        connection_count, circuit_id))

    -- Build stop names list
    local stop_names = {}
    for _, s in ipairs(stops) do
        table.insert(stop_names, s.name)
    end

    cecho(string.format("\n<dim_grey>Stops: %s<reset>\n",
        table.concat(stop_names, " → ")))
end

-- List all circuits in current area
function f2t_map_circuit_cmd_list()
    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- List all circuits
    local circuits = f2t_map_circuit_list(area_name)

    if #circuits == 0 then
        cecho(string.format("\n<yellow>[map]<reset> No circuits found in %s\n", area_name))
        return
    end

    cecho(string.format("\n<green>[map]<reset> Circuits in %s:\n", area_name))

    for _, circuit_id in ipairs(circuits) do
        local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
        if circuit_data then
            local stop_count = #(circuit_data.stops or {})
            cecho(string.format("  <yellow>%s<reset> - %d stops, vehicle room %s\n",
                circuit_id, stop_count, tostring(circuit_data.vehicle_room or "not set")))
        end
    end
end

-- Show circuit details
function f2t_map_circuit_cmd_show(circuit_id)
    if not circuit_id or circuit_id == "" then
        cecho("\n<red>[map]<reset> Usage: map special circuit show <circuit_id>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Display circuit details
    cecho(string.format("\n<green>[map]<reset> Circuit: <yellow>%s<reset>\n", circuit_id))
    cecho(string.format("  Area: %s\n", area_name))
    cecho(string.format("  vehicle_room: %s\n", tostring(circuit_data.vehicle_room or "not set")))
    cecho(string.format("  board_command: %s\n", circuit_data.board_command))
    cecho(string.format("  exit_command: %s\n", circuit_data.exit_command))
    cecho(string.format("  boarding_pattern: %s\n", circuit_data.boarding_pattern or "none"))
    cecho(string.format("  is_loop: %s\n", tostring(circuit_data.is_loop)))

    if circuit_data.stops and #circuit_data.stops > 0 then
        cecho(string.format("\n  <green>Stops (%d):<reset>\n", #circuit_data.stops))
        for i, stop in ipairs(circuit_data.stops) do
            local room_id = f2t_map_get_room_by_hash(stop.hash)
            local room_display = room_id and string.format("room %d", room_id) or "not mapped"

            cecho(string.format("    %d. <yellow>%s<reset> (hash: %s, %s)\n",
                i, stop.name, stop.hash, room_display))
            cecho(string.format("       arrival_pattern: %s\n", stop.arrival_pattern))
        end
    else
        cecho("\n  <yellow>No stops defined<reset>\n")
    end
end

-- Delete circuit and remove all connections
function f2t_map_circuit_cmd_delete(circuit_id)
    if not circuit_id or circuit_id == "" then
        cecho("\n<red>[map]<reset> Usage: map special circuit delete <circuit_id>\n")
        return
    end

    -- Get current area (must use Mudlet room ID, not Fed2 room number!)
    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        cecho("\n<red>[map]<reset> Cannot determine current location\n")
        return
    end

    local area_id = getRoomArea(current_room)
    local area_name = getRoomAreaName(area_id)

    -- Load circuit
    local circuit_data = f2t_map_circuit_load(area_name, circuit_id)
    if not circuit_data then
        cecho(string.format("\n<red>[map]<reset> Circuit '%s' not found in %s\n", circuit_id, area_name))
        return
    end

    -- Remove all special exits and custom lines for this circuit
    if circuit_data.stops then
        for _, stop in ipairs(circuit_data.stops) do
            -- Convert hash to room ID
            local stop_room = f2t_map_get_room_by_hash(stop.hash)
            if stop_room then
                local special_exits = getSpecialExits(stop_room)
                if special_exits then
                    for cmd, to_room in pairs(special_exits) do
                        -- Match format: __circuit:circuit_id:stop
                        if cmd:match("^__circuit:" .. circuit_id .. ":") then
                            removeSpecialExit(stop_room, cmd)
                            removeCustomLine(stop_room, to_room)
                            f2t_debug_log("[map-circuit] Removed exit: %s from room %d", cmd, stop_room)
                        end
                    end
                end

                -- Unmark stop
                f2t_map_circuit_unmark_stop(stop_room)
            end
        end
    end

    -- Delete circuit data
    if f2t_map_circuit_delete(area_name, circuit_id) then
        cecho(string.format("\n<green>[map]<reset> Deleted circuit '%s' and removed all connections\n", circuit_id))
    else
        cecho(string.format("\n<red>[map]<reset> Failed to delete circuit '%s'\n", circuit_id))
    end
end
