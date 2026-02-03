-- @patterns:
--   - pattern: ^(?i:tb|tell)\s+(\w+)\s+(.+)$
f2t_ui_register_alias("echoSendTell")

send(matches[1], false)
UI.chat_window:cecho('<ansiRed>You tell ' .. matches[2] .. ': "' .. matches[3] .. '"\n')