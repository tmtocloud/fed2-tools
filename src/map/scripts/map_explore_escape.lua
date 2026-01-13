-- Map exploration escape logic
-- Handles escaping from unmapped rooms by walking GMCP exits until navigation works

-- ========================================
-- Start Escape Procedure
-- ========================================

-- Attempt to escape from current room to reach a destination
-- If direct navigation fails, walks GMCP exits until navigation becomes possible
--
-- Parameters:
--   destination_room_id: Room ID to reach after escaping
--   on_success: Callback when destination is reached (or navigation works)
--   on_failure: Callback when escape fails after max attempts
--
-- Returns: true if escape started, false if not needed (navigation already works)
function f2t_map_explore_escape_start(destination_room_id, on_success, on_failure)
    -- Guard: Check exploration is active
    if not F2T_MAP_EXPLORE_STATE.active then
        f2t_debug_log("[map-explore-escape] Cannot start escape: exploration not active")
        if on_failure then on_failure("Exploration not active") end
        return false
    end

    -- Guard: Check if escape already in progress (prevent nested escapes)
    if F2T_MAP_EXPLORE_STATE.escape_state then
        f2t_debug_log("[map-explore-escape] Escape already in progress, ignoring nested escape request")
        if on_failure then on_failure("Escape already in progress") end
        return false
    end

    local current_room = F2T_MAP_CURRENT_ROOM_ID
    if not current_room then
        f2t_debug_log("[map-explore-escape] Cannot start escape: current room unknown")
        if on_failure then on_failure("Current room unknown") end
        return false
    end

    -- Check if already at destination
    if current_room == destination_room_id then
        f2t_debug_log("[map-explore-escape] Already at destination %d", destination_room_id)
        if on_success then on_success() end
        return true
    end

    -- First, try normal navigation
    f2t_debug_log("[map-explore-escape] Trying direct navigation to %d", destination_room_id)
    if f2t_map_navigate(tostring(destination_room_id)) then
        -- Navigation started successfully
        f2t_debug_log("[map-explore-escape] Direct navigation started")
        -- Set up state to call on_success when we arrive
        F2T_MAP_EXPLORE_STATE.escape_state = {
            destination_room_id = destination_room_id,
            on_success = on_success,
            on_failure = on_failure,
            phase = "navigating_to_destination"
        }
        F2T_MAP_EXPLORE_STATE.phase = "brief_escaping"
        return true
    end

    -- Navigation failed - we're stranded, need to escape
    f2t_debug_log("[map-explore-escape] Direct navigation failed, starting escape procedure")
    cecho("\n<yellow>[map-explore]<reset> Cannot navigate from current room, attempting to escape...\n")

    -- Get GMCP exits for current room
    local gmcp_exits = gmcp.room and gmcp.room.info and gmcp.room.info.exits
    if not gmcp_exits or next(gmcp_exits) == nil then
        f2t_debug_log("[map-explore-escape] No GMCP exits available")
        cecho("\n<red>[map-explore]<reset> No exits available from current room\n")
        if on_failure then on_failure("No exits available") end
        return false
    end

    -- Build list of exits to try
    local exits_to_try = {}
    for dir, _ in pairs(gmcp_exits) do
        table.insert(exits_to_try, dir)
    end

    f2t_debug_log("[map-explore-escape] Found %d exits to try: %s",
        #exits_to_try, table.concat(exits_to_try, ", "))

    -- Initialize escape state
    F2T_MAP_EXPLORE_STATE.escape_state = {
        destination_room_id = destination_room_id,
        on_success = on_success,
        on_failure = on_failure,
        exits_to_try = exits_to_try,
        attempts = 0,
        max_attempts = 10,  -- Limit to prevent infinite loops
        starting_room_id = current_room,
        phase = "walking_exits"
    }
    F2T_MAP_EXPLORE_STATE.phase = "brief_escaping"

    -- Try first exit
    f2t_map_explore_escape_try_next_exit()
    return true
end

-- ========================================
-- Try Next Exit
-- ========================================

function f2t_map_explore_escape_try_next_exit()
    local escape = F2T_MAP_EXPLORE_STATE.escape_state
    if not escape then
        f2t_debug_log("[map-explore-escape] No escape state, aborting")
        return
    end

    escape.attempts = escape.attempts + 1

    -- Check if we've exceeded max attempts
    if escape.attempts > escape.max_attempts then
        f2t_debug_log("[map-explore-escape] Max attempts (%d) exceeded", escape.max_attempts)
        f2t_map_explore_escape_fail("Max escape attempts exceeded")
        return
    end

    -- Check if we have exits to try
    if #escape.exits_to_try == 0 then
        -- No more exits from original room - try exits from current room
        local gmcp_exits = gmcp.room and gmcp.room.info and gmcp.room.info.exits
        if gmcp_exits then
            for dir, _ in pairs(gmcp_exits) do
                table.insert(escape.exits_to_try, dir)
            end
            f2t_debug_log("[map-explore-escape] Added %d exits from current room", #escape.exits_to_try)
        end

        if #escape.exits_to_try == 0 then
            f2t_debug_log("[map-explore-escape] No more exits to try")
            f2t_map_explore_escape_fail("No exits available")
            return
        end
    end

    -- Pop next exit to try
    local direction = table.remove(escape.exits_to_try, 1)
    f2t_debug_log("[map-explore-escape] Attempt %d: walking %s", escape.attempts, direction)

    cecho(string.format("  <dim_grey>Trying exit: %s<reset>\n", direction))

    -- Walk that exit using speedwalk pattern for timeout protection
    speedWalkDir = {direction}
    speedWalkPath = {nil}  -- Blind movement
    doSpeedWalk()

    -- Room change handler will pick up from here
end

-- ========================================
-- Handle Room Change During Escape
-- ========================================

function f2t_map_explore_escape_on_room_change()
    local escape = F2T_MAP_EXPLORE_STATE.escape_state
    if not escape then
        return false
    end

    local current_room = F2T_MAP_CURRENT_ROOM_ID
    f2t_debug_log("[map-explore-escape] Room change during escape: now at %d", current_room or 0)

    -- Check if we arrived at destination
    if current_room == escape.destination_room_id then
        f2t_debug_log("[map-explore-escape] Arrived at destination!")
        f2t_map_explore_escape_success()
        return true
    end

    -- Check if navigating to destination (after successful escape navigation)
    if escape.phase == "navigating_to_destination" then
        -- We were navigating, check if we arrived
        -- (Speedwalk handles the actual path following)
        -- This will be called when speedwalk completes
        return true
    end

    -- We moved to a new room - try navigation again
    f2t_debug_log("[map-explore-escape] Trying navigation from new room %d", current_room or 0)

    if f2t_map_navigate(tostring(escape.destination_room_id)) then
        -- Navigation now works! We've escaped
        f2t_debug_log("[map-explore-escape] Navigation now works, heading to destination")
        cecho("\n<green>[map-explore]<reset> Found path! Navigating to destination...\n")
        escape.phase = "navigating_to_destination"
        return true
    end

    -- Navigation still doesn't work - try next exit
    f2t_debug_log("[map-explore-escape] Navigation still fails, trying next exit")

    -- Small delay before trying next exit
    tempTimer(0.3, function()
        if F2T_MAP_EXPLORE_STATE.active and F2T_MAP_EXPLORE_STATE.escape_state then
            f2t_map_explore_escape_try_next_exit()
        end
    end)

    return true
end

-- ========================================
-- Handle Speedwalk Completion During Escape
-- ========================================

function f2t_map_explore_escape_on_speedwalk_complete(result)
    local escape = F2T_MAP_EXPLORE_STATE.escape_state
    if not escape then
        return false
    end

    f2t_debug_log("[map-explore-escape] Speedwalk completed with result: %s", result)

    if result == "completed" then
        -- Check if we're at destination
        local current_room = F2T_MAP_CURRENT_ROOM_ID
        if current_room == escape.destination_room_id then
            f2t_map_explore_escape_success()
            return true
        end

        -- We moved to a new room - try navigation again
        f2t_debug_log("[map-explore-escape] Trying navigation from new room %d", current_room or 0)

        if f2t_map_navigate(tostring(escape.destination_room_id)) then
            -- Navigation now works! We've escaped
            f2t_debug_log("[map-explore-escape] Navigation now works, heading to destination")
            cecho("\n<green>[map-explore]<reset> Found path! Navigating to destination...\n")
            escape.phase = "navigating_to_destination"
            return true
        end

        -- Navigation still doesn't work - try next exit
        f2t_debug_log("[map-explore-escape] Navigation still fails, trying next exit")
        tempTimer(0.3, function()
            if F2T_MAP_EXPLORE_STATE.active and F2T_MAP_EXPLORE_STATE.escape_state then
                f2t_map_explore_escape_try_next_exit()
            end
        end)
        return true

    elseif result == "failed" then
        -- Speedwalk failed - try next exit
        f2t_debug_log("[map-explore-escape] Speedwalk failed, trying next exit")
        tempTimer(0.3, function()
            if F2T_MAP_EXPLORE_STATE.active and F2T_MAP_EXPLORE_STATE.escape_state then
                f2t_map_explore_escape_try_next_exit()
            end
        end)
        return true

    elseif result == "stopped" then
        -- User stopped - abort escape
        f2t_debug_log("[map-explore-escape] Speedwalk stopped by user")
        f2t_map_explore_escape_fail("Stopped by user")
        return true
    end

    return false
end

-- ========================================
-- Escape Success
-- ========================================

function f2t_map_explore_escape_success()
    local escape = F2T_MAP_EXPLORE_STATE.escape_state
    if not escape then return end

    local dest_name = getRoomName(escape.destination_room_id) or "destination"
    f2t_debug_log("[map-explore-escape] Escape successful! Arrived at %s", dest_name)
    -- Message conveys exploration context rather than duplicating [map] arrival message
    cecho("\n<green>[map-explore]<reset> Escaped successfully, resuming exploration...\n")

    local on_success = escape.on_success

    -- Clear escape state (don't reset phase - callback handles its own phase management)
    F2T_MAP_EXPLORE_STATE.escape_state = nil

    -- Call success callback
    if on_success then
        tempTimer(0.5, function()
            if F2T_MAP_EXPLORE_STATE.active then
                on_success()
            end
        end)
    end
end

-- ========================================
-- Escape Failure
-- ========================================

function f2t_map_explore_escape_fail(reason)
    local escape = F2T_MAP_EXPLORE_STATE.escape_state
    if not escape then return end

    f2t_debug_log("[map-explore-escape] Escape failed: %s", reason)

    local on_failure = escape.on_failure
    local destination_room_id = escape.destination_room_id

    -- Clear escape state
    F2T_MAP_EXPLORE_STATE.escape_state = nil

    -- Call failure callback or pause exploration
    if on_failure then
        on_failure(reason)
    else
        -- Default: pause exploration with helpful message
        f2t_map_explore_pause_stranded(reason, destination_room_id)
    end
end

-- ========================================
-- Pause Exploration (Stranded)
-- ========================================

function f2t_map_explore_pause_stranded(reason, destination_room_id)
    if not F2T_MAP_EXPLORE_STATE.active then
        return
    end

    F2T_MAP_EXPLORE_STATE.paused = true
    F2T_MAP_EXPLORE_STATE.paused_reason = "stranded"
    F2T_MAP_EXPLORE_STATE.paused_destination = destination_room_id

    cecho("\n<yellow>[map-explore]<reset> Exploration paused - unable to navigate\n")
    cecho(string.format("\n<dim_grey>Reason: %s<reset>\n", reason))

    if destination_room_id then
        local dest_name = getRoomName(destination_room_id) or "Unknown"
        cecho(string.format("<dim_grey>Destination: %s (room %d)<reset>\n", dest_name, destination_room_id))
    end

    cecho("\n<yellow>To recover:<reset>\n")
    cecho("  1. Manually navigate to a known location (e.g., shuttlepad)\n")
    cecho("  2. Use <white>map explore resume<reset> to continue\n")
    cecho("  Or use <white>map explore stop<reset> to abort\n")

    f2t_debug_log("[map-explore] Paused due to stranded state: %s", reason)
end

f2t_debug_log("[map] Loaded map_explore_escape.lua")
