-- @patterns:
--   - pattern: ^(?:nav|go|goto)(?:\s+(.+))?$

-- Navigation command with subcommands
-- Usage: nav <destination>
-- Usage: nav info <destination>
-- Usage: nav info <origin> <destination>
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

elseif subcommand == "info" then
    -- nav info - Show route information
    local info_rest = args:match("^info%s+(.+)$")
    
    if f2t_handle_help("nav info", info_rest or "") then
        return
    end
    
    if not info_rest or info_rest == "" then
        cecho("\n<red>[map]<reset> Usage: nav info <destination> OR nav info <origin> <destination>\n")
        return
    end
    
    -- Parse origin and destination
    -- Support quoted strings for multi-word locations
    local origin, destination
    
    -- Try: "origin" "destination"
    local q_origin, q_dest = info_rest:match('^"([^"]+)"%s+"([^"]+)"$')
    if q_origin and q_dest then
        origin = q_origin
        destination = q_dest
    else
        -- Try: "origin" destination
        local q_origin2, unq_dest = info_rest:match('^"([^"]+)"%s+(.+)$')
        if q_origin2 then
            origin = q_origin2
            destination = unq_dest
        else
            -- Try: origin "destination"
            local unq_origin, q_dest2 = info_rest:match('^(.-)%s+"([^"]+)"$')
            if q_dest2 then
                origin = unq_origin
                destination = q_dest2
            else
                -- No quotes - check for two space-separated words
                local word1, word2 = info_rest:match("^(%S+)%s+(.+)$")
                if word1 and word2 then
                    origin = word1
                    destination = word2
                else
                    -- Single argument - treat as destination only
                    origin = nil
                    destination = info_rest
                end
            end
        end
    end
    
    f2t_map_show_route_info(origin, destination)

else
    -- Default: treat as destination and navigate
    f2t_map_navigate(args)
end