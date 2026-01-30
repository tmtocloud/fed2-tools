-- @patterns:
--   - pattern: ^ui(?:\s+(.+))?$

-- Main ui command - handles all ui-related subcommands
local args = matches[2]

-- No arguments - show help
if not args or args == "" then
    f2t_show_registered_help("ui")
    return
end

-- Check for help request
if f2t_handle_help("ui", args) then
    return
end

-- Parse subcommand
local subcommand = string.lower(args):match("^(%S+)")

if subcommand == "on" then
    -- ui on - Enable ui
    F2T_UI_ENABLED = true
    f2t_settings_set("ui", "enabled", true)
    cecho("\n<green>[ui]<reset> ui <yellow>ENABLED<reset>\n")
    f2t_debug_log("[ui] ui enabled by user")

elseif subcommand == "off" then
    -- ui off - Disable ui
    F2T_UI_ENABLED = false
    f2t_settings_set("ui", "enabled", false)
    cecho("\n<green>[ui]<reset> ui <red>DISABLED<reset>\n")
    f2t_debug_log("[ui] ui disabled by user")
else
    cecho(string.format("\n<red>[ui]<reset> Unknown command: %s\n", subcommand))
    f2t_show_help_hint("ui")
end