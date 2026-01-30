-- @patterns:
--   - pattern: ^([\w\s]+): ([\w\s]+) is (buying|selling) (\d+) tons at (\d+)ig/ton$
--     type: regex

local system   = matches[2]
local planet   = matches[3]
local action   = matches[4]
local quantity = matches[5]
local price    = matches[6]

-- Store the data
table.insert(UI.trading.data, {
  system   = system,
  planet   = planet,
  action   = action,
  quantity = tonumber(quantity),
  price    = tonumber(price)
})

UI.trading.last_line_was_price = true  -- Flag for blank line trigger
deleteLine()