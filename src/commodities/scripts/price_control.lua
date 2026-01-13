-- Control functions for checking commodity prices
-- Handles sending commands and managing capture state

-- Start a price check for a single commodity
function f2t_price_check_commodity(commodity, callback)
    -- Normalize commodity name (lowercase)
    commodity = string.lower(commodity)

    f2t_debug_log(string.format("[commodities] Starting price check for: %s", commodity))

    -- Set up capture state
    F2T_PRICE_CAPTURE_ACTIVE = false  -- Will be set to true by start trigger
    F2T_PRICE_CAPTURE_DATA = {}
    F2T_PRICE_CURRENT_COMMODITY = commodity
    F2T_PRICE_CALLBACK = callback

    -- Send the game command (false = don't echo to screen)
    send(string.format("check price %s cartel", commodity), false)
end

-- Show price analysis for a single commodity
function f2t_price_show(commodity)
    f2t_price_check_commodity(commodity, nil)
end

f2t_debug_log("[commodities] Price control loaded")
