-- Event handler registration for Federation 2 mapper
-- Registers GMCP event handlers for room data

-- ========================================
-- GMCP Room Info Event Handler
-- ========================================

-- Register event handler for gmcp.room.info
-- This fires whenever the game sends updated room data
local success, handler_id = pcall(registerAnonymousEventHandler, "gmcp.room.info", "f2t_map_handle_gmcp_room")

if success and handler_id then
    f2t_debug_log("[map] Registered GMCP event handler for gmcp.room.info (ID: %s)", tostring(handler_id))
else
    f2t_debug_log("[map] WARNING: Failed to register GMCP event handler: %s", tostring(handler_id))
end
