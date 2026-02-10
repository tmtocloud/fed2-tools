-- @patterns:
--   - pattern: ^(?i:tb|tell)\s+(\w+)\s+(.+)$

local speaker = gmcp.char.vitals.name

send(matches[1], false)

UI.chat_window:hecho('#FF5C5C→ ' .. matches[2] .. ': "' .. matches[3] .. '"\n')