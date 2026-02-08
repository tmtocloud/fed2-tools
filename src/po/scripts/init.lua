-- Initialize planet owner component
f2t_settings = f2t_settings or {}
f2t_settings.po = f2t_settings.po or {}

-- Global state for po capture operations
-- Supports independent exchange and production captures with callbacks
f2t_po = f2t_po or {
    phase = "idle",          -- "idle", "capturing_exchange", "transitioning", "capturing_production"
    planet = nil,            -- Planet being queried
    capture_buffer = {},     -- Lines captured during current phase
    callback = nil,          -- function(parsed_data) called on completion
    timer_id = nil
}

--- Reset all po capture state
function f2t_po_reset()
    if f2t_po.timer_id then
        killTimer(f2t_po.timer_id)
    end

    f2t_po.phase = "idle"
    f2t_po.planet = nil
    f2t_po.capture_buffer = {}
    f2t_po.callback = nil
    f2t_po.timer_id = nil
end

if F2T_DEBUG then
    cecho("<green>[po]<reset> Initialized\n")
end
