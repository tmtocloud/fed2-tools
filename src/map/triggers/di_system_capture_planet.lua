-- @patterns:
--   - pattern: ^([^,]+, .+ system, .+ cartel)$
--     type: regex

-- Capture planet/area lines from DI system output
-- Triggers on lines like: "Affogato, Coffee system, Coffee cartel"
-- or: "Coffee Space, Coffee system, Coffee cartel"

if not F2T_MAP_DI_SYSTEM_CAPTURE or not F2T_MAP_DI_SYSTEM_CAPTURE.active then
    return
end

-- Hide output
deleteLine()

-- Extract full line
local planet_line = matches[2]

-- Store planet line
table.insert(F2T_MAP_DI_SYSTEM_CAPTURE.planet_names, planet_line)

f2t_debug_log("[map-di-system] Captured planet line: %s", planet_line)

-- Reset timer (0.5s of silence = capture complete)
f2t_map_di_system_reset_timer()
