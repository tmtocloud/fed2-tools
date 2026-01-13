-- Manual exit management for Federation 2 mapper
-- Provides functions to add, remove, and list exits

-- ========================================
-- Exit Creation
-- ========================================

--- Add a manual exit between two rooms
--- @param from_room number Source room ID
--- @param to_room number Destination room ID
--- @param direction string Exit direction (e.g., "north", "south")
--- @param bidirectional boolean If true, create reverse exit as well
--- @return boolean true on success, false on failure
function f2t_map_manual_add_exit(from_room, to_room, direction, bidirectional)
    if not from_room or not roomExists(from_room) then
        cecho(string.format("\n<red>[map]<reset> Source room %s does not exist\n", tostring(from_room)))
        return false
    end

    if not to_room or not roomExists(to_room) then
        cecho(string.format("\n<red>[map]<reset> Destination room %s does not exist\n", tostring(to_room)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    -- Validate direction
    local valid_directions = {
        "north", "south", "east", "west",
        "northeast", "northwest", "southeast", "southwest",
        "up", "down",
        "in", "out"
    }

    direction = string.lower(direction)
    if not f2t_has_value(valid_directions, direction) then
        cecho(string.format("\n<red>[map]<reset> Invalid direction: %s\n", direction))
        cecho(string.format("\n<dim_grey>Valid directions: %s<reset>\n", table.concat(valid_directions, ", ")))
        return false
    end

    -- Get reverse direction for bidirectional exits
    local reverse_dir_map = {
        north = "south", south = "north",
        east = "west", west = "east",
        northeast = "southwest", southwest = "northeast",
        northwest = "southeast", southeast = "northwest",
        up = "down", down = "up",
        ["in"] = "out", out = "in"
    }

    -- Create the exit
    setExit(from_room, to_room, direction)

    local from_name = getRoomName(from_room) or string.format("Room %d", from_room)
    local to_name = getRoomName(to_room) or string.format("Room %d", to_room)

    cecho(string.format("\n<green>[map]<reset> Exit created: <white>%s<reset> --%s--> <white>%s<reset>\n",
        from_name, direction, to_name))

    f2t_debug_log("[map_manual] Exit created: %d --%s--> %d", from_room, direction, to_room)

    -- Create bidirectional exit if requested
    if bidirectional then
        local reverse_dir = reverse_dir_map[direction]
        if reverse_dir then
            setExit(to_room, from_room, reverse_dir)
            cecho(string.format("<green>[map]<reset> Reverse exit created: <white>%s<reset> --%s--> <white>%s<reset>\n",
                to_name, reverse_dir, from_name))

            f2t_debug_log("[map_manual] Reverse exit created: %d --%s--> %d", to_room, reverse_dir, from_room)
        else
            cecho(string.format("\n<yellow>[map]<reset> Warning: No reverse direction for '%s'\n", direction))
        end
    end

    return true
end

-- ========================================
-- Exit Removal
-- ========================================

--- Remove an exit from a room (with confirmation)
--- @param room_id number Room ID
--- @param direction string Exit direction to remove
function f2t_map_manual_remove_exit(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return
    end

    direction = string.lower(direction)

    -- Check if exit exists
    local exits = getRoomExits(room_id)
    if not exits or not exits[direction] then
        cecho(string.format("\n<red>[map]<reset> No exit '%s' from room %d\n", direction, room_id))
        return
    end

    local dest_room = exits[direction]
    local room_name = getRoomName(room_id) or string.format("Room %d", room_id)
    local dest_name = getRoomName(dest_room) or string.format("Room %d", dest_room)

    -- Request confirmation
    local action = string.format("remove exit '%s' from room %d (%s -> %s)",
        direction, room_id, room_name, dest_name)

    f2t_map_manual_request_confirmation(action, function(data)
        local id = data.room_id
        local dir = data.direction

        -- Verify room and exit still exist
        if not roomExists(id) then
            cecho(string.format("\n<red>[map]<reset> Room %d no longer exists\n", id))
            return
        end

        local current_exits = getRoomExits(id)
        if not current_exits or not current_exits[dir] then
            cecho(string.format("\n<red>[map]<reset> Exit '%s' no longer exists in room %d\n", dir, id))
            return
        end

        -- Remove the exit
        setExitStub(id, dir, 0)  -- Setting stub to 0 removes the exit

        cecho(string.format("\n<green>[map]<reset> Exit removed: <white>%s<reset> (%s)\n",
            dir, data.description))

        f2t_debug_log("[map_manual] Exit removed: %d --%s--> (deleted)", id, dir)
    end, {
        room_id = room_id,
        direction = direction,
        description = string.format("%s -> %s", room_name, dest_name)
    })
end

-- ========================================
-- Exit Listing
-- ========================================

--- List all exits for a room
--- @param room_id number Room ID
function f2t_map_manual_list_exits(room_id)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return
    end

    local room_name = getRoomName(room_id) or "unnamed"

    -- Get standard exits
    local exits = getRoomExits(room_id)

    -- Get special exits
    local special_exits = getSpecialExitsSwap(room_id)

    cecho(string.format("\n<green>[map]<reset> Exits for room %d (<white>%s<reset>):\n", room_id, room_name))

    -- Display standard exits
    if exits and next(exits) ~= nil then
        cecho("\n  <yellow>Standard Exits:<reset>\n")
        for dir, dest_id in pairs(exits) do
            local dest_name = getRoomName(dest_id) or "unnamed"
            local dest_hash = getRoomHashByID(dest_id) or "unknown"
            cecho(string.format("    <cyan>%-10s<reset> -> <white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
                dir, dest_name, dest_id, dest_hash))
        end
    else
        cecho("\n  <dim_grey>No standard exits<reset>\n")
    end

    -- Display special exits
    if special_exits and next(special_exits) ~= nil then
        cecho("\n  <yellow>Special Exits:<reset>\n")
        for dest_id, command in pairs(special_exits) do
            local dest_name = getRoomName(dest_id) or "unnamed"
            local dest_hash = getRoomHashByID(dest_id) or "unknown"

            -- Check if auto-transit
            if command:match("^__move_no_op_%d+$") then
                cecho(string.format("    <magenta>%-30s<reset> <dim_grey>(auto-transit)<reset> -> <white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
                    command, dest_name, dest_id, dest_hash))
            else
                cecho(string.format("    <magenta>%-30s<reset> -> <white>%s<reset> <dim_grey>[%d | %s]<reset>\n",
                    command, dest_name, dest_id, dest_hash))
            end
        end
    else
        cecho("\n  <dim_grey>No special exits<reset>\n")
    end

    cecho("\n")
end

f2t_debug_log("[map] Manual exit management initialized")
