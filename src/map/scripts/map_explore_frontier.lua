-- Map exploration frontier management (DFS stack)
-- Handles adding unexplored exits to frontier and validating exits

-- ========================================
-- Direction Conversion Utilities
-- ========================================

-- Map direction numbers to Fed2 command abbreviations
-- Fed2 expects short forms (ne, nw, se, sw) not full names
local DIRECTION_COMMANDS = {
    [1] = "n",      -- north
    [2] = "ne",     -- northeast
    [3] = "nw",     -- northwest
    [4] = "e",      -- east
    [5] = "w",      -- west
    [6] = "s",      -- south
    [7] = "se",     -- southeast
    [8] = "sw",     -- southwest
    [9] = "u",      -- up
    [10] = "d",     -- down
    [11] = "in",    -- in
    [12] = "out"    -- out
}

function f2t_map_explore_direction_number_to_name(dir_num)
    return DIRECTION_COMMANDS[dir_num]
end

-- ========================================
-- Exit Validation
-- ========================================

function f2t_map_explore_is_exit_valid(room_id, direction)
    f2t_debug_log("[map-explore] Validating exit: room=%d, direction=%s", room_id, direction)

    -- Check if exit itself is locked
    if hasExitLock(room_id, direction) then
        f2t_debug_log("[map-explore] Exit INVALID: locked (room=%d, direction=%s)", room_id, direction)
        return false
    end

    -- Get destination room (if exit is already connected)
    local exits = getRoomExits(room_id)
    if not exits then
        f2t_debug_log("[map-explore] Exit VALID: no exits data, stub exit (room=%d, direction=%s)", room_id, direction)
        return true  -- No exits data, assume valid (stub exit)
    end

    local dest_id = exits[direction]
    if not dest_id then
        f2t_debug_log("[map-explore] Exit VALID: no destination, stub exit (room=%d, direction=%s)", room_id, direction)
        return true  -- No destination yet (stub exit)
    end

    f2t_debug_log("[map-explore] Exit connected: room=%d, direction=%s -> dest=%d", room_id, direction, dest_id)

    -- Check if destination room is locked
    if roomLocked(dest_id) then
        f2t_debug_log("[map-explore] Exit INVALID: destination locked (room=%d, dest=%d)", room_id, dest_id)
        return false
    end

    -- Check if destination already visited
    if F2T_MAP_EXPLORE_STATE.visited_rooms[dest_id] then
        f2t_debug_log("[map-explore] Exit INVALID: destination already visited (room=%d, dest=%d)", room_id, dest_id)
        return false
    end

    f2t_debug_log("[map-explore] Exit VALID: connected but unvisited (room=%d, direction=%s -> dest=%d)", room_id, direction, dest_id)
    return true
end

-- ========================================
-- Add Room's Stubs to Frontier
-- ========================================

function f2t_map_explore_add_room_to_frontier(room_id)
    -- Get stub exits (unexplored directions)
    local stubs = getExitStubs(room_id)

    if not stubs then
        f2t_debug_log("[map-explore] No stub exits in room %d", room_id)
        return 0
    end

    local added_count = 0

    -- IMPORTANT: Mudlet's getExitStubs() uses 0-based indexing
    -- Use pairs() instead of ipairs() to iterate all indices including 0
    for _, stub_dir_num in pairs(stubs) do
        local direction = f2t_map_explore_direction_number_to_name(stub_dir_num)

        if direction then
            -- Validate exit
            if f2t_map_explore_is_exit_valid(room_id, direction) then
                -- Push onto frontier stack (DFS: last in, first out)
                table.insert(F2T_MAP_EXPLORE_STATE.frontier_stack, {
                    room_id = room_id,
                    direction = direction
                })

                added_count = added_count + 1

                f2t_debug_log("[map-explore] Added to frontier: room=%d, direction=%s (stub_dir=%d, stack size=%d)",
                    room_id, direction, stub_dir_num, #F2T_MAP_EXPLORE_STATE.frontier_stack)
            end
        else
            f2t_debug_log("[map-explore] Unknown stub direction number: %d", stub_dir_num)
        end
    end

    if added_count > 0 then
        f2t_debug_log("[map-explore] Added %d exits to frontier from room %d", added_count, room_id)
    else
        f2t_debug_log("[map-explore] No valid stub exits in room %d", room_id)
    end

    return added_count
end

-- ========================================
-- Remove Room from Frontier
-- ========================================

function f2t_map_explore_remove_from_frontier(room_id)
    local new_frontier = {}
    local removed_count = 0

    for _, exit in ipairs(F2T_MAP_EXPLORE_STATE.frontier_stack) do
        if exit.room_id == room_id then
            removed_count = removed_count + 1
        else
            table.insert(new_frontier, exit)
        end
    end

    F2T_MAP_EXPLORE_STATE.frontier_stack = new_frontier

    if removed_count > 0 then
        f2t_debug_log("[map-explore] Removed %d exits from frontier for room %d", removed_count, room_id)
    end

    return removed_count
end

-- ========================================
-- Get Frontier Destination (if connected)
-- ========================================

function f2t_map_explore_get_exit_destination(room_id, direction)
    local exits = getRoomExits(room_id)
    if not exits then
        return nil
    end

    return exits[direction]
end

-- ========================================
-- Check if Frontier is Empty
-- ========================================

function f2t_map_explore_has_frontier()
    return #F2T_MAP_EXPLORE_STATE.frontier_stack > 0
end

-- ========================================
-- Pop Next Exit from Frontier (DFS)
-- ========================================

function f2t_map_explore_pop_frontier()
    if #F2T_MAP_EXPLORE_STATE.frontier_stack == 0 then
        return nil
    end

    -- Pop from end (DFS: last in, first out)
    local exit = table.remove(F2T_MAP_EXPLORE_STATE.frontier_stack)

    f2t_debug_log("[map-explore] Popped from frontier: room=%d, direction=%s (remaining=%d)",
        exit.room_id, exit.direction, #F2T_MAP_EXPLORE_STATE.frontier_stack)

    return exit
end

-- ========================================
-- Get Frontier Size
-- ========================================

function f2t_map_explore_frontier_size()
    return #F2T_MAP_EXPLORE_STATE.frontier_stack
end

-- ========================================
-- Recompute Entire Frontier
-- ========================================
-- Scans all rooms in area for remaining stub exits
-- Filters and sorts by distance from reference room
-- Rebuilds frontier from scratch

function f2t_map_explore_recompute_frontier()
    local area_id = F2T_MAP_EXPLORE_STATE.starting_area_id
    local current_room = F2T_MAP_CURRENT_ROOM_ID

    if not area_id or not current_room then
        f2t_debug_log("[map-explore] Cannot recompute frontier: missing area_id or current_room")
        return
    end

    -- Determine reference room for distance calculation
    -- Brief mode: distance from shuttlepad (creates concentric circles)
    -- Full mode: distance from current room (natural DFS progression)
    local is_brief = F2T_MAP_EXPLORE_STATE.brief_flags_remaining_count ~= nil
    local reference_room = is_brief and F2T_MAP_EXPLORE_STATE.starting_room_id or current_room

    f2t_debug_log("[map-explore] Recomputing frontier for area %d (reference: %d, mode: %s)",
        area_id, reference_room, is_brief and "brief" or "full")

    local candidates = {}
    local rooms_in_area = getAreaRooms(area_id)

    if not rooms_in_area then
        f2t_debug_log("[map-explore] No rooms found in area %d", area_id)
        F2T_MAP_EXPLORE_STATE.frontier_stack = {}
        return
    end

    -- Scan all rooms for remaining stubs
    for _, room_id in pairs(rooms_in_area) do  -- pairs() for 0-indexed tables
        local stubs = getExitStubs(room_id)

        if stubs then
            for stub_index, stub_dir_num in pairs(stubs) do
                local direction = f2t_map_explore_direction_number_to_name(stub_dir_num)

                f2t_debug_log("[map-explore] Room %d: stub[%s] = %s (%s)",
                    room_id, tostring(stub_index), tostring(stub_dir_num), tostring(direction))

                if not direction then
                    f2t_debug_log("[map-explore] Skipped stub[%s]: unknown direction number %s", tostring(stub_index), tostring(stub_dir_num))
                elseif not f2t_map_explore_is_exit_valid(room_id, direction) then
                    f2t_debug_log("[map-explore] Skipped stub[%s]: exit not valid (locked or visited)", tostring(stub_index))
                else
                    -- Still a stub = unvisited destination
                    -- (visited destinations would have connected the stub automatically)
                    local success, weight = getPath(reference_room, room_id)
                    if success then
                        table.insert(candidates, {
                            room_id = room_id,
                            direction = direction,
                            distance = weight
                        })
                        f2t_debug_log("[map-explore] Added stub[%s] to candidates (distance: %d)", tostring(stub_index), weight)
                    else
                        f2t_debug_log("[map-explore] Skipped stub[%s]: no path from reference room %d to room %d",
                            tostring(stub_index), reference_room, room_id)
                    end
                end
            end
        end
    end

    -- Sort by distance (closest first)
    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    -- Apply direction priority for exchange discovery at shuttlepad
    -- Exchange is typically e or n from shuttlepad - prioritize these directions
    -- reference_room is starting_room_id in brief mode (concentric circles from shuttlepad)
    if is_brief and reference_room == F2T_MAP_EXPLORE_STATE.starting_room_id then
        -- Check if we're looking for exchange flag
        local seeking_exchange = F2T_MAP_EXPLORE_STATE.brief_flags_set and
                                 F2T_MAP_EXPLORE_STATE.brief_flags_set["exchange"]

        if seeking_exchange and #candidates > 0 then
            f2t_debug_log("[map-explore] Applying exchange direction priority (e > n > w > s)")

            -- Group by direction, preserving distance order within each group
            local direction_priority = {"e", "n", "sw", "w", "s", "ne", "nw", "se", "in", "u", "d", "out"}
            local grouped = {}

            -- Initialize groups
            for _, dir in ipairs(direction_priority) do
                grouped[dir] = {}
            end

            -- Group candidates by direction (already sorted by distance)
            for _, candidate in ipairs(candidates) do
                local dir = candidate.direction
                if grouped[dir] then
                    table.insert(grouped[dir], candidate)
                else
                    -- Unknown direction, add to end
                    if not grouped["other"] then grouped["other"] = {} end
                    table.insert(grouped["other"], candidate)
                end
            end

            -- Rebuild candidates in priority order
            candidates = {}
            for _, dir in ipairs(direction_priority) do
                for _, candidate in ipairs(grouped[dir]) do
                    table.insert(candidates, candidate)
                end
            end

            -- Add any "other" directions at the end
            if grouped["other"] then
                for _, candidate in ipairs(grouped["other"]) do
                    table.insert(candidates, candidate)
                end
            end

            f2t_debug_log("[map-explore] Direction priority applied, frontier order:")
            for i = 1, math.min(5, #candidates) do
                f2t_debug_log("  %d. room=%d, direction=%s, distance=%d",
                    i, candidates[i].room_id, candidates[i].direction, candidates[i].distance)
            end
        end
    end

    -- Rebuild frontier
    F2T_MAP_EXPLORE_STATE.frontier_stack = {}
    for i = 1, #candidates do
        table.insert(F2T_MAP_EXPLORE_STATE.frontier_stack, {
            room_id = candidates[i].room_id,
            direction = candidates[i].direction
        })
    end

    f2t_debug_log("[map-explore] Frontier recomputed: %d stub(s) remaining",
        #F2T_MAP_EXPLORE_STATE.frontier_stack)
end

f2t_debug_log("[map] Loaded map_explore_frontier.lua")
