-- Register help for all ui component commands
-- This file runs during initialization to populate the help registry

-- ========================================
-- ui Command
-- ========================================

f2t_register_help("ui", {
    description = "Federation 2 UI - Frames, Movable Tabs, Status Displays, Output Windows, and Helpful Buttons",
    usage = {
        {cmd = "UI Control:", desc = ""},
        {cmd = "ui on", desc = "Enable ui"},
        {cmd = "ui off", desc = "Disable ui"}
    },
    examples = {
        "ui on  # Turn UI on,
        "ui off # Turn UI off"
    }
})

f2t_debug_log("[ui] Registered help for ui commands")
