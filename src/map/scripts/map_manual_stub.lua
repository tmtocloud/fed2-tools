-- Stub exit management for Federation 2 mapper
-- Provides functions to create, delete, connect, and list stub exits

-- ========================================
-- Helper Functions
-- ========================================

-- Direction number to name mapping (from Mudlet docs)
local DIRECTION_NUMBERS = {
    [1] = "north", [2] = "northeast", [3] = "northwest",
    [4] = "east", [5] = "west", [6] = "south",
    [7] = "southeast", [8] = "southwest",
    [9] = "up", [10] = "down", [11] = "in", [12] = "out"
}

--- Convert direction number to name
--- @param dir_num number Direction number (1-12)
--- @return string|nil Direction name or nil if invalid
local function direction_number_to_name(dir_num)
    return DIRECTION_NUMBERS[dir_num]
end

-- ========================================
-- Stub Exit Creation
-- ========================================

--- Create a stub exit from a room in a given direction
--- @param room_id number Room ID to create stub from
--- @param direction string Exit direction
--- @return boolean true on success, false on failure
function f2t_map_manual_create_stub(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    direction = string.lower(direction)

    -- Check if stub already exists
    local existing_stubs = getExitStubs1(room_id)
    if existing_stubs then
        -- Use pairs() not ipairs() - getExitStubs() returns 0-indexed table
        for _, stub_dir_num in pairs(existing_stubs) do
            local stub_dir = direction_number_to_name(stub_dir_num)
            if stub_dir == direction then
                cecho(string.format("\n<yellow>[map]<reset> Stub exit '%s' already exists in room %d\n",
                    direction, room_id))
                return true
            end
        end
    end

    -- Check if regular exit already exists
    local exits = getRoomExits(room_id)
    if exits and exits[direction] then
        cecho(string.format("\n<red>[map]<reset> Regular exit '%s' already exists in room %d\n",
            direction, room_id))
        cecho("\n<dim_grey>Remove the regular exit first or use a different direction<reset>\n")
        return false
    end

    -- Create the stub exit
    setExitStub(room_id, direction, true)

    local room_name = getRoomName(room_id) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Stub exit created: <white>%s<reset> --%s--> <yellow>(stub)<reset>\n",
        room_name, direction))
    cecho("\n<dim_grey>Use 'map exit stub connect %d %s' to connect to destination<reset>\n",
        room_id, direction)

    f2t_debug_log("[map_manual] Stub exit created: %d --%s--> stub", room_id, direction)

    return true
end

-- ========================================
-- Stub Exit Deletion
-- ========================================

--- Delete a stub exit from a room
--- @param room_id number Room ID
--- @param direction string Exit direction
--- @return boolean true on success, false on failure
function f2t_map_manual_delete_stub(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    direction = string.lower(direction)

    -- Check if stub exists
    local existing_stubs = getExitStubs1(room_id)
    local stub_exists = false
    if existing_stubs then
        -- Use pairs() not ipairs() - getExitStubs() returns 0-indexed table
        for _, stub_dir_num in pairs(existing_stubs) do
            local stub_dir = direction_number_to_name(stub_dir_num)
            if stub_dir == direction then
                stub_exists = true
                break
            end
        end
    end

    if not stub_exists then
        cecho(string.format("\n<yellow>[map]<reset> No stub exit '%s' in room %d\n", direction, room_id))
        return false
    end

    -- Delete the stub exit
    setExitStub(room_id, direction, false)

    local room_name = getRoomName(room_id) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Stub exit deleted: <white>%s<reset> --%s--> <dim_grey>(removed)<reset>\n",
        room_name, direction))

    f2t_debug_log("[map_manual] Stub exit deleted: %d --%s-->", room_id, direction)

    return true
end

-- ========================================
-- Stub Exit Connection
-- ========================================

--- Connect a stub exit to its destination room
--- Uses Mudlet's smart matching to find the appropriate room
--- @param room_id number Room ID with stub exit
--- @param direction string Stub exit direction
--- @return boolean true on success, false on failure
function f2t_map_manual_connect_stub(room_id, direction)
    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return false
    end

    if not direction or direction == "" then
        cecho("\n<red>[map]<reset> Direction required\n")
        return false
    end

    direction = string.lower(direction)

    -- Check if stub exists
    local existing_stubs = getExitStubs1(room_id)
    local stub_exists = false
    if existing_stubs then
        -- Use pairs() not ipairs() - getExitStubs() returns 0-indexed table
        for _, stub_dir_num in pairs(existing_stubs) do
            local stub_dir = direction_number_to_name(stub_dir_num)
            if stub_dir == direction then
                stub_exists = true
                break
            end
        end
    end

    if not stub_exists then
        cecho(string.format("\n<red>[map]<reset> No stub exit '%s' in room %d\n", direction, room_id))
        return false
    end

    -- Connect the stub (Mudlet finds matching room automatically)
    local dir_num = f2t_map_direction_to_number(direction)
    local success = connectExitStub(room_id, dir_num)

    if success then
        -- Get the destination room (stub should now be a regular exit)
        local exits = getRoomExits(room_id)
        local dest_room = exits and exits[direction]

        if dest_room then
            local room_name = getRoomName(room_id) or "unnamed"
            local dest_name = getRoomName(dest_room) or "unnamed"

            cecho(string.format("\n<green>[map]<reset> Stub exit connected: <white>%s<reset> --%s--> <white>%s<reset>\n",
                room_name, direction, dest_name))

            f2t_debug_log("[map_manual] Stub exit connected: %d --%s--> %d", room_id, direction, dest_room)
        else
            cecho(string.format("\n<green>[map]<reset> Stub exit '%s' in room %d connected\n", direction, room_id))
            f2t_debug_log("[map_manual] Stub exit connected: %d --%s-->", room_id, direction)
        end

        return true
    else
        cecho(string.format("\n<red>[map]<reset> Failed to connect stub exit '%s' in room %d\n", direction, room_id))
        cecho("\n<dim_grey>Mudlet couldn't find a matching room with opposite stub<reset>\n")
        cecho("\n<dim_grey>Ensure destination room has opposite stub exit (e.g., south stub for north)<reset>\n")

        f2t_debug_log("[map_manual] Failed to connect stub exit: %d --%s-->", room_id, direction)

        return false
    end
end

-- ========================================
-- Stub Exit Listing
-- ========================================

--- List all stub exits in a room
--- @param room_id number Room ID (defaults to current room if nil)
function f2t_map_manual_list_stubs(room_id)
    room_id = room_id or F2T_MAP_CURRENT_ROOM_ID

    if not room_id or not roomExists(room_id) then
        cecho(string.format("\n<red>[map]<reset> Room %s does not exist\n", tostring(room_id)))
        return
    end

    local room_name = getRoomName(room_id) or "unnamed"

    cecho(string.format("\n<green>[map]<reset> Stub exits for room %d (<white>%s<reset>):\n",
        room_id, room_name))

    local stubs = getExitStubs1(room_id)

    if stubs and next(stubs) ~= nil then
        -- Use pairs() not ipairs() - getExitStubs() returns 0-indexed table
        for _, stub_dir_num in pairs(stubs) do
            local stub_dir = direction_number_to_name(stub_dir_num)
            if stub_dir then
                cecho(string.format("  <yellow>%-10s<reset> <dim_grey>(stub exit, not connected)<reset>\n", stub_dir))
            else
                cecho(string.format("  <yellow>%-10s<reset> <dim_grey>(unknown direction: %d)<reset>\n",
                    "???", stub_dir_num))
            end
        end

        cecho(string.format("\n<dim_grey>Use 'map exit stub connect %d <direction>' to connect stubs<reset>\n", room_id))
    else
        cecho("\n<dim_grey>No stub exits in this room<reset>\n")
    end

    cecho("\n")
end

f2t_debug_log("[map] Manual stub exit management initialized")
