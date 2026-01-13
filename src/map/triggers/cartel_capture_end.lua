-- @patterns:
--   - pattern: ^   Cartel
--     type: regex

-- End capturing Members section
-- Triggers on lines starting with "   Cartel" (e.g., "   Cartel queues...")

if not F2T_MAP_EXPLORE_CARTEL_CAPTURE or not F2T_MAP_EXPLORE_CARTEL_CAPTURE.active then
    return
end

-- Only process if we were in the Members section
if not F2T_MAP_EXPLORE_CARTEL_CAPTURE.in_members then
    return
end

-- Hide output
deleteLine()

-- Mark end of Members section (but keep capture active to hide remaining output)
F2T_MAP_EXPLORE_CARTEL_CAPTURE.in_members = false

f2t_debug_log("[map-explore-cartel] End of Members section, waiting for output to finish...")

-- Reset timer - when output stops (0.5s silence), process capture
f2t_map_explore_cartel_reset_timer()
