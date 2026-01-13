-- @patterns:
--   - pattern: ^   Members:$
--     type: regex

-- Start capturing cartel members section
-- Triggers when we see "   Members:" (3 spaces + "Members:")

if not F2T_MAP_EXPLORE_CARTEL_CAPTURE or not F2T_MAP_EXPLORE_CARTEL_CAPTURE.active then
    return
end

-- Hide output
deleteLine()

-- Mark that we're now in the Members section
F2T_MAP_EXPLORE_CARTEL_CAPTURE.in_members = true

f2t_debug_log("[map-explore-cartel] Found Members section, starting system capture")
