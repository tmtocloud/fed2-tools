-- @patterns:
--   - pattern: ^System information for the (.+) system:$
--     type: regex

-- Start capturing DI system output
-- Triggers when we see "System information for the <name> system:"

if not F2T_MAP_DI_SYSTEM_CAPTURE or not F2T_MAP_DI_SYSTEM_CAPTURE.active then
    return
end

-- Hide output
deleteLine()

f2t_debug_log("[map-di-system] Found system information header, starting planet capture")
