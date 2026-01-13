-- Shared argument parsing utilities
-- Provides reusable helpers for parsing command arguments consistently

-- ========================================
-- Basic Parsing
-- ========================================

--- Split arguments into words (space-separated)
--- @param str string Argument string
--- @return table Array of words
function f2t_parse_words(str)
    if not str or str == "" then
        return {}
    end

    local words = {}
    for word in string.gmatch(str, "%S+") do
        table.insert(words, word)
    end
    return words
end

--- Get subcommand with rest-of-line capture
--- @param args string Full argument string
--- @param subcommand string Expected subcommand
--- @return string|nil rest Arguments after subcommand, or nil if subcommand doesn't match
function f2t_parse_subcommand(args, subcommand)
    local pattern = "^" .. subcommand .. "%s*(.*)$"
    return args:match(pattern)
end

--- Get remaining arguments as single string
--- @param words table Parsed words array
--- @param start_index number Starting index (inclusive)
--- @return string Joined remaining words
function f2t_parse_rest(words, start_index)
    start_index = start_index or 1
    local rest = {}
    for i = start_index, #words do
        table.insert(rest, words[i])
    end
    return table.concat(rest, " ")
end

-- ========================================
-- Argument Validation
-- ========================================

--- Parse required argument with automatic error handling
--- @param words table Parsed words
--- @param index number Word index to parse
--- @param component string Component name for error prefix
--- @param usage_msg string Usage message to display on error
--- @return string|nil Argument value, or nil (with error displayed)
function f2t_parse_required_arg(words, index, component, usage_msg)
    if not words[index] then
        cecho(string.format("\n<red>[%s]<reset> %s\n", component, usage_msg))
        return nil
    end
    return words[index]
end

--- Parse optional number argument with default
--- @param words table Parsed words
--- @param index number Word index to parse
--- @param default any Default value if not present or invalid
--- @return number|any Parsed number or default
function f2t_parse_optional_number(words, index, default)
    local value = tonumber(words[index])
    return value or default
end

--- Parse required number argument with validation
--- @param words table Parsed words
--- @param index number Word index to parse
--- @param component string Component name for error messages
--- @param usage_msg string Usage message to display on error
--- @return number|nil Parsed number or nil (with error displayed)
function f2t_parse_required_number(words, index, component, usage_msg)
    local value = tonumber(words[index])
    if not value then
        if words[index] then
            cecho(string.format("\n<red>[%s]<reset> '%s' is not a valid number\n", component, words[index]))
        end
        cecho(string.format("\n<red>[%s]<reset> %s\n", component, usage_msg))
        return nil
    end
    return value
end

--- Parse argument from allowed choices
--- @param words table Parsed words
--- @param index number Word index to parse
--- @param choices table Array of allowed values
--- @param component string Component name for error messages
--- @param default any Optional default value if not present
--- @return string|any Choice value or default, or nil on invalid choice (with error displayed)
function f2t_parse_choice(words, index, choices, component, default)
    local value = words[index] or default

    if not value then
        cecho(string.format("\n<red>[%s]<reset> Missing required argument\n", component))
        cecho(string.format("\n<dim_grey>Allowed values: %s<reset>\n", table.concat(choices, ", ")))
        return nil
    end

    -- Check if value is in choices
    for _, choice in ipairs(choices) do
        if value == choice then
            return value
        end
    end

    -- Invalid choice
    cecho(string.format("\n<red>[%s]<reset> Invalid value '%s'\n", component, value))
    cecho(string.format("\n<dim_grey>Allowed values: %s<reset>\n", table.concat(choices, ", ")))
    return nil
end

f2t_debug_log("[shared] Argument parsing utilities initialized")
