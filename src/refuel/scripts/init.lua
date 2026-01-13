-- Initialize refuel component
-- threshold = 0 means disabled, threshold > 0 means enabled

-- Load threshold (settings registered in shared/scripts/f2t_refuel_settings.lua)
REFUEL_THRESHOLD = tonumber(f2t_settings_get("shared", "refuel_threshold")) or 0

f2t_debug_log("[refuel] Initialized: %s",
    REFUEL_THRESHOLD > 0
        and string.format("ENABLED at %d%%", REFUEL_THRESHOLD)
        or "DISABLED")
