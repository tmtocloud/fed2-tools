-- Factory Flush Logic
-- Iterates through all factories and flushes each one

-- Start flushing all factories
function f2t_factory_start_flush()
    -- Prevent concurrent operations
    if f2t_factory.flushing then
        cecho("\n<yellow>[factory]<reset> Factory flush already in progress, please wait...\n")
        return false
    end
    if f2t_factory.capturing then
        cecho("\n<yellow>[factory]<reset> Factory status in progress, please wait...\n")
        return false
    end

    -- Cancel any pending auto-flush timer (user manually flushing takes precedence)
    if f2t_factory.shutdown_timer_id then
        killTimer(f2t_factory.shutdown_timer_id)
        f2t_factory.shutdown_timer_id = nil
        f2t_debug_log("[factory-flush] Cancelled pending auto-flush timer")
    end

    f2t_factory.flushing = true
    f2t_factory.current_number = 0
    f2t_factory.flush_count = 0

    -- Set max factories based on rank: Manufacturer=15, Industrialist=8
    f2t_factory.max_factories = f2t_is_rank_exactly("Manufacturer") and 15 or 8

    f2t_debug_log("[factory-flush] Starting flush sequence (max: %d)", f2t_factory.max_factories)

    f2t_factory_flush_next()
    return true
end

-- Flush next factory
function f2t_factory_flush_next()
    if not f2t_factory.flushing then
        f2t_debug_log("[factory-flush] WARNING: flush_next called while not flushing")
        return
    end

    f2t_factory.current_number = f2t_factory.current_number + 1

    -- Check if we've flushed all possible factories
    if f2t_factory.current_number > f2t_factory.max_factories then
        f2t_debug_log("[factory-flush] Reached max factories (%d), completing", f2t_factory.max_factories)
        f2t_factory_flush_complete()
        return
    end

    f2t_debug_log("[factory-flush] Flushing factory %d", f2t_factory.current_number)

    send(string.format("flush factory %d", f2t_factory.current_number), false)
    deleteLine()
end

-- Complete flush sequence
function f2t_factory_flush_complete()
    local count = f2t_factory.flush_count

    f2t_factory.flushing = false
    f2t_factory.current_number = 0
    f2t_factory.flush_count = 0

    f2t_debug_log("[factory-flush] Completed flushing %d factories", count)

    if count == 0 then
        cecho("\n<yellow>[factory]<reset> No factories found to flush\n")
    elseif count == 1 then
        cecho("\n<green>[factory]<reset> Flushed 1 factory\n")
    else
        cecho(string.format("\n<green>[factory]<reset> Flushed %d factories\n", count))
    end
end
