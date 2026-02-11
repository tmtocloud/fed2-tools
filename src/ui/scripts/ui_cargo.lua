function ui_toggle_cargo_display()
    -- Don't toggle if there's no cargo
    local ship  = gmcp.char and gmcp.char.ship
    local cargo = ship and ship.cargo

    if not cargo or not next(cargo) then
        return  -- Do nothing when no cargo exists
    end

    if UI.cargo_display_visible then
        UI.cargo_manually_hidden = true
        ui_hide_cargo_display()
    else
        UI.cargo_manually_hidden = false
        ui_show_cargo_display()
    end
end

function ui_show_cargo_display()
    if not UI.cargo_dropdown or not UI.cargo_window then return end

    UI.cargo_display_visible = true

    -- Show gap filler first - position it between console and top_right_frame
    if UI.cargo_gap_filler then
        UI.cargo_gap_filler:show()
        UI.cargo_gap_filler:raise()  -- Above console
    end

    -- Show cargo dropdown and window - above scrollbar
    UI.cargo_dropdown:show()
    UI.cargo_dropdown:raise()
    UI.cargo_window:show()

    -- Ensure top_right_frame is above gap_filler
    if UI.top_right_frame then
        UI.top_right_frame:raise()
    end

    -- Update display after showing
    ui_update_cargo_display()
end

function ui_hide_cargo_display()
    if not UI.cargo_dropdown or not UI.cargo_window then return end

    UI.cargo_display_visible = false

    -- Hide cargo window and dropdown
    UI.cargo_window:hide()
    UI.cargo_dropdown:hide()

    if UI.cargo_gap_filler then
        UI.cargo_gap_filler:hide()
    end

    -- Clean up buttons when hiding
    if UI.cargo_buttons then
        for _, button_set in ipairs(UI.cargo_buttons) do
            if button_set.check_price then 
                button_set.check_price:hide()
            end
            if button_set.sell then 
                button_set.sell:hide()
            end
            if button_set.deliver then 
                button_set.deliver:hide()
            end
        end
    end
end

function ui_update_cargo_display()
    if not UI.cargo_window then return end

    local ship  = gmcp.char and gmcp.char.ship
    local cargo = ship and ship.cargo

    -- Clean up old buttons if they exist
    if UI.cargo_buttons then
        for _, button_set in ipairs(UI.cargo_buttons) do
            if button_set.check_price then button_set.check_price:hide() end
            if button_set.sell then button_set.sell:hide() end
            if button_set.deliver then button_set.deliver:hide() end
        end
    end
    UI.cargo_buttons = {}

    UI.cargo_window:clear()

    -- Count cargo entries
    local cargo_count = 0
    for _ in pairs(cargo) do
        cargo_count = cargo_count + 1
    end

    -- Calculate dynamic height
    local entry_height      = 65
    local header_height     = 10
    local footer_height     = 25
    local calculated_height = header_height + (cargo_count * entry_height) + footer_height
    local max_height        = header_height + (7 * entry_height) + footer_height
    local final_height      = math.min(calculated_height, max_height)

    -- Resize the container
    UI.cargo_dropdown:resize(nil, final_height)

    -- Count total tons
    local total_tons = cargo_count * 75

    local y_position     = header_height
    local button_height  = 20
    local button_width   = 70
    local button_spacing = 2

    local entry_num = 0
    for key, value in pairs(cargo) do
        entry_num = entry_num + 1
        local is_delivery = value.destination ~= nil

        -- Commodity name in cyan
        UI.cargo_window:cecho("<ansiCyan><b>" .. (value.commodity or "Unknown") .. "</b><reset>")

        if is_delivery then
            UI.cargo_window:cecho(" → <yellow>" .. (value.destination or "Unknown") .. "<reset>\n")
        else
            UI.cargo_window:cecho("\n")
        end

        -- Line 2: Price/profit info or origin
        if not is_delivery then
            local cost = tonumber(value.cost) or 0
            local base = tonumber(value.base) or 0
            local diff = base - cost

            UI.cargo_window:cecho("<white><b>" .. cost .. "</b>ig<reset> ")
            UI.cargo_window:cecho("(base: <dim_grey>" .. base .. "ig<reset>) ")

            -- Profit/loss
            if diff > 0 then
                UI.cargo_window:cecho("<green>+<b>" .. diff .. "</b>ig<reset>")
            elseif diff < 0 then
                UI.cargo_window:cecho("<red><b>" .. diff .. "</b>ig<reset>")
            else
                UI.cargo_window:cecho("<white>0ig<reset>")
            end

            UI.cargo_window:cecho("\n<yellow>" .. (value.origin or "Unknown") .. "<reset>\n")
        else
            UI.cargo_window:cecho("\n")
        end

        -- Create buttons positioned on the right side using NEGATIVE x values
        local buttons = {}

        if is_delivery then
            -- Single Deliver button
            buttons.deliver = Geyser.Label:new({
                name    = "cargo_deliver_" .. key,
                x       = -button_width - 5,  -- NEGATIVE to align from right
                y       = y_position,
                width   = button_width,
                height  = button_height,
                message = "<center>Deliver</center>"
            }, UI.cargo_dropdown)
            buttons.deliver:setStyleSheet(UI.style.button_css)
            buttons.deliver:setClickCallback(function()
                send("deliver", false)
            end)
        else
            -- Two buttons: Check Price and Sell
            buttons.check_price = Geyser.Label:new({
                name    = "cargo_check_" .. key,
                x       = -(button_width * 2) - button_spacing - 5,  -- NEGATIVE - rightmost
                y       = y_position,
                width   = button_width,
                height  = button_height,
                message = "<center>Check Price</center>"
            }, UI.cargo_dropdown)
            buttons.check_price:setStyleSheet(UI.style.button_css)
            buttons.check_price:setClickCallback(function()
                send("c price " .. (value.commodity or ""):lower(), false)
            end)

            buttons.sell = Geyser.Label:new({
                name    = "cargo_sell_" .. key,
                x       = -button_width - 5,  -- NEGATIVE - next to Check Price
                y       = y_position,
                width   = button_width,
                height  = button_height,
                message = "<center>Sell</center>"
            }, UI.cargo_dropdown)
            buttons.sell:setStyleSheet(UI.style.button_css)
            buttons.sell:setClickCallback(function()
                send("sell " .. (value.commodity or ""):lower(), false)
            end)
        end

        table.insert(UI.cargo_buttons, buttons)

        -- Move to next entry position
        y_position = y_position + entry_height - 15

        -- Add separator line between entries (but not after last one)
        if entry_num < cargo_count then
            UI.cargo_window:cecho("<dim_grey>───────────────────<reset>\n")
        else
            UI.cargo_window:echo("\n")
        end
    end

    -- Footer
    UI.cargo_window:cecho("<dim_grey>─────────────────────────<reset>\n")
    UI.cargo_window:cecho("<dim_grey>Total: " .. total_tons .. " tons<reset>")
end
