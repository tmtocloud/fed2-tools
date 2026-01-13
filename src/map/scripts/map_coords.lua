-- Coordinate calculation for Federation 2 mapper
-- Uses Fed2's native grid system for deterministic room positioning

-- ========================================
-- Fed2 Grid Coordinate Calculation
-- ========================================

-- Calculate absolute coordinates from Fed2 room number
-- Fed2 uses a grid system where room numbers map to coordinates:
-- x = room_num % 64 (column, 0-63)
-- y = -floor(room_num / 64) (row, inverted for visual display)
-- z = 0 (always ground level)
-- Returns: x, y, z
function f2t_map_calculate_coords_from_room_num(room_num)
    if not room_num then
        f2t_debug_log("[map] ERROR: Cannot calculate coords from nil room_num")
        return 0, 0, 0
    end

    local x = room_num % 64
    local y = -math.floor(room_num / 64)
    local z = 0

    f2t_debug_log("[map] Calculated coords for room #%d: (%d, %d, %d)", room_num, x, y, z)

    return x, y, z
end

-- ========================================
-- Coordinate Utilities
-- ========================================

-- Set room coordinates with validation
-- Returns: true on success, false on failure
function f2t_map_set_room_coords(room_id, x, y, z)
    if not room_id or not roomExists(room_id) then
        f2t_debug_log("[map] ERROR: Cannot set coords for invalid room: %s", tostring(room_id))
        return false
    end

    setRoomCoordinates(room_id, x, y, z)
    f2t_debug_log("[map] Room %d coordinates set to (%d, %d, %d)", room_id, x, y, z)
    return true
end

-- Get the opposite direction for bidirectional exit creation
-- Returns: opposite direction string or nil
function f2t_map_get_opposite_direction(direction)
    local opposites = {
        n = "s", s = "n",
        e = "w", w = "e",
        ne = "sw", sw = "ne",
        nw = "se", se = "nw",
        u = "d", d = "u",
        up = "down", down = "up",
        ["in"] = "out", out = "in"
    }

    return opposites[direction]
end

-- Convert string direction to Mudlet numeric direction code
-- Returns: numeric direction code or nil
function f2t_map_direction_to_number(direction)
    local dir_map = {
        n = 1,
        ne = 2,
        nw = 3,
        e = 4,
        w = 5,
        s = 6,
        se = 7,
        sw = 8,
        u = 9,
        d = 10,
        ["in"] = 11,
        out = 12,
        up = 9,
        down = 10,
        -- Also handle full names
        north = 1,
        northeast = 2,
        northwest = 3,
        east = 4,
        west = 5,
        south = 6,
        southeast = 7,
        southwest = 8
    }

    return dir_map[direction]
end

-- Normalize direction to abbreviated form
-- Mudlet sometimes expands directions (sw -> southwest)
-- Returns: normalized abbreviated direction
function f2t_map_normalize_direction(direction)
    local normalize_map = {
        north = "n",
        northeast = "ne",
        northwest = "nw",
        east = "e",
        west = "w",
        south = "s",
        southeast = "se",
        southwest = "sw",
        up = "u",
        down = "d"
    }

    -- Return normalized version if it exists, otherwise return as-is
    return normalize_map[direction] or direction
end
