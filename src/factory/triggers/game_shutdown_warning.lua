-- Trigger for game shutdown warning to auto-flush factories
-- @patterns:
--   - pattern: ^Federation II will be closing down for a short while in six minutes time\.$
--     type: regex

-- Only proceed if auto_flush_before_reset setting is enabled
if not f2t_settings_get("factory", "auto_flush_before_reset") then
    f2t_debug_log("[factory-auto-flush] Shutdown warning received, but auto-flush is disabled")
    return
end

-- Cancel existing timer if one exists
if f2t_factory.shutdown_timer_id then
    killTimer(f2t_factory.shutdown_timer_id)
    f2t_debug_log("[factory-auto-flush] Cancelled existing shutdown timer")
end

f2t_debug_log("[factory-auto-flush] Shutdown warning received, scheduling flush in 4 minutes")
cecho("\n<yellow>[factory]<reset> Game shutdown in 6 minutes - will flush factories in 4 minutes\n")

-- Set timer for 4 minutes (240 seconds) before flushing
f2t_factory.shutdown_timer_id = tempTimer(240, function()
    f2t_debug_log("[factory-auto-flush] Timer expired, initiating factory flush")
    cecho("\n<green>[factory]<reset> Auto-flushing factories before game reset...\n")
    f2t_factory_start_flush()
    f2t_factory.shutdown_timer_id = nil
end)
