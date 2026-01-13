-- @patterns:
--   - pattern: ^Cartels operating in this galaxy:$
--     type: regex

-- Start of galaxy cartels list
-- Triggers when we see "Cartels operating in this galaxy:"

if not F2T_MAP_EXPLORE_GALAXY_CAPTURE or not F2T_MAP_EXPLORE_GALAXY_CAPTURE.active then
    return
end

-- Hide header
deleteLine()

f2t_debug_log("[map-explore-galaxy] Found galaxy cartels header")

-- Start timer (will reset with each captured line)
f2t_map_explore_galaxy_reset_timer()
