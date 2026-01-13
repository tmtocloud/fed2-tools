-- Connection Handler for fed2-tools
-- Manages initialization based on connection state

-- ========================================
-- Connection State
-- ========================================

F2T_CONNECTED = false

-- ========================================
-- Connection Check
-- ========================================

-- Check if we're currently connected to the game
function f2t_check_connection()
    local conn_info = getConnectionInfo()

    if conn_info and conn_info.host and conn_info.host ~= "" then
        F2T_CONNECTED = true
        f2t_debug_log("[connection] Connected to: %s:%s", conn_info.host, tostring(conn_info.port))
        return true
    else
        F2T_CONNECTED = false
        f2t_debug_log("[connection] Not connected")
        return false
    end
end

-- ========================================
-- Connection Event Handler
-- ========================================

-- Register handler for connection events
function f2t_register_connection_handler()
    -- Check current connection state
    local connected = f2t_check_connection()

    if connected then
        f2t_debug_log("[connection] Already connected, components ready")
    else
        f2t_debug_log("[connection] Not connected, waiting for connection...")
    end

    -- Register event handler for future connection events
    registerAnonymousEventHandler("sysConnectionEvent", function()
        f2t_debug_log("[connection] Connection event received")

        -- Check new connection state
        local now_connected = f2t_check_connection()

        if now_connected and not F2T_CONNECTED then
            -- Just connected
            F2T_CONNECTED = true
            f2t_debug_log("[connection] Connection established, components ready")
        elseif not now_connected and F2T_CONNECTED then
            -- Just disconnected
            F2T_CONNECTED = false
            f2t_debug_log("[connection] Disconnected from game")
        end
    end)

    f2t_debug_log("[connection] Connection handler registered")
end

-- ========================================
-- Initialization
-- ========================================

-- Register connection handler
f2t_register_connection_handler()

f2t_debug_log("[connection] Connection handler initialized")
