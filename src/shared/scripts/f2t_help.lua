-- Help system for fed2-tools commands
-- Provides standardized help display for all commands

-- Display help for a command
-- Parameters:
--   command: string - Command name (e.g., "map dest", "nav")
--   description: string - Brief description of what the command does
--   usage: table - Array of usage examples, each with {cmd, desc} fields
--     - Empty entries ({cmd = "", desc = ""}) create visual separators
--   examples: table (optional) - Array of example strings
--     - Empty strings ("") create visual separators
function f2t_show_help(command, description, usage, examples)
    -- Header
    cecho(string.format("\n<green>[%s]<reset> %s\n\n", command, description))

    -- Usage section
    if usage and #usage > 0 then
        cecho("<yellow>Usage:<reset>\n")
        for _, u in ipairs(usage) do
            -- Empty entry creates a visual separator
            if u.cmd == "" and (not u.desc or u.desc == "") then
                cecho("\n")
            else
                cecho(string.format("  <cyan>%s<reset>\n", u.cmd))
                if u.desc and u.desc ~= "" then
                    cecho(string.format("    <dim_grey>%s<reset>\n", u.desc))
                end
            end
        end
        cecho("\n")
    end

    -- Examples section
    if examples and #examples > 0 then
        cecho("<yellow>Examples:<reset>\n")
        for _, example in ipairs(examples) do
            -- Empty string creates a visual separator
            if example == "" then
                cecho("\n")
            else
                cecho(string.format("  <cyan>%s<reset>\n", example))
            end
        end
        cecho("\n")
    end
end

-- Check if user is requesting help
-- Returns: true if args is "help"
function f2t_is_help_request(args)
    if not args or args == "" then
        return false
    end

    return string.lower(args) == "help"
end

-- Show "use --help for more info" hint
function f2t_show_help_hint(command)
    cecho(string.format("\n<dim_grey>Use '%s help' for more information<reset>\n", command))
end
