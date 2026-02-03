-- Populate the top status frame with labels
function ui_build_header()
    -- build the hbox the stat labels will go into
    UI.header = Geyser.HBox:new(
        {
            name   = "UI.header",
            x      = 0,
            y      = 0,
            width  = "100%",
            height = "100%",
        },
        UI.top_frame
    )

    --create the six labels inside the box: rank, hold space, fuel, stamina, groats, slithies
    for i = 1, 6 do
        UI["Label"..i] = Geyser.Label:new(
            {
                name = "UI.Label"..i,
            },
            UI.header
        )
    end

    UI.Label1:setStyleSheet(UI.style.label_css)
    UI.Label1:setFontSize(12)

    UI.Label2:setStyleSheet(UI.style.label_css)
    UI.Label2:setFontSize(12)

    UI.Label3:setStyleSheet(UI.style.label_css)
    UI.Label3:setFontSize(12)

    UI.Label4:setStyleSheet(UI.style.label_css)
    UI.Label4:setFontSize(12)

    UI.Label5:setStyleSheet(UI.style.label_css)
    UI.Label5:setFontSize(12)

    UI.Label6:setStyleSheet(UI.style.label_css)
    UI.Label6:setFontSize(12)
end

--Tracking: Rank, Cargo Space, Fuel, Stamina, Money, Slithies
function ui_update_header()
    local vitals = (gmcp.char and gmcp.char.vitals) or {}
    local ship   = (gmcp.char and gmcp.char.ship) or {}

    local rank      = vitals.rank or "-"
    local hold_cur   = (ship.hold and ship.hold.cur) or "-"
    local hold_max   = (ship.hold and ship.hold.max) or "-"
    local fuel_cur   = (ship.fuel and ship.fuel.cur) or "-"
    local fuel_max   = (ship.fuel and ship.fuel.max) or "-"
    local stam_cur   = (vitals.stamina and vitals.stamina.cur) or "-"
    local stam_max   = (vitals.stamina and vitals.stamina.max) or "-"
    local cash      = ui_convert_value(vitals.cash) or "-"
    local slith     = vitals.slithies or "-"
    local groats_max = ui_convert_value(UI.magic_cash_numbers[rank]) or "-"

    UI.Label1:echo("Rank: " .. [[<b>]] .. rank .. [[</b>]])
    if tonumber(hold_cur) then UI.Label2:echo("Hold: " ..    [[<b><font color=]] .. ui_color_percent(hold_cur,hold_max)..[[>]] .. hold_cur .. [[</font></b>]] .. "/" .. hold_max) end
    if tonumber(fuel_cur) then UI.Label3:echo("Fuel: " ..    [[<b><font color=]] .. ui_color_percent(fuel_cur,fuel_max)..[[>]] .. fuel_cur .. [[</font></b>]] .. "/" .. fuel_max) end
    if tonumber(stam_cur) then UI.Label4:echo("Stamina: " .. [[<b><font color=]] .. ui_color_percent(stam_cur,stam_max)..[[>]] .. stam_cur .. [[</font></b>]] .. "/" .. stam_max) end

    if groats_max == "-" then
        UI.Label5:echo("Groats: " .. [[<b>]] .. cash  .. [[</b>]])
    else
        UI.Label5:echo("Groats: " .. [[<b>]] .. cash  .. [[</b>]] .. "/" .. groats_max)
    end

    UI.Label6:echo("Slithies: " .. [[<b>]] .. slith .. [[</b>]])

    ui_update_tabs_for_rank()
end

-- Register the GMCP event handler
if F2T_CHAR_HANDLER_ID then
    killAnonymousEventHandler(F2T_CHAR_HANDLER_ID)
end
F2T_CHAR_HANDLER_ID = registerAnonymousEventHandler("gmcp.char", "ui_update_header")

f2t_debug_log("[ui] GMCP Char handler registered")