-- Federation 2 Tool Availability Checking
-- Provides utilities for checking game tools/upgrades via GMCP

-- ========================================
-- Tool Query Functions
-- ========================================

-- Get a tool's data from GMCP
-- @param tool_name: Tool identifier (e.g., "remote-access-cert")
-- Returns: tool data table (e.g., {days = 20}), or nil if not available
function f2t_get_tool(tool_name)
    if not tool_name then
        return nil
    end

    local tools = gmcp.char and gmcp.char.vitals and gmcp.char.vitals.tools

    if not tools then
        f2t_debug_log("[tools] No tool data available from GMCP")
        return nil
    end

    local tool_data = tools[tool_name]

    if not tool_data then
        f2t_debug_log("[tools] Tool not found: %s", tool_name)
        return nil
    end

    f2t_debug_log("[tools] Tool found: %s", tool_name)
    return tool_data
end

-- Check if player has a specific tool
-- @param tool_name: Tool identifier (e.g., "remote-access-cert")
-- Returns: true if tool exists, false otherwise
function f2t_has_tool(tool_name)
    return f2t_get_tool(tool_name) ~= nil
end

-- ========================================
-- Tool Requirement Check
-- ========================================

-- Check if player has a required tool and display error if not
-- @param tool_name: Tool identifier to check for
-- @param feature_name: Name of feature requiring this tool (for error message)
-- @param display_name: Optional user-friendly name for the tool (defaults to tool_name)
-- Returns: true if requirement met, false otherwise
function f2t_check_tool_requirement(tool_name, feature_name, display_name)
    if f2t_has_tool(tool_name) then
        return true
    end

    local name = display_name or tool_name
    cecho(string.format("\n<red>[fed2-tools]<reset> %s requires the <cyan>%s<reset> tool\n",
        feature_name, name))
    cecho("<dim_grey>See: https://federation2.com/guide/#sec-230.20<reset>\n")

    return false
end

f2t_debug_log("[tools] Tool availability system initialized")
