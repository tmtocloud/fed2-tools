-- @patterns:
--   - pattern: ^This exchange isn't currently buying .+\.$
--     type: regex

-- Detect when exchange is not buying the commodity (or doesn't need more)
f2t_bulk_sell_error("Exchange is not buying this commodity (or doesn't need more)")
