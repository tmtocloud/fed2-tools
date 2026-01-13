-- Capture factory output lines
-- @patterns:
--   - pattern: Production Facility #
--     type: substring
--   - pattern: ^\s{2,}.+
--     type: regex

if f2t_factory.capturing then
    -- Don't capture the "You don't have a factory" line, let another trigger handle it
    if not line:find("You don't have a factory with that number!") then
        deleteLine()
        table.insert(f2t_factory.capture_buffer, line)
        f2t_debug_log("[factory-status] Captured: %s", line:sub(1, 50))

        -- Reset the capture timer since we got new data
        f2t_factory_reset_capture_timer()
    end
end
