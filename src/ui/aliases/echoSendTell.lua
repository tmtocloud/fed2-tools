-- @patterns:
--   - pattern: ^(?i:tb|tell)\s+(\w+)\s+(.+)$

send(matches[1], false)
ui_chat_window:cecho('<ansiRed>You tell ' .. matches[2] .. ': "' .. matches[3] .. '"\n')