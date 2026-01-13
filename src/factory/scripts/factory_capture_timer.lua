-- Timer-based capture completion detection
-- After capturing starts, if no new data arrives for a short time, consider factory complete

f2t_factory_timer_id = nil

function f2t_factory_start_capture_timer()
    -- Cancel existing timer if any
    if f2t_factory_timer_id then
        killTimer(f2t_factory_timer_id)
    end

    -- Start timer to process capture after 0.5 seconds of no new data
    -- CRITICAL: Timer MUST always complete when it expires to reset state
    f2t_factory_timer_id = tempTimer(0.5, function()
        if f2t_factory.capturing then
            if #f2t_factory.capture_buffer > 0 then
                f2t_debug_log("[factory-status] Timer expired, processing capture")
                f2t_factory_process_capture()
            else
                -- No data captured - likely pattern mismatch, but still continue
                f2t_debug_log("[factory-status] Timer expired with empty buffer, continuing to next")
                f2t_factory.capturing = false
                f2t_factory.capture_buffer = {}
                f2t_factory_query_next()
            end
        end
    end)
end

-- Call this whenever we capture a new line to reset the timer
function f2t_factory_reset_capture_timer()
    if f2t_factory.capturing then
        f2t_factory_start_capture_timer()
    end
end
