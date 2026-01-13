-- @patterns:
--   - pattern: ^(?:nav|go|goto)(?:\s+(.+))?$

-- Navigation command with subcommands
-- Usage: nav <destination>
-- Usage: nav stop/pause/resume

local args = matches[2]

-- No arguments - show help
if not args or args == "" then
    f2t_show_registered_help("nav")
    return
end

-- Check for help request
if f2t_handle_help("nav", args) then
    return
end

-- Parse subcommand
local subcommand = string.lower(args):match("^(%S+)")

if subcommand == "stop" then
    -- nav stop - Stop active speedwalk
    local stop_rest = args:match("^stop%s+(.+)") or ""
    if f2t_handle_help("nav stop", stop_rest) then
        return
    end
    if not F2T_SPEEDWALK_ACTIVE then
        cecho("\n<yellow>[map]<reset> No active speedwalk to stop\n")
        return
    end
    f2t_map_speedwalk_stop()

elseif subcommand == "pause" then
    -- nav pause - Pause active speedwalk
    local pause_rest = args:match("^pause%s+(.+)") or ""
    if f2t_handle_help("nav pause", pause_rest) then
        return
    end
    if not F2T_SPEEDWALK_ACTIVE then
        cecho("\n<yellow>[map]<reset> No active speedwalk to pause\n")
        return
    end
    f2t_map_speedwalk_pause()

elseif subcommand == "resume" then
    -- nav resume - Resume paused speedwalk
    local resume_rest = args:match("^resume%s+(.+)") or ""
    if f2t_handle_help("nav resume", resume_rest) then
        return
    end
    if not F2T_SPEEDWALK_ACTIVE then
        cecho("\n<yellow>[map]<reset> No speedwalk to resume\n")
        return
    end
    f2t_map_speedwalk_resume()

else
    -- Default: treat as destination
    f2t_map_navigate(args)
end
