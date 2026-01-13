-- @patterns:
--   - pattern: ^haul(?:\s+(.+))?$

-- Hauling command - Automated commodity trading
local args = matches[2]

-- No arguments - show help
if not args or args == "" then
    f2t_show_registered_help("haul")
    return
end

-- Check for help request
if f2t_handle_help("haul", args) then
    return
end

-- Parse subcommand
local subcommand = string.lower(args):match("^(%S+)")

if subcommand == "start" then
    f2t_hauling_start()

elseif subcommand == "stop" then
    f2t_hauling_stop()

elseif subcommand == "terminate" or subcommand == "term" then
    f2t_hauling_terminate()

elseif subcommand == "pause" then
    f2t_hauling_pause()

elseif subcommand == "resume" then
    f2t_hauling_resume()

elseif subcommand == "status" then
    f2t_hauling_show_status()

elseif subcommand == "settings" then
    f2t_handle_settings_command("hauling", f2t_parse_subcommand(args, "settings") or "")

else
    cecho(string.format("\n<red>[hauling]<reset> Unknown command: %s\n", subcommand))
    f2t_show_help_hint("haul")
end
