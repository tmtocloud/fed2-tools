-- Factory Status Tool Initialization
-- Stores factory data and provides core functionality

-- Register settings
f2t_settings_register("factory", "auto_flush_before_reset", {
    description = "Automatically flush all factories before daily game reset",
    default = false,
    validator = function(value)
        if value ~= true and value ~= false and value ~= "true" and value ~= "false" then
            return false, "Must be true or false"
        end
        return true
    end
})

-- Initialize factory status data structure
f2t_factory = f2t_factory or {
    capturing = false,
    current_number = 0,
    max_factories = 8,  -- Set based on rank: Industrialist=8, Manufacturer=15
    current_data = {},
    factories = {},
    capture_buffer = {},
    flushing = false,
    flush_count = 0,
    shutdown_timer_id = nil
}

f2t_debug_log("[factory] Initialized with auto_flush_before_reset: %s",
    f2t_settings_get("factory", "auto_flush_before_reset") and "ENABLED" or "DISABLED")

-- Reset factory collection
function f2t_factory_reset()
    f2t_factory.capturing = false
    f2t_factory.current_number = 0
    f2t_factory.max_factories = 8
    f2t_factory.current_data = {}
    f2t_factory.factories = {}
    f2t_factory.capture_buffer = {}
    f2t_factory.flushing = false
    f2t_factory.flush_count = 0
    f2t_debug_log("[factory-status] Reset factory data")
end

-- Start capturing factory data
function f2t_factory_start_capture()
    -- Prevent concurrent operations
    if f2t_factory.capturing then
        cecho("\n<yellow>[factory]<reset> Factory status already in progress, please wait...\n")
        return false
    end
    if f2t_factory.flushing then
        cecho("\n<yellow>[factory]<reset> Factory flush in progress, please wait...\n")
        return false
    end

    f2t_factory_reset()
    f2t_factory.capturing = true
    f2t_factory.capture_buffer = {}

    -- Set max factories based on rank: Manufacturer=15, Industrialist=8
    f2t_factory.max_factories = f2t_is_rank_exactly("Manufacturer") and 15 or 8

    f2t_debug_log("[factory-status] Starting factory capture (max: %d)", f2t_factory.max_factories)

    f2t_factory_query_next()
    return true
end

-- Query next factory
function f2t_factory_query_next()
    if not f2t_factory.capturing then
        f2t_debug_log("[factory-status] WARNING: query_next called while not capturing")
        return
    end

    f2t_factory.current_number = f2t_factory.current_number + 1
    f2t_factory.capture_buffer = {}

    -- Check if we've queried all possible factories
    if f2t_factory.current_number > f2t_factory.max_factories then
        f2t_debug_log("[factory-status] Reached max factories (%d), completing", f2t_factory.max_factories)
        f2t_factory_complete()
        return
    end

    f2t_debug_log("[factory-status] Querying factory %d", f2t_factory.current_number)

    send(string.format("display factory %d", f2t_factory.current_number), false)
    deleteLine()
end
