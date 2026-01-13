-- Map import/export functionality
-- Uses Mudlet's native saveJsonMap/loadJsonMap functions with file dialogs

-- ========================================
-- Export Functions
-- ========================================

-- Export the map to a JSON file using file dialog
-- Returns: true on success, false on failure
function f2t_map_export()
    f2t_debug_log("[map] Starting map export")

    -- Get all rooms to check if map is empty
    local rooms = getRooms()
    local room_count = 0
    for _ in pairs(rooms) do
        room_count = room_count + 1
    end

    if room_count == 0 then
        cecho("\n<yellow>[map]<reset> No rooms to export. Map is empty.\n")
        f2t_debug_log("[map] Export aborted: map is empty")
        return false
    end

    -- Generate timestamped filename
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
    local default_filename = string.format("f2t_map_export_%s.json", timestamp)

    -- Prompt user for save location
    cecho(string.format("\n<green>[map]<reset> Select directory to save: <white>%s<reset>\n", default_filename))
    local file_path = invokeFileDialog(false, "Select Directory for Map Export")

    if not file_path or file_path == "" then
        cecho("\n<yellow>[map]<reset> Export cancelled.\n")
        f2t_debug_log("[map] Export cancelled by user")
        return false
    end

    -- Always append our timestamped filename to the selected path
    -- Remove trailing slash if present, then add filename
    file_path = string.format("%s/%s", file_path:gsub("/$", ""), default_filename)

    f2t_debug_log("[map] Exporting map to: %s", file_path)

    -- Use Mudlet's native saveJsonMap function
    local success, error_msg = saveJsonMap(file_path)

    if success then
        cecho(string.format("\n<green>[map]<reset> Map exported successfully\n"))
        cecho(string.format("\n<dim_grey>  Rooms: %d<reset>\n", room_count))
        cecho(string.format("\n<dim_grey>  File: %s<reset>\n", file_path))
        f2t_debug_log("[map] Export successful: %d rooms exported to %s", room_count, file_path)
        return true
    else
        cecho(string.format("\n<red>[map]<reset> Export failed\n"))
        if error_msg then
            cecho(string.format("\n<dim_grey>  Error: %s<reset>\n", error_msg))
        end
        cecho(string.format("\n<dim_grey>  File: %s<reset>\n", file_path))
        f2t_debug_log("[map] Export failed: %s", error_msg or "unknown error")
        return false
    end
end

-- ========================================
-- Import Functions
-- ========================================

-- Helper function to get map file info
-- Returns: room_count, area_count, error_msg
local function get_map_file_info(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil, nil, "File not found"
    end

    local content = file:read("*all")
    file:close()

    -- Try to parse JSON and count rooms
    local success, data = pcall(yajl.to_value, content)
    if not success then
        return nil, nil, "Invalid JSON format"
    end

    if not data or type(data) ~= "table" then
        return nil, nil, "Invalid map format"
    end

    -- Count rooms and areas in the map data
    -- Mudlet's saveJsonMap format: { areas: [ { rooms: [...] } ] }
    local room_count = 0
    local area_count = 0

    if data.areas and type(data.areas) == "table" then
        -- Areas is an array, iterate through it
        for _, area in ipairs(data.areas) do
            -- Count non-empty areas (skip Default Area with 0 rooms)
            if area.rooms and type(area.rooms) == "table" then
                local area_room_count = 0
                for _ in ipairs(area.rooms) do
                    room_count = room_count + 1
                    area_room_count = area_room_count + 1
                end
                if area_room_count > 0 then
                    area_count = area_count + 1
                end
            end
        end
    end

    f2t_debug_log("[map] Counted %d rooms in %d areas in map file", room_count, area_count)
    return room_count, area_count, nil
end

-- Execute map import (called by confirmation system)
-- @param data Table with file_path
-- Returns: true on success, false on failure
local function f2t_map_import_execute(data)
    local file_path = data.file_path

    f2t_debug_log("[map] Executing confirmed import from: %s", file_path)

    -- Clear existing map
    f2t_debug_log("[map] Clearing existing map before import")
    deleteMap()
    f2t_debug_log("[map] Map cleared using deleteMap()")

    -- Reset mapper state
    F2T_MAP_CURRENT_ROOM_ID = nil

    -- Load the map
    local success, error_msg = loadJsonMap(file_path)

    if success then
        -- Update map display
        updateMap()

        -- Get new room count
        local rooms = getRooms()
        local new_room_count = 0
        for _ in pairs(rooms) do
            new_room_count = new_room_count + 1
        end

        cecho("\n<green>[map]<reset> Map imported successfully\n")
        cecho(string.format("\n<dim_grey>  Rooms: %d<reset>\n", new_room_count))
        cecho(string.format("\n<dim_grey>  File: %s<reset>\n", file_path))
        f2t_debug_log("[map] Import successful: %d rooms now in map", new_room_count)

        -- Resync with current location if mapper is enabled
        if F2T_MAP_ENABLED then
            cecho("\n<green>[map]<reset> Synchronizing with current location...\n")
            tempTimer(0.5, function()
                f2t_map_sync()
            end)
        end

        return true
    else
        cecho("\n<red>[map]<reset> Import failed\n")
        if error_msg then
            cecho(string.format("\n<dim_grey>  Error: %s<reset>\n", error_msg))
        end
        cecho(string.format("\n<dim_grey>  File: %s<reset>\n", file_path))
        f2t_debug_log("[map] Import failed: %s", error_msg or "unknown error")
        return false
    end
end

-- Import a map from a JSON file using file dialog
-- Returns: true on success, false on failure, nil if awaiting confirmation
function f2t_map_import()

    -- Not confirmed - select file and show info
    cecho("\n<green>[map]<reset> Select map file to import...\n")
    local file_path = invokeFileDialog(true, "Open Map File (JSON format)")

    if not file_path or file_path == "" then
        cecho("\n<yellow>[map]<reset> Import cancelled.\n")
        f2t_debug_log("[map] Import cancelled by user")
        return false
    end

    f2t_debug_log("[map] Selected file for import: %s", file_path)

    -- Check if file exists and get info
    local import_room_count, import_area_count, error_msg = get_map_file_info(file_path)
    if not import_room_count then
        cecho("\n<red>[map]<reset> Cannot read map file\n")
        if error_msg then
            cecho(string.format("\n<dim_grey>  Error: %s<reset>\n", error_msg))
        end
        cecho(string.format("\n<dim_grey>  File: %s<reset>\n", file_path))
        f2t_debug_log("[map] Failed to read map file: %s", error_msg or "unknown error")
        return false
    end

    -- Get current map info
    local rooms = getRooms()
    local current_room_count = 0
    for _ in pairs(rooms) do
        current_room_count = current_room_count + 1
    end

    local areas = getAreaTable()
    local current_area_count = 0
    for area_name, area_id in pairs(areas) do
        -- Count non-default areas with rooms
        local area_rooms = getAreaRooms(area_id)
        if area_rooms and next(area_rooms) ~= nil then
            current_area_count = current_area_count + 1
        end
    end

    -- Show summary
    cecho("\n<cyan>[map]<reset> Import Summary:\n")
    cecho(string.format("\n  File: %s\n", file_path))
    cecho(string.format("\n  Map import: %d rooms across %d areas\n",
        import_room_count, import_area_count))

    if current_room_count > 0 then
        cecho(string.format("\n  Current map: %d rooms across %d areas\n",
            current_room_count, current_area_count))
        cecho("\n<yellow>[map]<reset> WARNING: Import will DELETE your current map!\n")
        cecho("\n<cyan>[map]<reset> TIP: Use <white>map export<reset> to backup your current map first.\n")
    else
        cecho("\n  Current map: empty\n")
    end

    f2t_debug_log("[map] Import requires confirmation - file has %d rooms in %d areas, current map has %d rooms in %d areas",
        import_room_count, import_area_count, current_room_count, current_area_count)

    -- Build confirmation action string
    local action = string.format("import map (%d rooms, %d areas)", import_room_count, import_area_count)
    if current_room_count > 0 then
        action = string.format("import map and DELETE current map (%d -> %d rooms)",
            current_room_count, import_room_count)
    end

    -- Use shared confirmation system
    f2t_map_manual_request_confirmation(action, f2t_map_import_execute, {
        file_path = file_path,
        room_count = import_room_count,
        area_count = import_area_count
    })

    return nil
end
