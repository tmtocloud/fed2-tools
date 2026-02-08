-- @patterns:
--   - pattern: exchange - all products:
--     type: substring

if f2t_po.phase == "capturing_exchange" then
    deleteLine()
    f2t_po_capture_reset_timer()
    f2t_debug_log("[po] Exchange header detected")
end
