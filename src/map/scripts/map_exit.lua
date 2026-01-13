-- Exit handling for Federation 2 mapper
-- Manages standard exits, special exits, and stub exits

-- ========================================
-- Helper Functions
-- ========================================

-- Direction expansion map (Mudlet expands abbreviations: w -> west)
local DIR_EXPANSION_MAP = {
    n = "north", s = "south", e = "east", w = "west",
    ne = "northeast", nw = "northwest", se = "southeast", sw = "southwest",
    u = "up", d = "down"
}

-- Check if a room has an exit in the given direction (checks both abbreviated and expanded forms)
-- Returns: destination room_id or nil
local function get_existing_exit(room_id, direction)
    local exits = getRoomExits(room_id)
    local existing = exits[direction]

    if not existing then
        local expanded = DIR_EXPANSION_MAP[direction]
        if expanded then
            existing = exits[expanded]
        end
    end

    return existing
end

-- Check if a room has a stub exit in the given direction
-- Returns: true if stub exists, false otherwise
local function has_stub_in_direction(room_id, direction)
    local stubs = getExitStubs(room_id)
    local direction_num = f2t_map_direction_to_number(direction)

    -- Use pairs() not ipairs() - getExitStubs() returns 0-indexed table
    for _, stub_dir_num in pairs(stubs) do
        if stub_dir_num == direction_num then
            return true
        end
    end

    return false
end

-- ========================================
-- Standard Exit Processing
-- ========================================

-- Process exits from GMCP data and create/update them
-- gmcp_exits: table of {direction = fed2_room_num}
-- current_room_id: Mudlet room ID of current room
function f2t_map_process_exits(current_room_id, gmcp_exits, gmcp_room_data)
    if not current_room_id or not roomExists(current_room_id) then
        f2t_debug_log("[map] ERROR: Cannot process exits for invalid room: %s",
            tostring(current_room_id))
        return
    end

    if not gmcp_exits then
        f2t_debug_log("[map] No exits to process for room %d", current_room_id)
        return
    end

    -- Get current exits to detect removals
    local current_exits = getRoomExits(current_room_id)

    -- Track which directions we've seen
    local seen_directions = {}

    -- Process each exit from GMCP
    for direction, fed2_num in pairs(gmcp_exits) do
        seen_directions[direction] = true

        -- Generate hash for destination room
        local dest_hash = string.format("%s.%s.%d",
            gmcp_room_data.system, gmcp_room_data.area, fed2_num)

        -- Check if destination room exists
        local dest_room_id = f2t_map_get_room_by_hash(dest_hash)

        if dest_room_id then
            -- Destination exists - check for existing exit
            local existing_exit = get_existing_exit(current_room_id, direction)

            f2t_debug_log("[map]   existing_exit[%s] = %s, dest_room_id = %d",
                direction, tostring(existing_exit), dest_room_id)

            if existing_exit ~= dest_room_id then
                -- FIRST: Check if destination room should have an exit pointing back to us
                -- Check both stub exits and stored GMCP exit data
                local opposite_dir = f2t_map_get_opposite_direction(direction)
                f2t_debug_log("[map]   Checking for reverse connection: opposite_dir=%s",
                    tostring(opposite_dir))

                if opposite_dir then
                    -- Check if destination already has a real exit pointing back
                    local dest_existing_exit = get_existing_exit(dest_room_id, opposite_dir)

                    if not dest_existing_exit or dest_existing_exit ~= current_room_id then
                        -- No exit back to us yet, check if one should exist
                        -- First check for stub exit
                        local dest_has_stub = has_stub_in_direction(dest_room_id, opposite_dir)
                        f2t_debug_log("[map]   Destination room %d has stub in direction %s: %s",
                            dest_room_id, opposite_dir, tostring(dest_has_stub))

                        -- Also check stored GMCP exit data
                        local dest_should_have_exit = false
                        local dest_exits_data = getRoomUserData(dest_room_id, "fed2_exits")
                        if dest_exits_data then
                            local our_fed2_num = gmcp_room_data.num
                            for dir_num_pair in string.gmatch(dest_exits_data, "[^,]+") do
                                local dir, num = string.match(dir_num_pair, "([^:]+):(%d+)")
                                if dir == opposite_dir and num and tonumber(num) == our_fed2_num then
                                    dest_should_have_exit = true
                                    f2t_debug_log("[map]   Destination GMCP data indicates exit %s -> %d",
                                        dir, our_fed2_num)
                                    break
                                end
                            end
                        end

                        f2t_debug_log("[map]   dest_has_stub=%s, dest_should_have_exit=%s",
                            tostring(dest_has_stub), tostring(dest_should_have_exit))

                        if dest_has_stub then
                            -- Remove the stub and create a real exit
                            local opposite_dir_num = f2t_map_direction_to_number(opposite_dir)
                            setExitStub(dest_room_id, opposite_dir_num, false)
                            setExit(dest_room_id, current_room_id, opposite_dir_num)
                            f2t_debug_log("[map] Connected reverse stub: room %d -> room %d (%s)",
                                dest_room_id, current_room_id, opposite_dir)
                        elseif dest_should_have_exit then
                            -- Create exit based on GMCP data (no stub to remove)
                            local opposite_dir_num = f2t_map_direction_to_number(opposite_dir)
                            f2t_debug_log("[map]   setExit(%d, %d, %d) -- %s: room %d -> room %d",
                                dest_room_id, current_room_id, opposite_dir_num,
                                opposite_dir, dest_room_id, current_room_id)
                            setExit(dest_room_id, current_room_id, opposite_dir_num)
                            f2t_debug_log("[map] Created reverse exit from GMCP data: room %d -> room %d (%s)",
                                dest_room_id, current_room_id, opposite_dir)
                        end
                    end
                end

                -- THEN: Create or convert our own exit
                local dir_num = f2t_map_direction_to_number(direction)
                if has_stub_in_direction(current_room_id, direction) then
                    -- Convert stub to real exit
                    -- connectExitStub only works for two-way exits (requires opposite stub)
                    -- Fall back to setExit + clear stub for one-way exits
                    local success = connectExitStub(current_room_id, dir_num, dest_room_id)
                    if not success then
                        setExit(current_room_id, dest_room_id, dir_num)
                        setExitStub(current_room_id, dir_num, false)
                    end
                    f2t_debug_log("[map] Converted stub to exit: room %d -> room %d (%s)",
                        current_room_id, dest_room_id, direction)
                else
                    -- Create new exit
                    f2t_debug_log("[map]   setExit(%d, %d, %d) -- %s: room %d -> room %d",
                        current_room_id, dest_room_id, dir_num,
                        direction, current_room_id, dest_room_id)
                    setExit(current_room_id, dest_room_id, dir_num)
                    f2t_debug_log("[map] Exit created: room %d -> room %d (%s)",
                        current_room_id, dest_room_id, direction)
                end
            end
        else
            -- Destination doesn't exist yet, create stub if not already present
            if not has_stub_in_direction(current_room_id, direction) then
                local dir_num = f2t_map_direction_to_number(direction)
                setExitStub(current_room_id, dir_num, true)
                f2t_debug_log("[map] Stub exit created: room %d (%s / %d) -> %s",
                    current_room_id, direction, dir_num, dest_hash)
            end
        end
    end

    -- Remove exits that are no longer in GMCP data
    -- Normalize directions since Mudlet may expand abbreviations (sw -> southwest)
    for direction, dest_id in pairs(current_exits) do
        local normalized_dir = f2t_map_normalize_direction(direction)
        local in_original = seen_directions[direction]
        local in_normalized = seen_directions[normalized_dir]

        f2t_debug_log("[map]   Checking exit %s (normalized: %s) - in_original=%s, in_normalized=%s",
            direction, normalized_dir, tostring(in_original), tostring(in_normalized))

        if not in_original and not in_normalized then
            local dir_num = f2t_map_direction_to_number(direction)
            setExit(current_room_id, -1, dir_num)
            f2t_debug_log("[map] Exit removed: room %d (%s / %d) - no longer in GMCP",
                current_room_id, direction, dir_num)
        end
    end
end

-- ========================================
-- Stub Exit Resolution
-- ========================================

-- Try to connect stub exits when entering a room from a known direction
-- prev_room_id: Mudlet ID of room we came from
-- current_room_id: Mudlet ID of room we're entering
-- direction: Direction we moved (e.g., "n", "ne", "in")
function f2t_map_resolve_stub_exit(prev_room_id, current_room_id, direction)
    if not prev_room_id or not current_room_id or not direction then
        return
    end

    if not roomExists(prev_room_id) or not roomExists(current_room_id) then
        return
    end

    -- Convert direction to number for comparison
    local dir_num = f2t_map_direction_to_number(direction)
    if not dir_num then
        f2t_debug_log("[map] ERROR: Unknown direction: %s", direction)
        return
    end

    -- Check if previous room has a stub in this direction
    local stubs = getExitStubs(prev_room_id)
    if not stubs then
        -- No stubs at all
        return
    end

    local has_stub = false
    -- IMPORTANT: getExitStubs() uses 0-based indexing, must use pairs() not ipairs()
    for _, stub_dir_num in pairs(stubs) do
        if stub_dir_num == dir_num then
            has_stub = true
            break
        end
    end

    if not has_stub then
        -- No stub to resolve
        f2t_debug_log("[map] No stub to resolve: room %d direction %s (%d)", prev_room_id, direction, dir_num)
        return
    end

    -- Connect the stub
    setExit(prev_room_id, current_room_id, dir_num)
    setExitStub(prev_room_id, dir_num, false)

    f2t_debug_log("[map] Stub resolved: room %d -> room %d (%s / %d)",
        prev_room_id, current_room_id, direction, dir_num)
end

-- Connect any stubs in the area that should point to a newly created/updated room
-- This handles one-way exits where the reverse connection doesn't trigger stub conversion
-- room_id: Mudlet room ID of the new/updated room
-- fed2_num: Federation 2 room number (from GMCP)
function f2t_map_connect_incoming_stubs(room_id, fed2_num)
    if not room_id or not fed2_num then
        return
    end

    local area_id = getRoomArea(room_id)
    if not area_id then
        return
    end

    local area_rooms = getAreaRooms(area_id)
    if not area_rooms then
        return
    end

    local fed2_num_str = tostring(fed2_num)

    -- IMPORTANT: getAreaRooms() returns 0-indexed table, must use pairs() not ipairs()
    for _, other_room_id in pairs(area_rooms) do
        if other_room_id ~= room_id then
            -- Check if this room has any stubs
            -- IMPORTANT: getExitStubs() returns 0-indexed table, use next() to check non-empty
            local stubs = getExitStubs(other_room_id)
            if stubs and next(stubs) ~= nil then
                -- Get the room's stored GMCP exit data
                local exits_data = getRoomUserData(other_room_id, "fed2_exits")
                if exits_data and exits_data ~= "" then
                    -- Parse exits data: "e:393,nw:328,sw:456"
                    for dir_num_pair in string.gmatch(exits_data, "[^,]+") do
                        local dir, num = string.match(dir_num_pair, "([^:]+):(%d+)")
                        if dir and num == fed2_num_str then
                            -- This exit should connect to our room
                            -- Check if there's actually a stub in this direction
                            local dir_num = f2t_map_direction_to_number(dir)
                            if dir_num then
                                local has_stub = false
                                for _, stub_dir in pairs(stubs) do
                                    if stub_dir == dir_num then
                                        has_stub = true
                                        break
                                    end
                                end

                                if has_stub then
                                    -- Connect the stub
                                    setExit(other_room_id, room_id, dir_num)
                                    setExitStub(other_room_id, dir_num, false)
                                    f2t_debug_log("[map] Connected incoming stub: room %d -> room %d (%s)",
                                        other_room_id, room_id, dir)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ========================================
-- Special Exit Processing
-- ========================================

-- Process special exits (like "board" command)
-- current_room_id: Mudlet room ID
-- gmcp_room_data: Full GMCP room data
function f2t_map_process_special_exits(current_room_id, gmcp_room_data)
    if not current_room_id or not roomExists(current_room_id) then
        return
    end

    if not gmcp_room_data then
        return
    end

    -- Handle jump exits for link rooms
    if gmcp_room_data.flags then
        f2t_map_process_link_room(current_room_id, gmcp_room_data.flags)
    end

    -- Handle "board/orbit" special exit for orbit/shuttlepad rooms
    if gmcp_room_data.board or gmcp_room_data.orbit then
        -- board field contains the hash of the destination room
        local board_hash = gmcp_room_data.board or gmcp_room_data.orbit
        local dest_room_id = f2t_map_get_room_by_hash(board_hash)

        if not dest_room_id then
            -- Destination doesn't exist yet - create it from the hash
            -- Parse hash format: system.area.num
            local parts = {}
            for part in string.gmatch(board_hash, "[^.]+") do
                table.insert(parts, part)
            end

            if #parts == 3 then
                local dest_system = parts[1]
                local dest_area = parts[2]
                local dest_num = tonumber(parts[3])

                if dest_system and dest_area and dest_num then
                    -- Create minimal room data for the board destination
                    local dest_data = {
                        system = dest_system,
                        area = dest_area,
                        num = dest_num,
                        name = string.format("%s (via board)", dest_area),
                        flags = {}
                    }

                    -- Get or create the destination area
                    local dest_area_id = f2t_map_get_or_create_area(dest_area, {
                        system = dest_system
                    })

                    if dest_area_id then
                        -- Create the destination room
                        dest_room_id = f2t_map_create_room(dest_data, dest_area_id)

                        if dest_room_id then
                            -- Set coordinates for the destination room
                            local x, y, z = f2t_map_calculate_coords_from_room_num(dest_num)
                            f2t_map_set_room_coords(dest_room_id, x, y, z)

                            -- Restore map focus to current room (creating stub can shift map UI)
                            centerview(current_room_id)

                            f2t_debug_log("[map] Created board destination: %s -> room %d",
                                board_hash, dest_room_id)
                        end
                    end
                end
            end
        end

        if dest_room_id then
            -- Remove any existing "board" special exit first
            removeSpecialExit(current_room_id, "board")

            -- Add special exit
            addSpecialExit(current_room_id, dest_room_id, "board")
            f2t_debug_log("[map] Special exit 'board': room %d -> room %d (%s)",
                current_room_id, dest_room_id, board_hash)
        else
            f2t_debug_log("[map] WARNING: Failed to create board destination: %s", board_hash)
        end
    end
end

-- ========================================
-- Exit Utilities
-- ========================================

-- Check if a room has any exits in a given direction
-- Returns: room_id of destination or nil
function f2t_map_get_exit(room_id, direction)
    if not room_id or not roomExists(room_id) then
        return nil
    end

    local exits = getRoomExits(room_id)
    return exits[direction]
end
