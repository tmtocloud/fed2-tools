-- @patterns:
--   - pattern: ^(?:(?i:(com|comm|say))\s+(.*)|(''|'|")\s*(.*))$

local display
local text = ""

if matches[2] ~= "" then
  display = matches[2]:lower()
  text = matches[3] or ""
else
  display = "say"
  text = matches[5] or ""
end

send(matches[1], false)
UI.chat_window:cecho('<ansiCyan>You ' .. display .. ': "' .. text .. '"\n')