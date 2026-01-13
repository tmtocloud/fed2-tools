-- @patterns:
--   - pattern: ^   (\S.*)$
--     type: regex

-- Capture individual cartel names from "display cartels" output
-- Triggers on lines starting with 3 spaces followed by cartel name

if not F2T_MAP_EXPLORE_GALAXY_CAPTURE or not F2T_MAP_EXPLORE_GALAXY_CAPTURE.active then
    return
end

-- Hide output
deleteLine()

-- Extract cartel name (already trimmed by regex capture)
local cartel_name = matches[2]

-- Store cartel name
table.insert(F2T_MAP_EXPLORE_GALAXY_CAPTURE.lines, cartel_name)

f2t_debug_log("[map-explore-galaxy] Captured cartel: %s", cartel_name)

-- Reset timer (0.5s of silence = capture complete)
f2t_map_explore_galaxy_reset_timer()
