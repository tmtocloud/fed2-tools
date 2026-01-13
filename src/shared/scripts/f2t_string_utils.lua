-- String utility functions

-- Strip ANSI/MUD color codes from a string
-- Handles formats like: %%bold%%, %%green%%, %%reset%%, etc.
function f2t_strip_color_codes(str)
    if not str then
        return ""
    end

    -- Remove all %%code%% patterns
    local cleaned = string.gsub(str, "%%%%[^%%]+%%%%", "")

    return cleaned
end

-- Clean a room name for display/storage
-- Removes color codes and trims whitespace
function f2t_clean_room_name(name)
    if not name then
        return ""
    end

    -- Strip color codes
    local cleaned = f2t_strip_color_codes(name)

    -- Trim leading/trailing whitespace
    cleaned = string.match(cleaned, "^%s*(.-)%s*$")

    return cleaned
end
