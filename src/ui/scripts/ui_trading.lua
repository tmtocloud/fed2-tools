function ui_trading()
  ------------- Trading Commodity Dropdown ---------------
  ui_trading_drop_down_button = Geyser.Label:new(
    {
      name   = "ui_trading_drop_down_button",
      message = "<center>Select Commodity ▼</center>",
    },
    ui_trading_button_bar
  )
  ui_trading_drop_down_button:setStyleSheet(ui_style.button_css)
  ui_trading_drop_down_button:setClickCallback("ui_show_trading_drop_down")

  ui_check_price_button = Geyser.Label:new(
    {
      name    = "ui_check_price_button",
      width   = "30%",
      height  = "100%",
      message = "<center>CP</center>",
    },
    ui_trading_button_bar
  )
  ui_check_price_button:setStyleSheet(ui_style.button_css)
  ui_check_price_button:setClickCallback("ui_check_price")

  ui_cartel_toggle_button = Geyser.Label:new(
    {
      name    = "ui_cartel_toggle_button",
      message = "<center>☑ Cartel</center>",
    },
    ui_trading_button_bar
  )
  ui_cartel_toggle_button:setStyleSheet(ui_style.button_css)
  ui_cartel_toggle_button:setClickCallback("ui_toggle_cartel")

  -- Initialize trading state
  ui_trading_data = {
    selected_commodity = nil,
    use_cartel         = true,
    -- Initialize profit search state
    profit_search      = {
      active              = false,
      commodities_to_search = {},
      current_index        = 1,
      results             = {},
      best_commodity       = nil,
      best_profit          = -math.huge,
    }
  }

  -- Best Profit button
  ui_best_profit_button = Geyser.Label:new(
    {
      name    = "ui_best_profit_button",
      message = "<center>Find Best</center>",
    },
    ui_trading_button_bar
  )
  ui_best_profit_button:setStyleSheet(ui_style.button_css)
  ui_best_profit_button:setClickCallback("ui_find_best_profit")
  
  -- Check to see if user has cartel price checking
  ui_check_cartel_status()
end

-- Responsible for formatting and displaying the commodity dropdown
function ui_show_trading_drop_down()
  if ui_commodity_popup then
    ui_commodity_popup:hide()
    ui_commodity_popup = nil
    return
  end
  
  ui_commodity_popup = Geyser.Container:new(
    {
      name   = "ui_commodity_popup",
      x      = "10%",
      y      = 30,
      width  = 220,
      height = 400,
    },
    ui_tradingContainer
  )
  
  -- Use MiniConsole for scrollable list instead
  local commodityBox = Geyser.ScrollBox:new(
    {
      name            = "commodityBox",
      x               = 0,
      y               = 0,
      width           = "100%",
      height          = "100%",
      fontSize        = 10,
      backgroundColor = "black",
    },
    ui_commodity_popup
  )

  local row_height = 24
  local y_offset   = 0
  local commods    = {}
  
  local commodity_list = ui_commodities()

  for i, item in ipairs(commodity_list) do
    local labelName = "commod" .. i
  
    commods[i] = Geyser.Label:new(
      {
        name    = labelName,
        x       = 0,
        y       = y_offset,
        width   = "100%",
        height  = row_height,
        message = "<center>" .. item.name .. " (" .. item.basePrice .. ")</center>",
      },
      commodityBox
    )
  
    commods[i]:setStyleSheet(ui_style.button_css)
  
    commods[i]:setClickCallback(
      function()
        ui_trading_data.selected_commodity = item.name
        ui_trading_drop_down_button:echo("<center>" .. item.name .. " ▼</center>")
        ui_commodity_popup:hide()
        ui_commodity_popup = nil
      end
    )
  
    y_offset = y_offset + row_height
  end

  ui_commodity_popup:show()
  ui_commodity_popup:raise()
end

function ui_toggle_cartel()
  ui_trading_data.use_cartel = not ui_trading_data.use_cartel

  local checkbox = ui_trading_data.use_cartel and "☑" or "☐"

  ui_cartel_toggle_button:echo("<center>" .. checkbox .. " Cartel</center>")
end

function ui_check_price()
  if not ui_trading_data.selected_commodity then
    cecho("\n<red>Please select a commodity first!\n")
    return
  end

  local cmd = "c price " .. ui_trading_data.selected_commodity:lower()

  if ui_trading_data.use_cartel then
    ui_trading                          = ui_trading or {}
    ui_trading_data.current_commodity   = ui_trading_data.selected_commodity:lower()
    ui_trading_data.data                = {}
    ui_trading_data.last_line_was_price = false

    ui_trading_window:clear()

    cmd = cmd .. " cartel"
  end

  send(cmd)
end

function ui_find_best_profit()
  -- Clear previous results
  ui_trading_data.profit_search = {
    active                = true,
    commodities_to_search = {},
    current_index         = 1,
    results               = {},
    best_commodity        = nil,
    best_profit           = -math.huge,
    total_count           = 0
  }
  
  -- Build list of all commodities
  for _, commodity, in ipairs(ui_commodities()) do
    table.insert(ui_trading_data.profit_search.commodities_to_search, commodity.name:lower())
  end

  table.sort(ui_trading_data.profit_search.commodities_to_search, function(a, b) return a < b end)
  
  ui_trading_data.profit_search.total_count = #ui_trading_data.profit_search.commodities_to_search
  
  ui_trading_window:clear()
  ui_trading_window:cecho("<yellow>Searching " .. #ui_trading_data.profit_search.commodities_to_search .. " commodities for best profit...\n\n")
  
   -- Create progress bar anchored to bottom of main window, between left and right frames
  if not ui_profit_progress_bar then
    ui_profit_progress_bar = Geyser.Gauge:new(
      {
        name   = "ui_profit_progress_bar",
        x      = "16.5%",
        y      = "-30px",
        width  = "61%",
        height = "25px"
      }
    )

    ui_profit_progress_bar:setFgColor("red")
    ui_profit_progress_bar:setColor(40, 40, 40)
  end
  
  ui_profit_progress_bar:setValue(1, ui_trading_data.profit_search.total_count,"Scanning commodities... 1/" .. ui_trading_data.profit_search.total_count)

  ui_profit_progress_bar:show()
  ui_profit_progress_bar:raise()

  -- Start searching
  ui_search_next_commodity()
end

function ui_search_next_commodity()
  if not ui_trading_data.profit_search.active then return end
  
  local commodity = ui_trading_data.profit_search.commodities_to_search[ui_trading_data.profit_search.current_index]
  
  if not commodity then
    -- Done searching, display results
    ui_display_best_profit()
    return
  end
  
  -- Clear commerce data for this search
  ui_trading_data.data = {}
  ui_trading_data.current_commodity = commodity
  ui_trading_data.last_line_was_price = false
  
  -- Send the search command
  send("c price " .. commodity:lower() .. " cartel", false)
end

function ui_process_profit_search_results()
  -- Calculate profit for current commodity
  local best_buy = math.huge
  local best_sell = -1
  
  for _, item in ipairs(ui_trading_data.data) do
    if item.action == "selling" then
      if item.price < best_buy then best_buy = item.price end
    elseif item.action == "buying" then
      if item.price > best_sell then best_sell = item.price end
    end
  end
  
  local profit = (best_buy ~= math.huge and best_sell ~= -1) and (best_sell - best_buy) or -math.huge
  
  local commodity = ui_trading_data.current_commodity
  
  -- Store result
  table.insert(
    ui_trading_data.profit_search.results,
    {
      commodity = commodity,
      profit    = profit,
      best_buy  = best_buy,
      best_sell = best_sell
    }
  )
  
  -- Update if this is the best
  if profit > ui_trading_data.profit_search.best_profit then
    ui_trading_data.profit_search.best_profit    = profit
    ui_trading_data.profit_search.best_commodity = commodity
  end
  
  -- Update progress bar BEFORE incrementing current_index
  if ui_profit_progress_bar then
    local current = ui_trading_data.profit_search.current_index
    local total   = ui_trading_data.profit_search.total_count
    
    ui_profit_progress_bar:setValue(current, total,"Scanning commodities... " .. current .. "/" .. total)
  end

  -- Update display
  ui_trading_window:cecho(string.format(
    "<%s>%-20s: %+4dig/ton<reset>\n",
    profit > 0 and "green" or "red",
    commodity,
    profit
  ))
  
  -- Move to next
  ui_trading_data.profit_search.current_index = ui_trading_data.profit_search.current_index + 1
  
  -- Small delay before next search to avoid flooding
  tempTimer(0.5, function() ui_search_next_commodity() end)
end

function ui_display_best_profit()
  ui_trading_data.profit_search.active = false
  ui_profit_progress_bar:hide()

  -- Sort results by profit
  table.sort(ui_trading_data.profit_search.results, function(a, b)
    return a.profit > b.profit
  end)
  
  ui_trading_window:cecho("\n<white>==========================================\n")
  ui_trading_window:cecho("<yellow>BEST PROFIT: <reset>")
  
  if ui_trading_data.profit_search.best_commodity then
    local best = ui_trading_data.profit_search.results[1]

    ui_trading_window:cechoLink(
      "<green><b>" .. best.commodity .. "</b><reset>",
      function()
        ui_trading_data.selected_commodity = best.commodity
        ui_trading_drop_down_button:echo("<center>" .. best.commodity .. " ▼</center>")
        send("c price " .. best.commodity:lower() .. " cartel")
      end,
      "Search " .. best.commodity,
      true
    )
    ui_trading_window:cecho(string.format(
      " | <green>%dig/ton profit<reset>\n",
      best.profit
    ))
    ui_trading_window:cecho(string.format(
      "Buy at %dig, Sell at %dig\n",
      best.best_buy,
      best.best_sell
    ))
    
    -- Auto-select it
    ui_trading_data.selected_commodity = best.commodity
    ui_trading_drop_down_button:echo("<center>" .. best.commodity .. " ▼</center>")
  else
    ui_trading_window:cecho("<red>No profitable commodities found<reset>\n")
  end
  
  ui_trading_window:cecho("<white>==========================================\n\n")
  ui_trading_window:cecho("<dim_grey>Click commodity name to view full cartel prices<reset>\n")
end

-- Function to check cartel status
function ui_check_cartel_status()
  ui_trading_data.cartel.checking = true
  send("inventory", false)
end

-- Function to update UI based on cartel status
function ui_updateCartelUI()
  if ui_trading_data.cartel.active then
    -- Show cartel-related buttons
    ui_cartel_toggle_button:show()
    ui_best_profit_button:show()
    
    -- Add tooltip with days remaining
    local tooltip = string.format("Cartel Access Active (%d days remaining)", ui_trading_data.cartel.daysRemaining)
    ui_cartel_toggle_button:setToolTip(tooltip)
    ui_best_profit_button:setToolTip(tooltip)
  else
    -- Hide cartel-related buttons
    ui_cartel_toggle_button:hide()
    ui_best_profit_button:hide()
    
    -- Ensure cartel mode is off
    ui_trading_data.use_cartel = false
    
    -- Stop any active profit search
    if ui_trading_data.profit_search and ui_trading_data.profit_search.active then
      ui_trading_data.profit_search.active = false
      if ui_profit_progress_bar then
        ui_profit_progress_bar:hide()
      end
    end
  end
end