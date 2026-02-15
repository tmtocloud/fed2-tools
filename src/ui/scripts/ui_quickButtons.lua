-- Build quick button cluster (in top-right corner)
function ui_build_quick_buttons()
    -- Use percentages for responsiveness
    local button_width_pct  = 50   -- % of parent width
    local button_height_pct = 50   -- % of parent height
    local button_gap_pct    = 2    -- % of parent width
    local margin_pct        = 2    -- % margins
    
    ------------- Score Button ---------------------------------
    UI.button_score = Geyser.Label:new(
        {
            name    = "UI.button_score",
            x       = margin_pct .. "%",
            y       = margin_pct .. "%",
            width   = button_width_pct - margin_pct .. "%",
            height  = button_height_pct - margin_pct .. "%",
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
            x       = (margin_pct + button_width_pct + button_gap_pct) .. "%",
            y       = margin_pct .. "%",
            width   = button_width_pct - button_gap_pct - margin_pct .. "%",
            height  = button_height_pct - margin_pct .. "%",
            message = "<center>ST</center>"
        },
        UI.top_right_frame
    )
    UI.button_status:setStyleSheet(UI.style.button_css)
    UI.button_status:setClickCallback("ui_status")
    UI.button_status:setToolTip("status")

    -- Travel button
    UI.button_travel = Geyser.Label:new(
        {
            name   = "UI.button_travel",
            x       = margin_pct .. "%",
            y       = (margin_pct + button_height_pct + button_gap_pct) .. "%",
            width   = (button_width_pct * 2) - margin_pct .. "%",
            height  = button_height_pct - margin_pct .. "%",
        },
        UI.top_right_frame
    )

    UI.button_travel:setStyleSheet(UI.style.button_css)
    UI.button_travel:echo("<center>Travel</center>")
    UI.button_travel:setClickCallback("ui_toggle_travel")
end

function ui_score()
    send("score", false)
end

function ui_status()
    send("status", false)
end