-- F2T status display
-- Shows enabled/disabled state of all fed2-tools components

function f2t_show_status()
    local version = F2T_VERSION or "unknown"
    cecho(string.format("\n<green>[fed2-tools]<reset> v%s - Component Status:\n\n", version))

    -- Map component
    local map_status = F2T_MAP_ENABLED and "<green>ENABLED<reset>" or "<red>DISABLED<reset>"
    cecho(string.format("  <yellow>%-15s<reset> %s\n", "Map", map_status))

    -- Refuel component (threshold 0 = disabled, >0 = enabled)
    local refuel_threshold = tonumber(f2t_settings_get("shared", "refuel_threshold")) or 0
    if refuel_threshold > 0 then
        cecho(string.format("  <yellow>%-15s<reset> <green>ENABLED<reset> <dim_grey>(threshold: %d%%)<reset>\n",
            "Refuel", refuel_threshold))
    else
        cecho(string.format("  <yellow>%-15s<reset> <red>DISABLED<reset>\n", "Refuel"))
    end

    -- Stamina monitoring (enabled if threshold > 0)
    local stamina_threshold = f2t_settings_get("shared", "stamina_threshold") or 0
    local stamina_enabled = stamina_threshold > 0
    local stamina_status = stamina_enabled and "<green>ENABLED<reset>" or "<red>DISABLED<reset>"
    if stamina_enabled then
        cecho(string.format("  <yellow>%-15s<reset> %s <dim_grey>(threshold: %d%%)<reset>\n",
            "Stamina Monitor", stamina_status, stamina_threshold))
    else
        cecho(string.format("  <yellow>%-15s<reset> %s\n", "Stamina Monitor", stamina_status))
    end

    -- Death monitoring
    local death_enabled = f2t_settings_get("shared", "death_monitor_enabled")
    local death_status = death_enabled and "<green>ENABLED<reset>" or "<red>DISABLED<reset>"
    cecho(string.format("  <yellow>%-15s<reset> %s\n",
        "Death Monitor", death_status))

    -- Debug mode
    local debug_status = F2T_DEBUG and "<yellow>ON<reset>" or "<dim_grey>OFF<reset>"
    cecho(string.format("\n  <yellow>%-15s<reset> %s\n", "Debug Mode", debug_status))

    cecho("\n")
end
