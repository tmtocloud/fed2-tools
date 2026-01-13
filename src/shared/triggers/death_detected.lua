-- @patterns:
--   - pattern: Darkness closes in. Farewell!
--     type: substring

-- Death detection trigger
-- CRITICAL: This fires BEFORE the respawn teleport, allowing location capture

-- Guard: Only process if death monitor enabled
if not f2t_settings_get("shared", "death_monitor_enabled") then
    return
end

-- Guard: Don't process if death recovery already active
if F2T_DEATH_STATE and F2T_DEATH_STATE.active then
    f2t_debug_log("[death] Death trigger fired but recovery already in progress")
    return
end

f2t_debug_log("[death] Death detected! Capturing location before respawn...")
f2t_death_start_recovery()
