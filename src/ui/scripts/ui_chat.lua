function ui_echo_com()
    UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.com.from .. ': "' .. gmcp.comm.com.message .. '"\n')
end

function ui_echo_tell()
    UI.chat_window:cecho('<ansiRed>' .. gmcp.comm.tell.from .. ': "' .. gmcp.comm.tell.message .. '"\n')
end

function ui_echo_say()
    UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.say.from .. ': "' .. gmcp.comm.say.message .. '"\n')
end