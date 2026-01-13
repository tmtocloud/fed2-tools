-- Confirmation system for manual mapping operations
-- Provides a safe way to confirm destructive operations with timeout

-- ========================================
-- Global State
-- ========================================

-- Pending confirmation state
-- Format: {action = string, callback = function, data = table, timer_id = number, expires_at = number}
F2T_MAP_MANUAL_PENDING_ACTION = nil

-- ========================================
-- Confirmation Request
-- ========================================

--- Request confirmation for a destructive operation
--- @param action string Description of the action (e.g., "delete room")
--- @param callback function Function to call if confirmed
--- @param data table Optional data to pass to callback
--- @return boolean true if confirmation requested, false if confirmations disabled
function f2t_map_manual_request_confirmation(action, callback, data)
    -- Check if confirmations are enabled
    local confirm_enabled = f2t_settings_get("map", "map_manual_confirm")

    if not confirm_enabled then
        -- Confirmations disabled, execute immediately
        f2t_debug_log("[map_manual] Confirmations disabled, executing: %s", action)
        callback(data)
        return false
    end

    -- Clear any existing pending action
    if F2T_MAP_MANUAL_PENDING_ACTION then
        if F2T_MAP_MANUAL_PENDING_ACTION.timer_id then
            killTimer(F2T_MAP_MANUAL_PENDING_ACTION.timer_id)
        end
        cecho("\n<yellow>[map]<reset> Previous confirmation cancelled\n")
    end

    -- Create timeout timer (30 seconds)
    local timer_id = tempTimer(30, function()
        if F2T_MAP_MANUAL_PENDING_ACTION then
            cecho("\n<red>[map]<reset> Confirmation expired\n")
            F2T_MAP_MANUAL_PENDING_ACTION = nil
        end
    end)

    -- Store pending action
    F2T_MAP_MANUAL_PENDING_ACTION = {
        action = action,
        callback = callback,
        data = data,
        timer_id = timer_id,
        expires_at = os.time() + 30
    }

    -- Show confirmation prompt
    cecho(string.format("\n<yellow>[map]<reset> Confirm action: <white>%s<reset>\n", action))
    cecho("\n<dim_grey>Use 'map confirm' within 30 seconds to proceed<reset>\n")

    f2t_debug_log("[map_manual] Confirmation requested: %s", action)

    return true
end

-- ========================================
-- Confirmation Execution
-- ========================================

--- Confirm and execute the pending action
--- @return boolean true on success, false if no pending action
function f2t_map_manual_confirm()
    if not F2T_MAP_MANUAL_PENDING_ACTION then
        cecho("\n<red>[map]<reset> No pending action to confirm\n")
        cecho("\n<dim_grey>Run a destructive command first (e.g., 'map room delete <id>')<reset>\n")
        return false
    end

    -- Check if expired
    if os.time() > F2T_MAP_MANUAL_PENDING_ACTION.expires_at then
        cecho("\n<red>[map]<reset> Confirmation expired\n")
        F2T_MAP_MANUAL_PENDING_ACTION = nil
        return false
    end

    local action = F2T_MAP_MANUAL_PENDING_ACTION.action
    local callback = F2T_MAP_MANUAL_PENDING_ACTION.callback
    local data = F2T_MAP_MANUAL_PENDING_ACTION.data

    -- Kill the timer
    if F2T_MAP_MANUAL_PENDING_ACTION.timer_id then
        killTimer(F2T_MAP_MANUAL_PENDING_ACTION.timer_id)
    end

    -- Clear pending action before executing (in case callback fails)
    F2T_MAP_MANUAL_PENDING_ACTION = nil

    -- Execute the callback
    f2t_debug_log("[map_manual] Confirmation accepted, executing: %s", action)
    cecho(string.format("\n<green>[map]<reset> Confirmed: <white>%s<reset>\n", action))

    callback(data)

    return true
end

-- ========================================
-- Manual Cancellation
-- ========================================

--- Manually cancel any pending confirmation
function f2t_map_manual_cancel_confirmation()
    if not F2T_MAP_MANUAL_PENDING_ACTION then
        cecho("\n<yellow>[map]<reset> No pending confirmation to cancel\n")
        return false
    end

    local action = F2T_MAP_MANUAL_PENDING_ACTION.action

    -- Kill the timer
    if F2T_MAP_MANUAL_PENDING_ACTION.timer_id then
        killTimer(F2T_MAP_MANUAL_PENDING_ACTION.timer_id)
    end

    -- Clear pending action
    F2T_MAP_MANUAL_PENDING_ACTION = nil

    cecho(string.format("\n<yellow>[map]<reset> Confirmation cancelled: <white>%s<reset>\n", action))
    f2t_debug_log("[map_manual] Confirmation cancelled: %s", action)

    return true
end

f2t_debug_log("[map] Manual confirmation system initialized")
