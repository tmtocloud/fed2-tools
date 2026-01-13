-- @patterns:
--   - pattern: There's no one here expecting anything from you\.
--     type: substring

-- Handle error when dropoff command is used in wrong room

if F2T_HAULING_STATE and F2T_HAULING_STATE.active and F2T_HAULING_STATE.current_phase == "akaturi_delivering" then
    deleteLine()
    cecho("\n<yellow>[hauling]<reset> Wrong delivery location, trying next match...\n")
    F2T_HAULING_STATE.akaturi_delivery_error = true
    f2t_debug_log("[hauling/akaturi] Delivery failed - wrong room")

    -- Re-run deliver phase to try next match
    tempTimer(0.5, function()
        if F2T_HAULING_STATE.active and not F2T_HAULING_STATE.paused and
           F2T_HAULING_STATE.current_phase == "akaturi_delivering" then
            f2t_hauling_phase_akaturi_deliver()
        end
    end)
end
