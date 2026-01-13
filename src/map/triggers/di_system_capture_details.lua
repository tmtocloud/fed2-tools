-- @patterns:
--   - pattern: ^  .+$
--     type: regex

-- Capture detail lines from DI system output (Owner, Economy, etc.)
-- Triggers on lines starting with 2 spaces
-- Store these lines so we can check for Economy: None or Workforce: 0/0

if not F2T_MAP_DI_SYSTEM_CAPTURE or not F2T_MAP_DI_SYSTEM_CAPTURE.active then
    return
end

-- Hide output
deleteLine()

-- Extract the detail line
local detail_line = line

-- Store detail line
table.insert(F2T_MAP_DI_SYSTEM_CAPTURE.planet_names, detail_line)

-- Reset timer (0.5s of silence = capture complete)
f2t_map_di_system_reset_timer()
