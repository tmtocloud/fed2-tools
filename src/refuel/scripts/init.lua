-- Initialize refuel component
-- Settings are registered in shared/scripts/f2t_settings_refuel.lua
-- threshold = 0 means disabled, threshold > 0 means enabled at that percentage

local threshold = f2t_settings_get("shared", "refuel_threshold") or 0

f2t_debug_log("[refuel] Initialized: %s",
    threshold > 0
        and string.format("ENABLED at %d%%", threshold)
        or "DISABLED")
