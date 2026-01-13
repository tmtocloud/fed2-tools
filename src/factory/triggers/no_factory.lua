-- Detect when a factory slot is empty (destroyed or never built)
-- @patterns:
--   - pattern: ^You don't have a factory with that number!$
--     type: regex

if f2t_factory.capturing then
    deleteLine()

    -- Record this as a missing factory slot
    f2t_debug_log("[factory-status] Factory %d not found, recording as missing", f2t_factory.current_number)
    table.insert(f2t_factory.factories, {
        number = f2t_factory.current_number,
        missing = true
    })

    -- Continue to next factory (query_next will complete when max is reached)
    f2t_factory_query_next()
end
