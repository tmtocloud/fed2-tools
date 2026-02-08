-- @patterns:
--   - pattern: ^I'm afraid you can't sell that at the moment\.$
--     type: regex

-- Detect invalid commodity or no cargo to sell
f2t_bulk_sell_error("Cannot sell that commodity (invalid or out of stock)")
