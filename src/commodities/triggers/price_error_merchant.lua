-- @patterns:
--   - pattern: ^You need to be at least a merchant to use the exchange!
--     type: substring

-- Handle error when player doesn't have merchant rank yet
if F2T_PRICE_CAPTURE_ACTIVE then
    deleteLine()  -- Hide game error message only if we were capturing
    F2T_PRICE_CAPTURE_ACTIVE = false
    F2T_PRICE_CAPTURE_DATA = {}
    cecho("\n<red>[commodities]<reset> You need merchant rank to check commodity prices\n")
    f2t_debug_log("[commodities] Price check failed: merchant rank required")
end
