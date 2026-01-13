-- Lock management for Federation 2 mapper
-- Provides functions to lock/unlock rooms and exits for navigation control

-- ========================================
-- Room Locking
-- ========================================

--- Lock a room (prevents pathfinding through it)
--- @param room_id number Room ID to lock
--- @return boolean true on success, false on failure
function f2t_map_manual_lock_room(room_id)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    -- Check if already locked
    if roomLocked(room_id) then
        cecho(string.format("\n<yellow>[map]<reset> Room %d is already locked\n", room_id))
        return true
    end

    -- Lock the room
    lockRoom(room_id, true)

    local room_name = getRoomName(room_id) or "unnamed"
    local hash = getRoomHashByID(room_id) or "unknown"

    cecho(string.format("\n<green>[map]<reset> Room locked: <white>%s<reset> (ID: %d)\n", room_name, room_id))
    cecho(string.format("  <dim_grey>Hash: %s<reset>\n", hash))
    cecho("  <red>Navigation will avoid this room<reset>\n")

    f2t_debug_log("[map_manual] Room locked: %d (%s)", room_id, hash)

    return true
end

--- Unlock a room
--- @param room_id number Room ID to unlock
--- @return boolean true on success, false on failure
function f2t_map_manual_unlock_room(room_id)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    -- Check if locked
    if not roomLocked(room_id) then
        cecho(string.format("\n<yellow>[map]<reset> Room %d is not locked\n", room_id))
        return true
    end

    -- Unlock the room
    lockRoom(room_id, false)

    local room_name = getRoomName(room_id) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Room unlocked: <white>%s<reset> (ID: %d)\n", room_name, room_id))

    f2t_debug_log("[map_manual] Room unlocked: %d", room_id)

    return true
end

-- ========================================
-- Exit Locking
-- ========================================

--- Lock an exit (prevents pathfinding through it)
--- @param room_id number Room ID
--- @param direction string Exit direction to lock
--- @return boolean true on success, false on failure
function f2t_map_manual_lock_exit(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    direction = string.lower(direction)

    -- Check if exit exists
    local exits = getRoomExits(room_id)
    if not exits or not exits[direction] then
        cecho(string.format("\n<red>[map]<reset> No exit '%s' from room %d\n", direction, room_id))
        return false
    end

    -- Check if already locked
    if hasExitLock(room_id, direction) then
        cecho(string.format("\n<yellow>[map]<reset> Exit '%s' in room %d is already locked\n", direction, room_id))
        return true
    end

    -- Lock the exit
    lockExit(room_id, direction, true)

    local room_name = getRoomName(room_id) or "unnamed"
    local dest_room = exits[direction]
    local dest_name = getRoomName(dest_room) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Exit locked: <white>%s<reset> --%s--> <white>%s<reset>\n",
        room_name, direction, dest_name))
    cecho("  <red>Navigation will avoid this exit<reset>\n")

    f2t_debug_log("[map_manual] Exit locked: %d --%s--> %d", room_id, direction, dest_room)

    return true
end

--- Unlock an exit
--- @param room_id number Room ID
--- @param direction string Exit direction to unlock
--- @return boolean true on success, false on failure
function f2t_map_manual_unlock_exit(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    direction = string.lower(direction)

    -- Check if exit exists
    local exits = getRoomExits(room_id)
    if not exits or not exits[direction] then
        cecho(string.format("\n<red>[map]<reset> No exit '%s' from room %d\n", direction, room_id))
        return false
    end

    -- Check if locked
    if not hasExitLock(room_id, direction) then
        cecho(string.format("\n<yellow>[map]<reset> Exit '%s' in room %d is not locked\n", direction, room_id))
        return true
    end

    -- Unlock the exit
    lockExit(room_id, direction, false)

    local room_name = getRoomName(room_id) or "unnamed"
    local dest_room = exits[direction]
    local dest_name = getRoomName(dest_room) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Exit unlocked: <white>%s<reset> --%s--> <white>%s<reset>\n",
        room_name, direction, dest_name))

    f2t_debug_log("[map_manual] Exit unlocked: %d --%s--> %d", room_id, direction, dest_room)

    return true
end

-- ========================================
-- Lock Status Display
-- ========================================

--- Display lock status for a room (room + all exits)
--- @param room_id number Room ID
function f2t_map_manual_lock_status(room_id)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return
    end

    local room_name = getRoomName(room_id) or "unnamed"
    local room_locked = roomLocked(room_id)

    cecho(string.format("\n<green>[map]<reset> Lock status for room %d (<white>%s<reset>):\n", room_id, room_name))

    -- Room lock status
    if room_locked then
        cecho("  <red>Room is LOCKED<reset> (navigation will avoid this room)\n")

        -- Check for death-related lock metadata
        local death_date = getRoomUserData(room_id, "f2t_death_date")
        if death_date and death_date ~= "" then
            cecho(string.format("  <red>Death Location<reset>: %s\n", death_date))
        end
    else
        cecho("  <green>Room is UNLOCKED<reset>\n")
    end

    -- Exit lock status
    local exits = getRoomExits(room_id)
    if exits and next(exits) ~= nil then
        cecho("\n  <yellow>Exit Lock Status:<reset>\n")

        local has_locked_exits = false
        for dir, dest_id in pairs(exits) do
            local locked = hasExitLock(room_id, dir)
            if locked then
                has_locked_exits = true
                local dest_name = getRoomName(dest_id) or "unnamed"
                cecho(string.format("    <red>%-10s<reset> <red>LOCKED<reset>   -> <white>%s<reset> (ID: %d)\n",
                    dir, dest_name, dest_id))
            end
        end

        if not has_locked_exits then
            cecho("    <green>No locked exits<reset>\n")
        end
    else
        cecho("\n  <dim_grey>No exits to lock<reset>\n")
    end

    cecho("\n")
end

f2t_debug_log("[map] Manual lock management initialized")
