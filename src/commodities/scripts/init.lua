-- Initialize commodities component
-- Provides commodity price checking and analysis tools

-- Initialize settings
f2t_settings = f2t_settings or {}
f2t_settings.commodities = f2t_settings.commodities or {}

-- Register settings
f2t_settings_register("commodities", "results_count", {
    description = "Number of top exchanges to show in price tables",
    default = 5,
    validator = function(value)
        local num = tonumber(value)
        if not num then
            return false, "Value must be a number"
        end
        if num < 1 or num > 20 then
            return false, "Value must be between 1 and 20"
        end
        return true
    end
})

-- Global state for price capture
F2T_PRICE_CAPTURE_ACTIVE = false
F2T_PRICE_CAPTURE_DATA = {}
F2T_PRICE_CURRENT_COMMODITY = nil
F2T_PRICE_CALLBACK = nil

-- Register help for price command
f2t_register_help("price", {
    description = "Check commodity prices and find profitable trading opportunities",
    usage = {
        {cmd = "price <commodity>", desc = "Show top buy/sell locations for specific commodity"},
        {cmd = "pr <commodity>", desc = "Shorthand for price command"},
        {cmd = "", desc = ""},
        {cmd = "price all", desc = "Analyze all commodities, sorted by profitability"},
        {cmd = "", desc = ""},
        {cmd = "price settings", desc = "List all commodities settings"},
        {cmd = "price settings set <name> <value>", desc = "Change a setting (e.g., results_count)"}
    },
    examples = {
        "price alloys                             # Check alloys prices",
        "pr nanofabrics                           # Check nanofabrics (shorthand)",
        "",
        "price all                                # Find most profitable commodities",
        "",
        "price settings set results_count 10      # Show top 10 exchanges instead of 5"
    }
})

f2t_debug_log("[commodities] Component initialized")
