-- Detect when factory flush succeeds
-- @patterns:
--   - pattern: ^The storage facilities at factory #(\d+) have been cleared\.$
--     type: regex

if f2t_factory.flushing then
    deleteLine()

    local factory_num = tonumber(matches[2])
    f2t_factory.flush_count = f2t_factory.flush_count + 1

    f2t_debug_log("[factory-flush] Successfully flushed factory %d", factory_num)

    -- Continue to next factory
    f2t_factory_flush_next()
end
