-- Jump special exit management for Federation 2 mapper
-- Automatically creates special exits for jump commands when visiting link rooms

-- ========================================
-- Jump Destination Capture State
-- ========================================

F2T_MAP_JUMP_CAPTURE = {
    expecting = false,  -- Set when we send jump command, waiting for output
    active = false,     -- Set when we detect jump output headers
    room_id = nil,
    source_system = nil,
    destinations = {},
    in_output = false  -- Track if we're currently reading jump output
}

-- Timer for detecting end of jump output
local jump_timer_id = nil

-- ========================================
-- Link Room Detection and Processing
-- ========================================

-- Check if a room is a link room and initiate jump capture
-- Called from map_core.lua after room processing
function f2t_map_process_link_room(room_id, flags)
    if not room_id or not roomExists(room_id) then
        return
    end

    if not flags or not f2t_has_value(flags, "link") then
        return
    end

    -- Check if we already have jump exits for this room
    local special_exits = getSpecialExits(room_id)
    local has_jump_exits = false

    for command, dest_id in pairs(special_exits) do
        if string.match(command, "^jump ") then
            has_jump_exits = true
            break
        end
    end

    if has_jump_exits then
        f2t_debug_log("[map] Link room %d already has jump exits", room_id)
        return
    end

    -- Get the system for this link room
    local system = getRoomUserData(room_id, "fed2_system")
    if not system then
        f2t_debug_log("[map] WARNING: Link room %d has no system data", room_id)
        return
    end

    f2t_debug_log("[map] Link room detected: %d in system %s - initiating jump capture", room_id, system)

    -- Start jump capture
    f2t_map_start_jump_capture(room_id, system)
end

-- ========================================
-- Jump Capture Functions
-- ========================================

-- Start capturing jump destinations
function f2t_map_start_jump_capture(room_id, source_system)
    -- Set expecting flag - will activate when we see headers
    F2T_MAP_JUMP_CAPTURE.expecting = true
    F2T_MAP_JUMP_CAPTURE.active = false
    F2T_MAP_JUMP_CAPTURE.room_id = room_id
    F2T_MAP_JUMP_CAPTURE.source_system = source_system
    F2T_MAP_JUMP_CAPTURE.destinations = {}
    F2T_MAP_JUMP_CAPTURE.in_output = false

    f2t_debug_log("[map] Expecting jump output for room %d (system: %s)", room_id, source_system)

    -- Send jump command (output will be captured when headers detected)
    send("jump", false)  -- false = don't echo to screen
end

-- Add a captured destination system
function f2t_map_add_jump_destination(system_name)
    if not F2T_MAP_JUMP_CAPTURE.active then
        return
    end

    table.insert(F2T_MAP_JUMP_CAPTURE.destinations, system_name)
    f2t_debug_log("[map] Captured jump destination: %s", system_name)
end

-- Finish capture and create special exits
function f2t_map_finish_jump_capture()
    if not F2T_MAP_JUMP_CAPTURE.active then
        return
    end

    local room_id = F2T_MAP_JUMP_CAPTURE.room_id
    local source_system = F2T_MAP_JUMP_CAPTURE.source_system
    local destinations = F2T_MAP_JUMP_CAPTURE.destinations

    f2t_debug_log("[map] Finishing jump capture: %d destinations found", #destinations)

    local created_count = 0
    for _, dest_system in ipairs(destinations) do
        if f2t_map_create_jump_special_exit(room_id, source_system, dest_system) then
            created_count = created_count + 1
        end
    end

    f2t_debug_log("[map] Created %d bidirectional jump exits for room %d", created_count, room_id)

    -- Reset state
    F2T_MAP_JUMP_CAPTURE.expecting = false
    F2T_MAP_JUMP_CAPTURE.active = false
    F2T_MAP_JUMP_CAPTURE.in_output = false
    F2T_MAP_JUMP_CAPTURE.room_id = nil
    F2T_MAP_JUMP_CAPTURE.source_system = nil
    F2T_MAP_JUMP_CAPTURE.destinations = {}
end

-- ========================================
-- Special Exit Creation
-- ========================================

-- Create bidirectional jump special exits between two link rooms
function f2t_map_create_jump_special_exit(from_room_id, from_system, to_system)
    -- Find link room in destination system
    local to_room_id = f2t_map_find_link_room_in_system(to_system)

    if not to_room_id then
        f2t_debug_log("[map] No link room found in system '%s' - skipping", to_system)
        return false
    end

    -- Create forward exit: from_room -> to_room
    local forward_command = string.format("jump %s", to_system)
    addSpecialExit(from_room_id, to_room_id, forward_command)
    f2t_debug_log("[map] Created jump exit: room %d -> room %d (%s)",
        from_room_id, to_room_id, forward_command)

    -- Create reverse exit: to_room -> from_room
    local reverse_command = string.format("jump %s", from_system)
    addSpecialExit(to_room_id, from_room_id, reverse_command)
    f2t_debug_log("[map] Created reverse jump exit: room %d -> room %d (%s)",
        to_room_id, from_room_id, reverse_command)

    return true
end

-- ========================================
-- Room Queries
-- ========================================

-- Find a link room in a specific system
function f2t_map_find_link_room_in_system(system)
    if not system or system == "" then
        return nil
    end

    local rooms = getRooms()
    for room_id, room_name in pairs(rooms) do
        local room_system = getRoomUserData(room_id, "fed2_system")
        local has_link_flag = getRoomUserData(room_id, "fed2_flag_link")

        if room_system == system and has_link_flag == "true" then
            return room_id
        end
    end

    return nil
end

-- ========================================
-- Timer Functions
-- ========================================

-- Start/reset the capture completion timer
function f2t_map_jump_reset_timer()
    -- Cancel existing timer
    if jump_timer_id then
        killTimer(jump_timer_id)
    end

    -- Start new timer - if no more lines arrive in 0.5s, we're done
    jump_timer_id = tempTimer(0.5, function()
        if F2T_MAP_JUMP_CAPTURE.active then
            f2t_debug_log("[map] Jump capture timeout - processing %d destinations", #F2T_MAP_JUMP_CAPTURE.destinations)
            f2t_map_finish_jump_capture()
        end
        jump_timer_id = nil
    end)
end

f2t_debug_log("[map] Jump exit management loaded")
