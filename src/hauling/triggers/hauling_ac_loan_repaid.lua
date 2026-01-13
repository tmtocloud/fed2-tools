-- @patterns:
--   - pattern: Your loan has been cleared!
--     type: substring

-- Loan successfully repaid - log for debug purposes

-- Only process if hauling is active
if not (F2T_HAULING_STATE and F2T_HAULING_STATE.active) then
    return
end

f2t_debug_log("[hauling/ac] Loan repayment confirmed by game")

-- The deliver phase already handles transition after repay timer,
-- so no additional action needed here. This trigger is just for confirmation.
