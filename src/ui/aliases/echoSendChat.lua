-- @patterns:
--   - pattern: ^(?:(?i:(com|comm|say))\s+(.*)|(''|'|")\s*(.*))$

local display
local text = ""

if matches[2] ~= "" then
    text = matches[3] or ""
else
    text = matches[5] or ""
end

local speaker = gmcp.char.vitals.name

send(matches[1], false)

-- This is ansiCyan but a few shades darker to distinguish between self and others
UI.chat_window:hecho('#4fa3a3' .. speaker .. ': "' .. text .. '"\n')