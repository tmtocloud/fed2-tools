-- Register help for all ui component commands
-- This file runs during initialization to populate the help registry

-- ========================================
-- ui Command
-- ========================================

f2t_register_help("ui", {
    description = "Federation 2 UI - Frames, Movable Tabs, Status Displays, Output Windows, and Helpful Buttons",
    usage = {
        {cmd = "ui", desc = "Show UI status"},
        {cmd = "ui on", desc = "Enable UI (show elements, enable triggers)"},
        {cmd = "ui off", desc = "Disable UI (hide elements, disable triggers)"},
        {cmd = "ui toggle", desc = "Toggle UI state"},
        {cmd = "ui status", desc = "Show detailed UI status"},
        {cmd = "", desc = ""},
        {cmd = "Settings:", desc = ""},
        {cmd = "ui settings", desc = "List all mapper settings"},
        {cmd = "ui settings get <name>", desc = "Get a specific setting"},
        {cmd = "ui settings set <name> <value>", desc = "Set a setting"},
        {cmd = "ui settings clear <name>", desc = "Reset to default"}
    },
    examples = {
        "ui off    # Hide UI for clean gameplay",
        "ui on     # Restore UI",
        "ui settings set left_width 30",
        "ui settings get top_left_width"
    }
})

f2t_debug_log("[ui] Registered help for ui commands")
