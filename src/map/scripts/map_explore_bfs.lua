-- BFS (Breadth-First Search) algorithm for finding rooms with specific flags
-- Used by system/cartel exploration to quickly find exchanges on planets

-- ========================================
-- BFS Flag Finder
-- ========================================

function f2t_map_explore_bfs_find_flag(starting_room_id, target_flag, max_depth)
    max_depth = max_depth or 20  -- Default depth limit to prevent infinite search

    f2t_debug_log("[map-explore-bfs] Starting BFS search for flag '%s' from room %d (max depth: %d)",
        target_flag, starting_room_id, max_depth)

    -- Queue for BFS (FIFO: first in, first out)
    local queue = {{room_id = starting_room_id, depth = 0}}

    -- Track visited rooms to prevent loops
    local visited = {[starting_room_id] = true}

    -- Statistics
    local rooms_checked = 0

    while #queue > 0 do
        -- Pop from FRONT of queue (BFS pattern)
        local current = table.remove(queue, 1)
        rooms_checked = rooms_checked + 1

        f2t_debug_log("[map-explore-bfs] Checking room %d (depth: %d, queue size: %d)",
            current.room_id, current.depth, #queue)

        -- Check depth limit
        if current.depth >= max_depth then
            f2t_debug_log("[map-explore-bfs] Reached max depth %d, stopping search", max_depth)
            break
        end

        -- Check if current room has target flag
        local flag_key = string.format("fed2_flag_%s", target_flag)
        local has_flag = getRoomUserData(current.room_id, flag_key)

        if has_flag == "true" then
            f2t_debug_log("[map-explore-bfs] Found flag '%s' at room %d (depth: %d, rooms checked: %d)",
                target_flag, current.room_id, current.depth, rooms_checked)
            return current.room_id  -- Success!
        end

        -- Get stub exits from current room
        local stubs = getExitStubs(current.room_id)

        if stubs then
            -- Add unvisited stub exits to queue (back of queue for BFS)
            for _, stub_dir_num in pairs(stubs) do
                local direction = f2t_map_explore_direction_number_to_name(stub_dir_num)

                if direction and f2t_map_explore_is_exit_valid(current.room_id, direction) then
                    -- Check if exit has a connected destination
                    local dest_id = f2t_map_explore_get_exit_destination(current.room_id, direction)

                    if dest_id and not visited[dest_id] then
                        visited[dest_id] = true
                        table.insert(queue, {
                            room_id = dest_id,
                            depth = current.depth + 1
                        })

                        f2t_debug_log("[map-explore-bfs] Added room %d to queue (direction: %s, depth: %d)",
                            dest_id, direction, current.depth + 1)
                    end
                end
            end
        end
    end

    -- Not found within depth limit
    f2t_debug_log("[map-explore-bfs] Flag '%s' not found within depth %d (rooms checked: %d)",
        target_flag, max_depth, rooms_checked)
    return nil
end

f2t_debug_log("[map] Loaded map_explore_bfs.lua")
