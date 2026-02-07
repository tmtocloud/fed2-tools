-- Register help for all ui component commands
-- This file runs during initialization to populate the help registry

-- ========================================
-- ui Command
-- ========================================

f2t_register_help("ui", {
    description = "Federation 2 UI - Frames, Movable Tabs, Status Displays, Output Windows, and Helpful Buttons",
    usage = {
        {cmd = "ui", desc = "Show UI status"},
        {cmd = "ui on", desc = "Enable UI (show elements, enable triggers/aliases/events)"},
        {cmd = "ui off", desc = "Disable UI (hide elements, disable triggers/aliases/events)"},
        {cmd = "ui status", desc = "Show detailed UI status"}
    },
    examples = {
        "ui off    # Hide UI for clean gameplay",
        "ui on     # Restore UI"
    }
})

f2t_debug_log("[ui] Registered help for ui commands")
