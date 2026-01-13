-- @patterns:
--   - pattern: ^(?:factory|fac)(?:\s+(.+))?$

-- Factory command - View status of all factories
local command = matches[1]
local args = matches[2]

-- Check rank requirement (only Industrialist or Manufacturer)
local rank = f2t_get_rank()
if not (f2t_is_rank_exactly("Industrialist") or f2t_is_rank_exactly("Manufacturer")) then
    cecho("\n<red>[factory]<reset> Factory commands require <cyan>Industrialist<reset> or <cyan>Manufacturer<reset> rank\n")
    if rank then
        cecho(string.format("<dim_grey>Your current rank: <white>%s<reset>\n", rank))
    end
    return
end

-- No arguments - show help (no default behavior)
if not args or args == "" then
    f2t_show_registered_help("factory")
    return
end

-- Check for help request
if f2t_handle_help("factory", args) then
    return
end

-- Parse subcommand
local subcommand = f2t_parse_words(args)[1]

if subcommand == "status" then
    -- factory status / fac status
    cecho("\n<green>[factory]<reset> Gathering factory data...\n")
    f2t_debug_log("[factory-status] Starting factory status command")
    f2t_factory_start_capture()

elseif subcommand == "flush" then
    -- factory flush / fac flush
    cecho("\n<green>[factory]<reset> Flushing all factories...\n")
    f2t_debug_log("[factory-flush] Starting factory flush command")
    f2t_factory_start_flush()

elseif subcommand == "settings" then
    -- factory settings [list|get|set|clear]
    local settings_args = f2t_parse_subcommand(args, "settings") or ""
    f2t_handle_settings_command("factory", settings_args)

else
    cecho(string.format("\n<red>[factory]<reset> Unknown command: %s\n", subcommand))
    f2t_show_help_hint("factory")
end
