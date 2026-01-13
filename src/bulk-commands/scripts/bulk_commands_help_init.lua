-- Register help for all bulk-commands component commands
-- This file runs during initialization to populate the help registry

-- ========================================
-- Bulk Buy Command
-- ========================================

f2t_register_help("bb", {
    description = "Bulk buy commodities at exchanges",
    usage = {
        {cmd = "bb <commodity> [count]", desc = "Buy commodity in bulk"},
        {cmd = "bb <commodity>", desc = "Buy all available cargo space"}
    },
    examples = {
        "bb alloys       # Buy alloys until cargo full",
        "bb alloys 5     # Buy exactly 5 lots of alloys",
        "bb grain 10     # Buy 10 lots of grain"
    }
})

-- ========================================
-- Bulk Sell Command
-- ========================================

f2t_register_help("bs", {
    description = "Bulk sell commodities at exchanges",
    usage = {
        {cmd = "bs", desc = "Sell entire cargo hold"},
        {cmd = "bs <commodity>", desc = "Sell all lots of specific commodity"},
        {cmd = "bs <commodity> <count>", desc = "Sell specific number of lots"}
    },
    examples = {
        "bs              # Sell everything in cargo",
        "bs alloys       # Sell all alloys lots",
        "bs grain 5      # Sell 5 lots of grain"
    }
})

f2t_debug_log("[bulk-commands] Registered help for bulk commands")
