-- Build quick button cluster (in top-right corner)
function ui_build_quick_buttons()
    local button_width  = 35
    local button_height = 25
    local button_gap    = 5

    ------------- Score Button ---------------------------------
    UI.button_score = Geyser.Label:new(
        {
            name    = "UI.button_score",
            x       = 5,
            y       = 5,
            width   = button_width,
            height  = button_height,
            message = "<center>SC</center>"
        },
        UI.top_right_frame
    )
    UI.button_score:setStyleSheet(UI.style.button_css)
    UI.button_score:setClickCallback("ui_score")
    UI.button_score:setToolTip("score")

    ------------- Status Button --------------------------------
    UI.button_status = Geyser.Label:new(
        {
            name    = "UI.button_status",
            x       = button_width + button_gap + 5,
            y       = 5,
            width   = button_width,
            height  = button_height,
            message = "<center>ST</center>"
        },
        UI.top_right_frame
    )
    UI.button_status:setStyleSheet(UI.style.button_css)
    UI.button_status:setClickCallback("ui_status")
    UI.button_status:setToolTip("status")

    ------------- Buy Fuel Button ------------------------------
    UI.button_buy_fuel = Geyser.Label:new(
        {
            name    = "UI.button_buy_fuel",
            x       = 5,
            y       = button_height + button_gap + 5,
            width   = (button_width * 2) + button_gap,
            height  = button_height,
            message = "<center>Buy Fuel</center>"
        },
        UI.top_right_frame
    )
    UI.button_buy_fuel:setStyleSheet(UI.style.button_css)
    UI.button_buy_fuel:setClickCallback("ui_buy_fuel")
end

function ui_score()
    send("score", false)
end

function ui_status()
    send("status", false)
end

function ui_buy_fuel()
    send("buy fuel", false)
end
