-- Table utility functions for fed2-tools

-- Check if a table contains a specific value
-- Returns true if found, false otherwise
function f2t_has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- Get sorted keys from a table
-- Returns array of keys sorted alphabetically
function f2t_table_get_sorted_keys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- Count the number of keys in a table (works for hash tables)
-- Returns the count of all key-value pairs
function f2t_table_count_keys(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
