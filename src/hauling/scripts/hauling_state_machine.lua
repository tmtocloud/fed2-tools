-- Hauling State Machine
-- Manages the buy/sell cycle for automated commodity trading

-- Start hauling automation
function f2t_hauling_start()
    if F2T_HAULING_STATE.active then
        cecho("\n<yellow>[hauling]<reset> Hauling already active\n")
        return
    end

    -- Check if cargo hold is empty
    local cargo = gmcp.char and gmcp.char.ship and gmcp.char.ship.cargo
    if cargo and #cargo > 0 then
        cecho(string.format("\n<red>[hauling]<reset> Cargo hold must be empty to start hauling (%d lots currently loaded)\n", #cargo))
        cecho("\n<dim_grey>Use 'bs' to sell all cargo first<reset>\n")
        return
    end

    cecho("\n<green>[hauling]<reset> Starting automated hauling...\n")

    F2T_HAULING_STATE.active = true
    F2T_HAULING_STATE.paused = false
    F2T_HAULING_STATE.stopping = false
    F2T_HAULING_STATE.cycle_count = 0

    -- Set navigation ownership for hauling
    -- Callback handles customs interrupt by requesting auto-resume
    if f2t_map_set_nav_owner then
        f2t_map_set_nav_owner("hauling", function(reason)
            f2t_debug_log("[hauling] Navigation interrupted by %s", reason)
            -- Hauling uses auto-resume - customs handler will resume navigation
            return { auto_resume = true }
        end)
    end

    -- Reset statistics for new session
    F2T_HAULING_STATE.total_cycles = 0
    F2T_HAULING_STATE.session_profit = 0
    F2T_HAULING_STATE.commodity_history = {}

    -- Load margin threshold from settings
    F2T_HAULING_STATE.margin_threshold_pct = f2t_settings_get("hauling", "margin_threshold")

    f2t_debug_log("[hauling] Starting new hauling session (margin threshold: %.0f%%)",
        F2T_HAULING_STATE.margin_threshold_pct)

    -- Cancel any standalone stamina prompt (hauling will handle stamina automatically)
    if f2t_stamina_cancel_standalone_prompt then
        f2t_stamina_cancel_standalone_prompt()
    end

    -- NOTE: Don't start completion timer yet - it will be started when entering buying/selling phase

    -- Detect which hauling mode to use based on rank
    local mode, err = f2t_hauling_detect_mode()

    if not mode then
        -- Mode detection failed
        cecho(string.format("\n<red>[hauling]<reset> %s\n", err or "Cannot determine hauling mode"))
        f2t_hauling_do_stop()
        return
    end

    -- Store mode and display to user
    F2T_HAULING_STATE.mode = mode
    local rank = f2t_get_rank() or "unknown"
    local mode_name = f2t_hauling_get_mode_name(mode)

    cecho(string.format("\n<cyan>[hauling]<reset> Rank: %s - Using %s\n", rank, mode_name))
    f2t_debug_log("[hauling] Mode selected: %s (%s)", mode, mode_name)

    -- Register mode-specific event handlers
    if mode == "ac" then
        F2T_HAULING_STATE.handler_id = f2t_ac_register_handlers()
    elseif mode == "exchange" then
        F2T_HAULING_STATE.handler_id = f2t_exchange_register_handlers()
    elseif mode == "akaturi" then
        F2T_HAULING_STATE.handler_id = f2t_akaturi_register_handlers()
    end

    -- Get starting phase for this mode and transition
    local starting_phase = f2t_hauling_get_starting_phase(mode)

    if not starting_phase then
        cecho(string.format("\n<red>[hauling]<reset> Unknown starting phase for mode: %s\n", mode))
        f2t_hauling_do_stop()
        return
    end

    f2t_hauling_transition(starting_phase)
end

-- Gracefully stop hauling automation (finish current cycle first)
function f2t_hauling_stop()
    if not F2T_HAULING_STATE.active then
        cecho("\n<yellow>[hauling]<reset> Hauling not active\n")
        return
    end

    -- For AC jobs, check if we've accepted a job (even if cargo not yet collected)
    -- We should finish any job that's past the selection phase
    if F2T_HAULING_STATE.mode == "ac" and F2T_HAULING_STATE.ac_job then
        local phase = F2T_HAULING_STATE.current_phase
        -- If we're in a phase where we've committed to a job, finish it
        if phase == "ac_accepting_job" or phase == "ac_collecting" or
           phase == "ac_navigating_to_dest" or phase == "ac_delivering" then
            F2T_HAULING_STATE.stopping = true
            local job = F2T_HAULING_STATE.ac_job

            -- Different message depending on whether we have cargo
            if F2T_HAULING_STATE.ac_cargo_collected then
                cecho(string.format("\n<green>[hauling]<reset> Stopping after delivering cargo (%s to %s)...\n",
                    job.commodity, job.destination))
            else
                cecho(string.format("\n<green>[hauling]<reset> Stopping after completing job %d (%s from %s to %s)...\n",
                    job.number, job.commodity, job.source, job.destination))
            end

            cecho("\n<dim_grey>Use 'haul terminate' to stop immediately<reset>\n")
            f2t_debug_log("[hauling/ac] Graceful stop requested, will finish job %d (phase: %s)",
                job.number, phase)
            return
        end
        -- Otherwise (fetching/selecting phase), we can stop immediately below
    end

    -- For Akaturi contracts, check if we've picked up a package
    if F2T_HAULING_STATE.mode == "akaturi" and F2T_HAULING_STATE.akaturi_contract then
        local phase = F2T_HAULING_STATE.current_phase
        -- If we're in a phase where we've committed to a contract, finish it
        if phase == "akaturi_collecting" or phase == "akaturi_navigating_delivery" or phase == "akaturi_delivering" then
            F2T_HAULING_STATE.stopping = true
            local contract = F2T_HAULING_STATE.akaturi_contract

            -- Different message depending on whether we have package
            if F2T_HAULING_STATE.akaturi_package_collected then
                cecho(string.format("\n<green>[hauling]<reset> Stopping after delivering %s to %s...\n",
                    contract.item or "package", contract.delivery_planet or "destination"))
            else
                cecho(string.format("\n<green>[hauling]<reset> Stopping after completing contract (pickup from %s)...\n",
                    contract.pickup_planet or "unknown"))
            end

            cecho("\n<dim_grey>Use 'haul terminate' to stop immediately<reset>\n")
            f2t_debug_log("[hauling/akaturi] Graceful stop requested, will finish contract (phase: %s)", phase)
            return
        end
        -- Otherwise (getting job/searching/navigating to pickup), we can stop immediately below
    end

    -- For exchange hauling, check if we have cargo in hold
    local cargo = gmcp.char and gmcp.char.ship and gmcp.char.ship.cargo
    if cargo and #cargo > 0 then
        -- Set stopping flag and let current cycle complete
        F2T_HAULING_STATE.stopping = true
        cecho(string.format("\n<green>[hauling]<reset> Stopping after current cycle completes (%d lots in hold)...\n", #cargo))
        cecho("\n<dim_grey>Use 'haul terminate' to stop immediately<reset>\n")
        f2t_debug_log("[hauling] Graceful stop requested, will finish selling %d lots", #cargo)
    else
        -- No cargo/job, stop immediately
        -- Stop any active speedwalk since we're stopping now
        if F2T_SPEEDWALK_ACTIVE then
            f2t_debug_log("[hauling] Stopping speedwalk due to immediate stop")
            f2t_map_speedwalk_stop()
        end
        f2t_hauling_do_stop()
    end
end

-- Terminate hauling automation immediately
function f2t_hauling_terminate()
    if not F2T_HAULING_STATE.active then
        cecho("\n<yellow>[hauling]<reset> Hauling not active\n")
        return
    end

    cecho("\n<yellow>[hauling]<reset> Terminating hauling immediately...\n")
    f2t_debug_log("[hauling] Immediate termination requested")

    -- Stop any active speedwalk
    if F2T_SPEEDWALK_ACTIVE then
        f2t_debug_log("[hauling] Stopping speedwalk due to termination")
        f2t_map_speedwalk_stop()
    end

    f2t_hauling_do_stop()
end

-- Internal function to actually stop hauling (preserves statistics)
function f2t_hauling_do_stop()
    -- Clear navigation ownership
    if f2t_map_clear_nav_owner then
        f2t_map_clear_nav_owner()
    end

    -- Check if we should navigate to safe room
    local use_safe_room = f2t_settings_get("hauling", "use_safe_room")
    local safe_room = f2t_settings_get("shared", "safe_room")

    if use_safe_room and safe_room and safe_room ~= "" then
        cecho(string.format("\n<green>[hauling]<reset> Returning to safe room: <cyan>%s<reset>\n", safe_room))
        f2t_debug_log("[hauling] Navigating to safe room: %s", safe_room)

        f2t_map_navigate(safe_room)

        -- Wait for navigation to complete before showing final stats
        tempTimer(2, function()
            f2t_hauling_finish_stop()
        end)
    else
        -- Safe room disabled or not configured, stop immediately
        f2t_hauling_finish_stop()
    end
end

-- Complete the stop sequence (called after safe room navigation)
function f2t_hauling_finish_stop()
    -- Show final statistics
    if F2T_HAULING_STATE.total_cycles > 0 then
        cecho("\n<green>[hauling]<reset> Final Session Statistics:\n")
        cecho(string.format("  Total Cycles: <cyan>%d<reset>\n", F2T_HAULING_STATE.total_cycles))
        cecho(string.format("  Session Profit: <green>%d ig<reset>\n", F2T_HAULING_STATE.session_profit))

        local avg_profit = math.floor(F2T_HAULING_STATE.session_profit / F2T_HAULING_STATE.total_cycles)
        cecho(string.format("  Avg Profit/Cycle: <cyan>%d ig<reset>\n", avg_profit))
    end

    cecho("\n<green>[hauling]<reset> Hauling automation stopped\n")

    f2t_debug_log("[hauling] Stopped after %d cycles, session profit: %d ig",
        F2T_HAULING_STATE.total_cycles, F2T_HAULING_STATE.session_profit)

    -- Clean up mode-specific event handlers
    if F2T_HAULING_STATE.mode == "ac" and F2T_HAULING_STATE.handler_id then
        f2t_ac_cleanup_handlers(F2T_HAULING_STATE.handler_id)
    elseif F2T_HAULING_STATE.mode == "exchange" and F2T_HAULING_STATE.handler_id then
        f2t_exchange_cleanup_handlers(F2T_HAULING_STATE.handler_id)
    elseif F2T_HAULING_STATE.mode == "akaturi" and F2T_HAULING_STATE.handler_id then
        f2t_akaturi_cleanup_handlers(F2T_HAULING_STATE.handler_id)
    elseif F2T_HAULING_STATE.handler_id then
        -- Generic cleanup for any other mode
        killAnonymousEventHandler(F2T_HAULING_STATE.handler_id)
        f2t_debug_log("[hauling] Cleaned up event handlers for mode: %s", F2T_HAULING_STATE.mode or "unknown")
    end

    -- Note: Stamina monitoring continues running (always-on mode)
    -- It will revert to standalone prompt mode now that hauling is inactive

    -- Cancel any active price all operation
    if f2t_price_cancel_all and f2t_price_cancel_all() then
        f2t_debug_log("[hauling] Cancelled active price all operation")
    end

    -- Clear any active price capture state
    if F2T_PRICE_CAPTURE_ACTIVE then
        F2T_PRICE_CAPTURE_ACTIVE = false
        F2T_PRICE_CAPTURE_DATA = {}
        F2T_PRICE_CURRENT_COMMODITY = nil
        F2T_PRICE_CALLBACK = nil
        f2t_debug_log("[hauling] Cleared active price capture state")
    end

    -- Reset active state (but preserve statistics for status display)
    F2T_HAULING_STATE.active = false
    F2T_HAULING_STATE.paused = false
    F2T_HAULING_STATE.paused_room_id = nil
    F2T_HAULING_STATE.stopping = false
    F2T_HAULING_STATE.mode = nil
    F2T_HAULING_STATE.current_phase = nil
    F2T_HAULING_STATE.handler_id = nil
    F2T_HAULING_STATE.commodity_queue = {}
    F2T_HAULING_STATE.queue_index = 1
    F2T_HAULING_STATE.current_commodity = nil
    F2T_HAULING_STATE.buy_location = nil
    F2T_HAULING_STATE.sell_location = nil
    F2T_HAULING_STATE.expected_profit = 0
    F2T_HAULING_STATE.actual_cost = 0
    F2T_HAULING_STATE.current_commodity_stats = {
        lots_bought = 0,
        total_cost = 0,
        lots_sold = 0,
        total_revenue = 0,
        profit = 0
    }
    F2T_HAULING_STATE.commodity_cycles = 0
    F2T_HAULING_STATE.commodity_total_profit = 0
    F2T_HAULING_STATE.sell_attempts = 0
    F2T_HAULING_STATE.dump_attempts = 0

    -- Clear AC job state
    F2T_HAULING_STATE.ac_job = nil
    F2T_HAULING_STATE.ac_job_taken = false
    F2T_HAULING_STATE.ac_cargo_collected = false
    F2T_HAULING_STATE.ac_cargo_delivered = false
    F2T_HAULING_STATE.ac_collect_error = nil
    F2T_HAULING_STATE.ac_deliver_error = nil
    F2T_HAULING_STATE.ac_collect_sent = false
    F2T_HAULING_STATE.ac_deliver_sent = false
    F2T_HAULING_STATE.ac_deliver_waiting = false
    F2T_HAULING_STATE.ac_50_milestone_shown = false
    F2T_HAULING_STATE.ac_payment_amount = nil

    -- Clear AC capture state
    if F2T_AC_JOB_STATE then
        F2T_AC_JOB_STATE.capturing = false
        F2T_AC_JOB_STATE.jobs = {}
    end

    -- Clear Akaturi contract state
    F2T_HAULING_STATE.akaturi_contract = {
        pickup_planet = nil,
        pickup_room = nil,
        delivery_planet = nil,
        delivery_room = nil,
        item = nil
    }
    F2T_HAULING_STATE.akaturi_package_collected = false
    F2T_HAULING_STATE.akaturi_package_delivered = false
    F2T_HAULING_STATE.akaturi_pickup_error = false
    F2T_HAULING_STATE.akaturi_delivery_error = false
    F2T_HAULING_STATE.akaturi_pickup_sent = false
    F2T_HAULING_STATE.akaturi_delivery_sent = false
    F2T_HAULING_STATE.akaturi_payment_amount = nil

    -- Clear Akaturi capture state
    if F2T_AKATURI_STATE then
        F2T_AKATURI_STATE.capturing_job = false
        F2T_AKATURI_STATE.capturing_pickup = false
        F2T_AKATURI_STATE.job_buffer = {}
        F2T_AKATURI_STATE.pickup_buffer = {}
        F2T_AKATURI_STATE.pickup_matches = {}
        F2T_AKATURI_STATE.delivery_matches = {}
        F2T_AKATURI_STATE.current_match_index = 0
    end

    -- Clear cycle pause tracking
    F2T_HAULING_STATE.cycle_pause_return_location = nil

    -- NOTE: DO NOT reset total_cycles, session_profit, or commodity_history
    -- These are preserved so 'haul status' can show last session statistics
end

-- Pause hauling
function f2t_hauling_pause()
    if not F2T_HAULING_STATE.active then
        cecho("\n<yellow>[hauling]<reset> Hauling not active\n")
        return
    end

    if F2T_HAULING_STATE.paused then
        cecho("\n<yellow>[hauling]<reset> Already paused\n")
        return
    end

    F2T_HAULING_STATE.paused = true

    -- Store speedwalk destination before stopping (so we can recompute on resume)
    if F2T_SPEEDWALK_ACTIVE and F2T_SPEEDWALK_DESTINATION_ROOM_ID then
        F2T_HAULING_STATE.paused_speedwalk_destination = F2T_SPEEDWALK_DESTINATION_ROOM_ID
        f2t_debug_log("[hauling] Stored speedwalk destination: %d", F2T_SPEEDWALK_DESTINATION_ROOM_ID)
    else
        F2T_HAULING_STATE.paused_speedwalk_destination = nil
    end

    cecho(string.format("\n<green>[hauling]<reset> Paused at phase: <cyan>%s<reset>\n",
        F2T_HAULING_STATE.current_phase or "unknown"))

    f2t_debug_log("[hauling] Paused at phase: %s", F2T_HAULING_STATE.current_phase or "unknown")

    -- Stop any active speedwalk (will recompute on resume)
    if F2T_SPEEDWALK_ACTIVE then
        f2t_debug_log("[hauling] Stopping speedwalk (will recompute on resume)")
        f2t_map_speedwalk_stop()
    end
end

-- Resume hauling
function f2t_hauling_resume()
    if not F2T_HAULING_STATE.active then
        cecho("\n<yellow>[hauling]<reset> Hauling not active\n")
        return
    end

    if not F2T_HAULING_STATE.paused then
        cecho("\n<yellow>[hauling]<reset> Not paused\n")
        return
    end

    F2T_HAULING_STATE.paused = false

    cecho(string.format("\n<green>[hauling]<reset> Resuming from phase: <cyan>%s<reset>\n",
        F2T_HAULING_STATE.current_phase or "unknown"))

    f2t_debug_log("[hauling] Resumed from phase: %s", F2T_HAULING_STATE.current_phase or "unknown")

    -- If we had a paused speedwalk, recompute path to the original destination
    local should_restart_phase = true
    if F2T_HAULING_STATE.paused_speedwalk_destination then
        local destination = F2T_HAULING_STATE.paused_speedwalk_destination
        F2T_HAULING_STATE.paused_speedwalk_destination = nil  -- Clear it

        f2t_debug_log("[hauling] Recomputing speedwalk to destination: %d", destination)
        cecho(string.format("\n<cyan>[hauling]<reset> Recomputing path to destination...\n"))

        -- Navigate to the stored destination
        local result = f2t_map_navigate(destination)
        if result == true then
            f2t_debug_log("[hauling] Already at destination, continuing phase")
            -- Already there, restart phase
        else
            -- Navigation started, don't restart phase yet
            should_restart_phase = false
        end
    end

    -- Only re-execute phase if we don't have an active speedwalk
    -- This prevents starting a new navigation when we're already navigating
    if should_restart_phase and F2T_HAULING_STATE.current_phase then
        f2t_debug_log("[hauling] Restarting phase: %s", F2T_HAULING_STATE.current_phase)
        f2t_hauling_transition(F2T_HAULING_STATE.current_phase)
    end
end

-- Show current hauling status
function f2t_hauling_show_status()
    -- Show status header
    if F2T_HAULING_STATE.active then
        cecho("\n<green>[hauling]<reset> Status:\n")
        cecho(string.format("  State: <cyan>%s<reset>\n",
            F2T_HAULING_STATE.paused and "PAUSED" or "RUNNING"))
        cecho(string.format("  Phase: <cyan>%s<reset>\n",
            F2T_HAULING_STATE.current_phase or "none"))
    else
        cecho("\n<green>[hauling]<reset> Status: <yellow>STOPPED<reset>\n")

        -- If no statistics exist, nothing to show
        if F2T_HAULING_STATE.total_cycles == 0 and #F2T_HAULING_STATE.commodity_history == 0 then
            cecho("\n<dim_grey>No hauling session data available. Use 'haul start' to begin.<reset>\n")
            return
        end

        cecho("\n<dim_grey>Last session results:<reset>\n")
    end

    -- Overall statistics (show for both active and stopped)
    cecho("\n<white>Session Statistics:<reset>\n")
    cecho(string.format("  Total Cycles: <cyan>%d<reset>\n",
        F2T_HAULING_STATE.total_cycles))
    cecho(string.format("  Session Profit: <green>%d ig<reset>\n",
        F2T_HAULING_STATE.session_profit))

    if F2T_HAULING_STATE.total_cycles > 0 then
        local avg_profit = math.floor(F2T_HAULING_STATE.session_profit / F2T_HAULING_STATE.total_cycles)
        cecho(string.format("  Avg Profit/Cycle: <cyan>%d ig<reset>\n", avg_profit))
    end

    -- Active session details (only show when hauling is running)
    if F2T_HAULING_STATE.active then
        -- Commodity queue
        if F2T_HAULING_STATE.commodity_queue and #F2T_HAULING_STATE.commodity_queue > 0 then
            cecho(string.format("\n<white>Commodity Queue:<reset> <cyan>%d/%d<reset>\n",
                F2T_HAULING_STATE.queue_index, #F2T_HAULING_STATE.commodity_queue))
            for i, comm in ipairs(F2T_HAULING_STATE.commodity_queue) do
                local marker = i == F2T_HAULING_STATE.queue_index and " <yellow>*<reset>" or ""
                cecho(string.format("  %d. <cyan>%s<reset> (profit: %d ig/ton)%s\n",
                    i, comm.commodity, comm.expected_profit, marker))
            end
        end

        -- Current commodity
        if F2T_HAULING_STATE.current_commodity then
            cecho(string.format("\n<white>Current Commodity:<reset> <cyan>%s<reset>\n",
                F2T_HAULING_STATE.current_commodity))
            cecho(string.format("  Expected Profit: <green>%d ig/ton<reset>\n",
                F2T_HAULING_STATE.expected_profit))
            cecho(string.format("  Commodity Cycles: <cyan>%d<reset>\n",
                F2T_HAULING_STATE.commodity_cycles))

            -- Current cycle stats
            local stats = F2T_HAULING_STATE.current_commodity_stats
            if stats.lots_bought > 0 or stats.lots_sold > 0 then
                cecho("  <white>Current Cycle:<reset>\n")
                if stats.lots_bought > 0 then
                    cecho(string.format("    Bought: %d lots (cost: %d ig)\n",
                        stats.lots_bought, stats.total_cost))
                end
                if stats.lots_sold > 0 then
                    cecho(string.format("    Sold: %d lots (revenue: %d ig)\n",
                        stats.lots_sold, stats.total_revenue))
                end
            end
        end

        -- Locations
        if F2T_HAULING_STATE.buy_location then
            cecho(string.format("\n<white>Buy Location:<reset> <cyan>%s: %s<reset> at <yellow>%d ig/ton<reset>\n",
                F2T_HAULING_STATE.buy_location.system,
                F2T_HAULING_STATE.buy_location.planet,
                F2T_HAULING_STATE.buy_location.price))
        end

        if F2T_HAULING_STATE.sell_location then
            cecho(string.format("<white>Sell Location:<reset> <cyan>%s: %s<reset> at <yellow>%d ig/ton<reset>\n",
                F2T_HAULING_STATE.sell_location.system,
                F2T_HAULING_STATE.sell_location.planet,
                F2T_HAULING_STATE.sell_location.price))
        end
    end  -- End active session details

    -- Commodity history (show for both active and stopped)
    if #F2T_HAULING_STATE.commodity_history > 0 then
        cecho("\n<white>Completed Commodities:<reset>\n")
        for _, hist in ipairs(F2T_HAULING_STATE.commodity_history) do
            cecho(string.format("  <cyan>%s<reset>: %d cycles, profit: <green>%d ig<reset>\n",
                hist.commodity, hist.cycles, hist.profit))
        end
    end
end

-- Transition to a new phase
function f2t_hauling_transition(new_phase)
    if not F2T_HAULING_STATE.active or F2T_HAULING_STATE.paused then
        return
    end

    f2t_debug_log("[hauling] Transitioning to phase: %s", new_phase)
    F2T_HAULING_STATE.current_phase = new_phase

    -- Execute phase
    if new_phase == "analyzing" then
        f2t_hauling_phase_analyze()
    elseif new_phase == "navigating_to_buy" then
        f2t_hauling_phase_navigate_to_buy()
    elseif new_phase == "buying" then
        f2t_hauling_phase_buy()
    elseif new_phase == "navigating_to_sell" then
        f2t_hauling_phase_navigate_to_sell()
    elseif new_phase == "selling" then
        f2t_hauling_phase_sell()
    -- Armstrong Cuthbert phases
    elseif new_phase == "ac_fetching_jobs" then
        f2t_hauling_phase_ac_fetch_jobs()
    elseif new_phase == "ac_selecting_job" then
        f2t_hauling_phase_ac_select_job()
    elseif new_phase == "ac_navigating_to_source" then
        f2t_hauling_phase_ac_navigate_to_source()
    elseif new_phase == "ac_accepting_job" then
        f2t_hauling_phase_ac_accept_job()
    elseif new_phase == "ac_collecting" then
        f2t_hauling_phase_ac_collect()
    elseif new_phase == "ac_navigating_to_dest" then
        f2t_hauling_phase_ac_navigate_to_dest()
    elseif new_phase == "ac_delivering" then
        f2t_hauling_phase_ac_deliver()
    -- Akaturi phases
    elseif new_phase == "akaturi_getting_job" then
        f2t_hauling_phase_akaturi_get_job()
    elseif new_phase == "akaturi_parsing_pickup" then
        f2t_hauling_phase_akaturi_parse_pickup()
    elseif new_phase == "akaturi_searching_pickup" then
        f2t_hauling_phase_akaturi_search_pickup()
    elseif new_phase == "akaturi_navigating_pickup" then
        f2t_hauling_phase_akaturi_navigate_pickup()
    elseif new_phase == "akaturi_collecting" then
        f2t_hauling_phase_akaturi_collect()
    elseif new_phase == "akaturi_searching_delivery" then
        -- This phase is handled inline in collect phase
        f2t_debug_log("[hauling] Akaturi delivery search handled in collect phase")
    elseif new_phase == "akaturi_navigating_delivery" then
        f2t_hauling_phase_akaturi_navigate_delivery()
    elseif new_phase == "akaturi_delivering" then
        f2t_hauling_phase_akaturi_deliver()
    elseif new_phase == "akaturi_navigating_to_planet_for_pickup" then
        -- Special phase: user is navigating to planet for manual room finding
        -- This should only be called after user manually found room and resumed
        -- If speedwalk is still active, event handler will handle it
        if not F2T_SPEEDWALK_ACTIVE then
            f2t_debug_log("[hauling/akaturi] User manually found pickup room, transitioning to collecting")
            f2t_hauling_transition("akaturi_collecting")
        else
            f2t_debug_log("[hauling/akaturi] Still navigating to planet, waiting for completion")
        end
    elseif new_phase == "akaturi_navigating_to_planet_for_delivery" then
        -- Special phase: user is navigating to planet for manual room finding
        -- This should only be called after user manually found room and resumed
        -- If speedwalk is still active, event handler will handle it
        if not F2T_SPEEDWALK_ACTIVE then
            f2t_debug_log("[hauling/akaturi] User manually found delivery room, transitioning to delivering")
            f2t_hauling_transition("akaturi_delivering")
        else
            f2t_debug_log("[hauling/akaturi] Still navigating to planet, waiting for completion")
        end
    else
        cecho(string.format("\n<red>[hauling]<reset> Unknown phase: %s\n", new_phase))
        f2t_hauling_stop()
    end
end

f2t_debug_log("[hauling] State machine loaded")
