-- Area management for Federation 2 mapper
-- Handles creation and retrieval of areas (planets/stations)

-- ========================================
-- Area Lookup and Creation
-- ========================================

-- Get or create an area by name
-- Returns: area_id (number)
function f2t_map_get_or_create_area(area_name, area_data)
    if not area_name or area_name == "" then
        f2t_debug_log("[map] ERROR: Cannot create area with empty name")
        return nil
    end

    -- Check if area already exists
    local areas = getAreaTable()
    local area_id = areas[area_name]

    if area_id then
        f2t_debug_log("[map] Area found: %s (ID: %d)", area_name, area_id)
        return area_id
    end

    -- Create new area
    area_id = addAreaName(area_name)
    if not area_id then
        f2t_debug_log("[map] ERROR: Failed to create area: %s", area_name)
        return nil
    end

    -- Set default zoom level for the area
    local zoom = f2t_settings_get("map", "area_zoom")
    setMapZoom(zoom, area_id)

    f2t_debug_log("[map] Area created: %s (ID: %d, zoom: %d)", area_name, area_id, zoom)

    -- Store area metadata if provided
    if area_data then
        if area_data.system then
            setAreaUserData(area_id, "fed2_system", area_data.system)
            f2t_debug_log("[map]   System: %s", area_data.system)
        end

        if area_data.cartel then
            setAreaUserData(area_id, "fed2_cartel", area_data.cartel)
            f2t_debug_log("[map]   Cartel: %s", area_data.cartel)
        end

        if area_data.owner then
            setAreaUserData(area_id, "fed2_owner", area_data.owner)
            f2t_debug_log("[map]   Owner: %s", area_data.owner)
        end
    end

    return area_id
end

-- ========================================
-- Area Retrieval
-- ========================================

-- Get area ID by name (case-insensitive)
-- Returns: area_id or nil
function f2t_map_get_area_id(area_name)
    if not area_name or area_name == "" then
        return nil
    end

    local areas = getAreaTable()

    -- Try exact match first (faster)
    local area_id = areas[area_name]
    if area_id then
        f2t_debug_log("[map_area] get_area_id('%s') -> %d (exact match)", area_name, area_id)
        return area_id
    end

    -- Case-insensitive search
    local search_lower = string.lower(area_name)
    for name, id in pairs(areas) do
        if string.lower(name) == search_lower then
            f2t_debug_log("[map_area] get_area_id('%s') -> %d (case-insensitive match: '%s')", area_name, id, name)
            return id
        end
    end

    f2t_debug_log("[map_area] get_area_id('%s') -> nil (not found)", area_name)
    return nil
end

-- Get area name by ID
-- Returns: area_name or nil
function f2t_map_get_area_name(area_id)
    return getRoomAreaName(area_id)
end

-- ========================================
-- System Name Helpers
-- ========================================

-- Get system name from a "{System} Space" area name
-- Example: "Coffee Space" -> "Coffee"
function f2t_map_get_system_from_space_area(area_name)
    local system = string.match(area_name, "^(.+)%s+Space$")
    return system
end

-- Get space area name from system name
-- Example: "Coffee" -> "Coffee Space"
-- Note: This returns the input case, use f2t_map_get_system_space_area_actual() for case-insensitive lookup
function f2t_map_get_system_space_area(system)
    return string.format("%s Space", system)
end

-- Get the actual space area name for a system (case-insensitive)
-- Returns: actual area name with correct case, or nil if not found
function f2t_map_get_system_space_area_actual(system_name)
    local areas = getAreaTable()
    local search_lower = string.lower(system_name)

    for area_name, _ in pairs(areas) do
        local system = f2t_map_get_system_from_space_area(area_name)
        if system and string.lower(system) == search_lower then
            return area_name
        end
    end

    return nil
end

-- ========================================
-- Input Parsing Helpers
-- ========================================

-- Parse a multi-word input string into <location> <remaining_text>
-- Uses progressive prefix matching: tries longest possible location name first,
-- then progressively shorter prefixes, until a valid planet/system is found
--
-- Example: "the lattice exchange room"
--   - Tries "the lattice exchange" (no match)
--   - Tries "the lattice" (match!) -> returns "the lattice", "exchange room"
--
-- @param input: The full input string to parse
-- @return location_name: The matched planet/system name (or nil if none found)
-- @return remaining_text: Everything after the location (or full input if no location found)
function f2t_map_parse_location_prefix(input)
    if not input or input == "" then
        return nil, ""
    end

    -- Split into words
    local words = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(words, word)
    end

    -- Need at least 2 words (location + remaining)
    if #words < 2 then
        return nil, input
    end

    -- Try progressively longer prefixes as location names
    -- Start from longest possible (all words except last) down to single word
    for i = #words - 1, 1, -1 do
        local potential_location = table.concat(words, " ", 1, i)

        -- Check if it's a planet (area)
        local area_id = f2t_map_get_area_id(potential_location)

        -- Check if it's a system ("{System} Space" area exists)
        local space_area = f2t_map_get_system_space_area_actual(potential_location)

        if area_id or space_area then
            -- Found a valid location, rest is remaining text
            local remaining = table.concat(words, " ", i + 1)
            f2t_debug_log("[map_area] parse_location_prefix('%s') -> location='%s', remaining='%s'",
                input, potential_location, remaining)
            return potential_location, remaining
        end
    end

    -- No location found
    f2t_debug_log("[map_area] parse_location_prefix('%s') -> no location found", input)
    return nil, input
end
