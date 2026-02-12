-- Trigger for game shutdown warning to auto-stop hauling
-- @patterns:
--   - pattern: ^Federation II will be closing down for a short while in six minutes time\.$
--     type: regex

-- Only act if hauling is currently active
if not F2T_HAULING_STATE or not F2T_HAULING_STATE.active then
    return
end

-- Cancel existing timer if one exists (e.g., multiple warnings)
if F2T_HAULING_STATE.shutdown_timer_id then
    killTimer(F2T_HAULING_STATE.shutdown_timer_id)
    f2t_debug_log("[hauling] Cancelled existing shutdown timer")
end

f2t_debug_log("[hauling] Shutdown warning received, scheduling stop in 4 minutes")
cecho("\n<yellow>[hauling]<reset> Game shutdown in 6 minutes - hauling will stop in 4 minutes\n")

-- Schedule graceful stop in 4 minutes (240 seconds)
F2T_HAULING_STATE.shutdown_timer_id = tempTimer(240, function()
    F2T_HAULING_STATE.shutdown_timer_id = nil

    if not F2T_HAULING_STATE.active then
        f2t_debug_log("[hauling] Shutdown timer fired but hauling already stopped")
        return
    end

    f2t_debug_log("[hauling] Shutdown timer expired, initiating graceful stop")
    cecho("\n<yellow>[hauling]<reset> Stopping hauling before game reset...\n")
    f2t_hauling_stop()
end)
