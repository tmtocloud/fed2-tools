-- @patterns:
--   - pattern: ^This exchange isn't currently selling .+\.$
--     type: regex

-- Detect when exchange is not selling the commodity (or ran out)
f2t_bulk_buy_error("Exchange is not selling this commodity (or ran out)")
