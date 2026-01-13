-- @patterns:
--   - pattern: Your routine is suddenly interrupted by the appearance
--     type: substring
-- Trigger when Sol customs inspection STARTS to stop speedwalk immediately
-- This prevents queued commands from executing during the customs sequence

-- Only handle this if speedwalk is active
if not F2T_SPEEDWALK_ACTIVE then
    return
end

cecho("\n<yellow>[map]<reset> Customs inspection - stopping speedwalk\n")
f2t_debug_log("[map] Customs started, stopping speedwalk to prevent command queue issues")

-- Save state before stopping (stop will clear these)
local saved_destination = F2T_SPEEDWALK_DESTINATION_ROOM_ID
local saved_owner = F2T_SPEEDWALK_OWNER
local saved_callback = F2T_SPEEDWALK_ON_INTERRUPT

-- Notify owner of interrupt via callback (if registered)
-- Callback can pause its state and return { auto_resume = true } to request auto-resume
local auto_resume = false
if saved_callback then
    -- Use pcall to protect against callback errors
    local success, result = pcall(saved_callback, "customs")
    if success then
        if result and result.auto_resume then
            auto_resume = true
            f2t_debug_log("[map] Owner requested auto-resume after customs")
        end
    else
        f2t_debug_log("[map] Callback error during customs: %s", tostring(result))
        -- Default to auto-resume on error for safety
        auto_resume = true
    end
else
    -- Standalone navigation: auto-resume by default
    auto_resume = true
    f2t_debug_log("[map] Standalone navigation, will auto-resume after customs")
end

-- CRITICAL: Stop speedwalk immediately to prevent queued commands from executing
f2t_map_speedwalk_stop()

-- If we had a destination and should auto-resume, handle recovery after customs completes
if saved_destination and auto_resume then
    f2t_debug_log("[map] Saved destination %d, will attempt recovery after customs", saved_destination)

    -- Wait for customs to complete (1s) then issue look to get GMCP update
    tempTimer(1.0, function()
        f2t_debug_log("[map] Customs complete, issuing look to get current location")
        send("look")

        -- Wait for GMCP update (1s) then attempt to resume navigation
        tempTimer(1.0, function()
            local current_room = F2T_MAP_CURRENT_ROOM_ID

            if not current_room then
                cecho("\n<yellow>[map]<reset> Cannot determine current location after customs\n")
                f2t_debug_log("[map] No current room ID after customs, cannot resume")
                return
            end

            if current_room == saved_destination then
                f2t_debug_log("[map] Already at destination %d after customs", saved_destination)
                return
            end

            f2t_debug_log("[map] Resuming navigation from room %d to %d", current_room, saved_destination)
            cecho("\n<yellow>[map]<reset> Resuming navigation after customs...\n")

            -- Restore ownership for recovery navigation
            -- This ensures subsequent interrupts use the same callback
            if saved_owner and saved_callback then
                f2t_map_set_nav_owner(saved_owner, saved_callback)
                f2t_debug_log("[map] Ownership restored for post-customs recovery: %s", saved_owner)
            end

            -- Restart navigation to the saved destination
            -- f2t_map_navigate accepts room ID as string
            f2t_map_navigate(tostring(saved_destination))
        end)
    end)
end
