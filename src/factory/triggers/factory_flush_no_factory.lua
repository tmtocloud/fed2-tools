-- Detect when a factory slot is empty during flush (destroyed or never built)
-- @patterns:
--   - pattern: ^You don't have a factory with that number!$
--     type: regex

if f2t_factory.flushing then
    deleteLine()
    f2t_debug_log("[factory-flush] Factory %d not found, skipping", f2t_factory.current_number)

    -- Continue to next factory (flush_next will complete when max is reached)
    f2t_factory_flush_next()
end
