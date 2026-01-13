-- Centralized help registry for fed2-tools commands
-- Allows commands to register help once, then be invoked from multiple places

-- ========================================
-- Help Registry
-- ========================================

-- Global registry of command help
F2T_HELP_REGISTRY = F2T_HELP_REGISTRY or {}

-- Register help for a command
-- Parameters:
--   command: string - Command name (e.g., "nav", "nav stop", "map dest")
--   config: table with fields:
--     - description: string - Brief description
--     - usage: table - Array of {cmd, desc} tables
--     - examples: table (optional) - Array of example strings
function f2t_register_help(command, config)
    if not command or command == "" then
        f2t_debug_log("[help] Cannot register help: empty command name")
        return false
    end

    if not config or not config.description then
        f2t_debug_log("[help] Cannot register help for '%s': missing description", command)
        return false
    end

    F2T_HELP_REGISTRY[command] = {
        description = config.description,
        usage = config.usage or {},
        examples = config.examples or {}
    }

    f2t_debug_log("[help] Registered help for command: %s", command)
    return true
end

-- Show help for a registered command
-- Parameters:
--   command: string - Command name to show help for
-- Returns: true if help was shown, false if command not registered
function f2t_show_registered_help(command)
    local help_config = F2T_HELP_REGISTRY[command]

    if not help_config then
        f2t_debug_log("[help] No help registered for command: %s", command)
        return false
    end

    f2t_show_help(command, help_config.description, help_config.usage, help_config.examples)
    return true
end

-- Check if argument is a help request and show help if registered
-- This is the main function aliases should use
-- Parameters:
--   command: string - Command name
--   arg: string - User argument to check
-- Returns: true if help was shown, false otherwise
function f2t_handle_help(command, arg)
    if not f2t_is_help_request(arg) then
        return false
    end

    return f2t_show_registered_help(command)
end

-- List all registered commands (useful for debugging)
function f2t_list_registered_help()
    cecho("\n<green>[help]<reset> Registered commands:\n\n")

    local commands = {}
    for cmd, _ in pairs(F2T_HELP_REGISTRY) do
        table.insert(commands, cmd)
    end

    table.sort(commands)

    for _, cmd in ipairs(commands) do
        cecho(string.format("  <cyan>%s<reset>\n", cmd))
    end

    cecho("\n")
end
