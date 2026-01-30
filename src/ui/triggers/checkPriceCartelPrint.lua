-- @patterns:
--   - pattern: ^$
--     type: regex

UI.trading = UI.trading or {}

if not UI.trading.last_line_was_price or #UI.trading.data == 0 then 
  UI.trading.last_line_was_price = false
  return 
end

UI.trading.last_line_was_price = false

-- If we're in profit search mode, process differently
if UI.trading.profit_search and UI.trading.profit_search.active then
  ui_process_profit_search_results()
  UI.trading.data = {}
  deleteLine()
  return
end

local function rpad(str, len)
  str = tostring(str)
  local pad = len - #str
  if pad > 0 then
    return str .. string.rep(" ", pad)
  end
  return str:sub(1, len)
end

-- 1. PRE-CALCULATE BEST PRICES
local best_buy_price  = math.huge
local best_sell_price = -1

for _, item in ipairs(UI.trading.data) do
  if item.action == "selling" then -- Station sells, we BUY
    if item.price < best_buy_price then best_buy_price = item.price end
  elseif item.action == "buying" then -- Station buys, we SELL
    if item.price > best_sell_price then best_sell_price = item.price end
  end
end

-- Sort by price
table.sort(UI.trading.data, function(a, b)
  return a.price < b.price
end)

-- Display header
UI.trading_window:cecho("<white>System    Planet        Action  Qty   Price\n")
UI.trading_window:cecho("<white>──────────────────────────────────────────\n")

-- Display each entry
for _, item in ipairs(UI.trading.data) do
  -- Column A: Combined action + command
  local action_button

  if item.action == "buying" then
    action_button = "<green>[SELL]<reset>"
  else
    action_button = "<yellow>[BUY]<reset> "
  end
  
  UI.trading_window:cechoLink(rpad(item.system, 9),function() send("j " .. item.system) end,"Jump to: " .. item.system,true)
  UI.trading_window:cecho(" ")
  
  -- Clickable planet name (truncated to 13 chars)
  local planet_display = rpad(item.planet:sub(1, 13), 13)

  UI.trading_window:cechoLink(
    "<ansiCyan>" .. planet_display .. "<reset>",
    function() send("whereis " .. item.planet) end,
    item.planet,  -- Full name in tooltip
    true
  )
  
  UI.trading_window:cecho(" ")
  
  -- Clickable action button
  local cmd = (item.action == "buying") and "sell " or "buy "
  UI.trading_window:cechoLink(
    action_button,
    function() send(cmd .. UI.trading.current_commodity) end,
    cmd .. UI.trading.current_commodity,
    true
  )
  
  UI.trading_window:cecho(" " .. rpad(item.quantity, 5) .. " ")
  -- Highlight the price in green if it's the best price point
  local price_string = rpad(item.price .. "ig", 6)

  if (item.action == "selling" and item.price == best_buy_price) or 
     (item.action == "buying" and item.price == best_sell_price) then
    UI.trading_window:cecho("<green>" .. price_string .. "<reset>\n")
  else
    UI.trading_window:cecho("<white>" .. price_string .. "<reset>\n")
  end
end

-- 3. FOOTER WITH PROFIT CALCULATION
local profit_message = ""
if best_buy_price ~= math.huge and best_sell_price ~= -1 then
  local delta = best_sell_price - best_buy_price
  if delta > 0 then
    profit_message = string.format(" | <green>Best Profit: %dig/ton<reset>", delta)
  else
    profit_message = " | <red>No Profit Delta<reset>"
  end
end

UI.trading_window:cecho("\n<white>" .. #UI.trading.data .. " exchanges" .. profit_message .. "\n")