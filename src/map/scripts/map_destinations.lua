-- Destination management for Federation 2 mapper
-- Stores user-defined saved destinations as Fed2 hashes in persistent settings

-- ========================================
-- Destination Storage
-- ========================================

-- Initialize destination settings
function f2t_map_init_destinations()
    f2t_settings = f2t_settings or {}
    f2t_settings.map = f2t_settings.map or {}
    f2t_settings.map.destinations = f2t_settings.map.destinations or {}

    f2t_debug_log("[map] Destinations initialized: %d destination(s) loaded",
        f2t_map_count_destinations())
end

-- ========================================
-- Destination Management Functions
-- ========================================

-- Add a destination for the current location
-- Returns: true on success, false on failure
function f2t_map_destination_add(dest_name)
    if not dest_name or dest_name == "" then
        cecho("\n<red>[map]<reset> Destination name required\n")
        return false
    end

    -- Normalize destination name (lowercase)
    dest_name = string.lower(dest_name)

    -- Get current room
    if not f2t_map_ensure_current_location(f2t_map_destination_add, {dest_name}) then
        return false
    end

    -- Get Fed2 hash from current room
    local hash = getRoomHashByID(F2T_MAP_CURRENT_ROOM_ID)
    if not hash or hash == "" then
        cecho("\n<red>[map]<reset> Current room has no Fed2 hash - cannot save destination\n")
        return false
    end

    -- Check if destination already exists
    local existing_hash = f2t_settings.map.destinations[dest_name]
    if existing_hash then
        cecho(string.format("\n<yellow>[map]<reset> Destination '%s' already exists (overwriting)\n",
            dest_name))
        f2t_debug_log("[map] Overwriting destination '%s': %s -> %s",
            dest_name, existing_hash, hash)
    end

    -- Store destination
    f2t_settings.map.destinations[dest_name] = hash
    f2t_save_settings()

    local room_name = getRoomName(F2T_MAP_CURRENT_ROOM_ID)
    cecho(string.format("\n<green>[map]<reset> Destination '<yellow>%s<reset>' saved for <cyan>%s<reset>\n",
        dest_name, room_name))
    f2t_debug_log("[map] Destination added: %s -> %s (%s)", dest_name, hash, room_name)

    return true
end

-- Remove a destination
-- Returns: true on success, false on failure
function f2t_map_destination_remove(dest_name)
    if not dest_name or dest_name == "" then
        cecho("\n<red>[map]<reset> Destination name required\n")
        return false
    end

    -- Normalize destination name (lowercase)
    dest_name = string.lower(dest_name)

    -- Check if destination exists
    if not f2t_settings.map.destinations[dest_name] then
        cecho(string.format("\n<red>[map]<reset> Destination '%s' not found\n", dest_name))
        return false
    end

    -- Remove destination
    f2t_settings.map.destinations[dest_name] = nil
    f2t_save_settings()

    cecho(string.format("\n<green>[map]<reset> Destination '<yellow>%s<reset>' removed\n", dest_name))
    f2t_debug_log("[map] Destination removed: %s", dest_name)

    return true
end

-- List all destinations
function f2t_map_destination_list()
    local destinations = f2t_settings.map.destinations or {}
    local count = 0

    -- Count destinations
    for _ in pairs(destinations) do
        count = count + 1
    end

    if count == 0 then
        cecho("\n<dim_grey>[map]<reset> No saved destinations\n")
        cecho("\n<dim_grey>Use 'map dest add <name>' to save a destination<reset>\n")
        return
    end

    -- Sort destination names
    local sorted_names = {}
    for name in pairs(destinations) do
        table.insert(sorted_names, name)
    end
    table.sort(sorted_names)

    -- Display header
    cecho(string.format("\n<green>[map]<reset> Saved Destinations (%d):\n", count))

    -- Display each destination
    for _, name in ipairs(sorted_names) do
        local hash = destinations[name]
        local room_id = f2t_map_get_room_by_hash(hash)

        if room_id then
            local room_name = getRoomName(room_id)
            cecho(string.format("  <yellow>%-20s<reset> → <cyan>%s<reset> <dim_grey>(%s)<reset>\n",
                name, room_name, hash))
        else
            cecho(string.format("  <yellow>%-20s<reset> → <red>Not mapped<reset> <dim_grey>(%s)<reset>\n",
                name, hash))
        end
    end
end

-- Get Fed2 hash for a destination
-- Returns: hash string or nil if not found
function f2t_map_destination_get(dest_name)
    if not dest_name or dest_name == "" then
        return nil
    end

    -- Normalize destination name (lowercase)
    dest_name = string.lower(dest_name)

    local hash = f2t_settings.map.destinations[dest_name]
    if hash then
        f2t_debug_log("[map] Destination '%s' -> hash '%s'", dest_name, hash)
    end

    return hash
end

-- Count destinations
-- Returns: number of destinations
function f2t_map_count_destinations()
    local count = 0
    local destinations = f2t_settings.map.destinations or {}

    for _ in pairs(destinations) do
        count = count + 1
    end

    return count
end

-- ========================================
-- Initialization
-- ========================================

-- Initialize destinations on script load
f2t_map_init_destinations()
