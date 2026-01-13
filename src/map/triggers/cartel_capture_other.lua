-- @patterns:
--   - pattern: ^[A-Z].+Cartel
--     type: regex
--   - pattern: ^   [A-Z]
--     type: regex
--   - pattern: ^      .+ \([a-z]+/\d+\)$
--     type: regex

-- Delete cartel output lines that aren't system names:
-- Pattern 1: Header line (e.g., "Coffee Cartel - Plutocrat...")
-- Pattern 2: Metadata lines (e.g., "   Cartel queues...", "   The cartel has...", "   Blish Cities:")
-- Pattern 3: City lines (e.g., "      Kona (leisure/5)")

if not F2T_MAP_EXPLORE_CARTEL_CAPTURE or not F2T_MAP_EXPLORE_CARTEL_CAPTURE.active then
    return
end

-- If we're in the Members section, don't delete here (member trigger handles it)
if F2T_MAP_EXPLORE_CARTEL_CAPTURE.in_members then
    return
end

-- Delete these lines (header, metadata, or cities)
deleteLine()
