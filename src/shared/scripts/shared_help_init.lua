-- Register help for all shared component commands (f2t system commands)
-- This file runs during initialization to populate the help registry

-- ========================================
-- F2T Main Command
-- ========================================

f2t_register_help("f2t", {
    description = "Federation 2 Tools Package - System commands and component overview",
    usage = {
        {cmd = "System Commands:", desc = ""},
        {cmd = "f2t", desc = "Show this help"},
        {cmd = "f2t status", desc = "Show component states"},
        {cmd = "f2t version", desc = "Show package version"},
        {cmd = "f2t debug on/off", desc = "Toggle debug logging"},
        {cmd = "f2t settings", desc = "Manage system settings"},
        {cmd = "", desc = ""},
        {cmd = "Components:", desc = ""},
        {cmd = "map help", desc = "Auto-mapping, navigation, destinations"},
        {cmd = "nav help", desc = "Navigation command formats"},
        {cmd = "factory help", desc = "Factory status display"},
        {cmd = "refuel help", desc = "Automatic ship refueling"},
        {cmd = "bb help", desc = "Bulk buy commodities"},
        {cmd = "bs help", desc = "Bulk sell commodities"},
        {cmd = "price help", desc = "Commodity price analysis"},
        {cmd = "haul help", desc = "Automated commodity trading"}
    },
    examples = {
        "f2t status              # Check which components are enabled",
        "f2t version             # Show current package version",
        "f2t debug on            # Enable debug logging",
        "f2t settings            # View system settings",
        "map help                # Get help for map component"
    }
})

-- ========================================
-- F2T Settings Command
-- ========================================

f2t_register_help("f2t settings", {
    description = "Manage fed2-tools system settings",
    usage = {
        {cmd = "f2t settings", desc = "List all system settings"},
        {cmd = "f2t settings get <name>", desc = "Get a specific setting"},
        {cmd = "f2t settings set <name> <value>", desc = "Set a setting"},
        {cmd = "f2t settings clear <name>", desc = "Reset setting to default"}
    },
    examples = {
        "f2t settings                          # List all settings",
        "f2t settings set stamina_threshold 25 # Enable stamina at 25%",
        "f2t settings set food_source earth    # Set food source location",
        "f2t settings clear stamina_threshold  # Disable (reset to 0)"
    }
})

-- ========================================
-- F2T Debug Command
-- ========================================

f2t_register_help("f2t debug", {
    description = "Control debug logging for fed2-tools components",
    usage = {
        {cmd = "f2t debug", desc = "Show current debug state"},
        {cmd = "f2t debug on", desc = "Enable debug logging (persists)"},
        {cmd = "f2t debug off", desc = "Disable debug logging (persists)"}
    },
    examples = {
        "f2t debug on     # Enable debug messages",
        "f2t debug off    # Disable debug messages",
        "f2t debug        # Show current state"
    }
})

-- ========================================
-- F2T Status Command
-- ========================================

f2t_register_help("f2t status", {
    description = "Show fed2-tools component status",
    usage = {
        {cmd = "f2t status", desc = "Display all component states"}
    },
    examples = {
        "f2t status       # Show which components are enabled/disabled"
    }
})

f2t_debug_log("[shared] Registered help for f2t system commands")
