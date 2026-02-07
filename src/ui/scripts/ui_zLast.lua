-- Run on every update to GMCP room info
function ui_on_gmcp_room_info()
    local exits = {}

    -- get all the gmcp room exits and add them to valid exits
    for exit, _ in pairs(gmcp.room.info.exits) do
        table.insert(exits, exit:lower())
    end

    -- Detect shuttlepad or orbit and add board to valid exits
    if f2t_has_value(gmcp.room.info.flags, "shuttlepad") or f2t_has_value(gmcp.room.info.flags, "orbit") or gmcp.room.info.orbit then table.insert(exits, "board") end

    for dir, dirData in pairs(UI.movement.directions) do
        if f2t_has_value(exits, dir) then
            dirData.button:setStyleSheet(UI.style.button_css)
            dirData.button:setClickCallback(dirData.action)
        else
            dirData.button:setStyleSheet(UI.style.disabled_button_css)
            dirData.button:setClickCallback(function() end)
        end
    end

    -- grey out buy fuel if in space
    if f2t_has_value(gmcp.room.info.flags, "space") then
        UI.button_buy_fuel:setStyleSheet(UI.style.disabled_button_css)
        UI.button_buy_fuel:setClickCallback(function() end)
    else
        UI.button_buy_fuel:setStyleSheet(UI.style.button_css)
        UI.button_buy_fuel:setClickCallback("ui_buy_fuel")
    end
end

function ui_update_for_rank()
    if f2t_is_rank_or_above("Commander") then
        if not f2t_has_value(UI.tab_bottom_right.tabs, "Hauling") then
            UI.tab_bottom_right:addTab("Hauling", 2)
        end

        UI.button_status:show()
        UI.button_buy_fuel:show()
    else
        UI.tab_bottom_right:removeTab("Hauling")
        UI.button_status:hide()
        UI.button_buy_fuel:hide()
    end

    -- Trading: only rank 4+
    if f2t_is_rank_or_above("Merchant") then
        if not f2t_has_value(UI.tab_bottom_right.tabs, "Trading") then
            UI.tab_bottom_right:addTab("Trading", 3)
        end
    else
        UI.tab_bottom_right:removeTab("Trading")
    end
end

function ui_build()
    ui_create_containers()
    ui_build_tabs()
    ui_build_tab_content()
    ui_build_header()
    ui_build_quick_buttons()
    ui_build_movement()
    ui_hauling()
    ui_trading()
    ui_commodities()
    ui_update_for_rank()
    ui_update_header()

    f2t_debug_log("[ui] ui_build finished")
end

function ui_event_register()
    f2t_ui_register_event("AdjustableContainerRepositionFinish", "ui_on_container_reposition")
    f2t_ui_register_event("sysWindowResizeEvent"               , "ui_on_window_resize")
    f2t_ui_register_event("gmcp.char"                          , "ui_update_header")
    f2t_ui_register_event("gmcp.room.info"                     , "ui_on_gmcp_room_info")
    f2t_ui_register_event("gmcp.char.ship.cargo"               , "ui_cargo")
    f2t_ui_register_event("gmcp.comm.com"                      , "ui_echo_com")
    f2t_ui_register_event("gmcp.comm.tell"                     , "ui_echo_tell")
    f2t_ui_register_event("gmcp.comm.say"                      , "ui_echo_say")

    f2t_debug_log("[ui] event handlers registered")
end

-- If UI is enabled, kick everything off
if F2T_UI_STATE.enabled then
    if not ui_built then 
        ui_build()
        ui_built = true
    end
    if not ui_evented then 
        ui_event_register()
        ui_evented = true
    end
end
