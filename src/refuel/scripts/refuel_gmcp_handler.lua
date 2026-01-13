-- GMCP event handler for automatic refueling
-- Replaces unreliable prompt trigger with GMCP room.info event

-- Handler function for room changes
function f2t_refuel_on_room_change()
    -- Only run if refuel threshold is set (0 = disabled)
    local threshold = REFUEL_THRESHOLD or 0
    if threshold <= 0 then
        return
    end

    -- Check if we're at a shuttlepad
    local room_info = gmcp.room and gmcp.room.info
    if not room_info or not room_info.flags then
        return
    end

    local flags = room_info.flags
    if not f2t_has_value(flags, "shuttlepad") then
        return
    end

    f2t_debug_log("[refuel] At shuttlepad, checking fuel level")

    -- Check current fuel level against configured threshold
    local fuel = gmcp.char and gmcp.char.ship and gmcp.char.ship.fuel
    if not fuel or not fuel.cur or not fuel.max then
        f2t_debug_log("[refuel] ERROR: Fuel data not available")
        return
    end

    local cur_fuel = fuel.cur
    local max_fuel = fuel.max
    local fuel_percent = math.floor((cur_fuel / max_fuel) * 100 + 0.5)

    if fuel_percent <= threshold then
        f2t_debug_log("[refuel] Fuel at %d%% (threshold: %d%%), buying fuel", fuel_percent, threshold)
        send("buy fuel", false)
    else
        f2t_debug_log("[refuel] Fuel at %d%% (threshold: %d%%), no refuel needed", fuel_percent, threshold)
    end
end

-- Register the GMCP event handler
if F2T_REFUEL_HANDLER_ID then
    killAnonymousEventHandler(F2T_REFUEL_HANDLER_ID)
end
F2T_REFUEL_HANDLER_ID = registerAnonymousEventHandler("gmcp.room.info", "f2t_refuel_on_room_change")

f2t_debug_log("[refuel] GMCP handler registered")
