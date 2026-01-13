-- @patterns:
--   - pattern: ^requested spot market prices\.$
--     type: regex

-- Continuation of broker message (second line)
-- Only delete if we're actively capturing (automated price check)
if F2T_PRICE_CAPTURE_ACTIVE then
    deleteLine()
    f2t_debug_log("[commodities] Captured continuation line (automated)")
end
