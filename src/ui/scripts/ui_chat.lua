function ui_echo_com()
    UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.com.from .. ' comms: "' .. gmcp.comm.com.message .. '"\n')
end

function ui_echo_tell()
    UI.chat_window:cecho('<ansiRed>' .. gmcp.comm.tell.from .. ' tight beams you: "' .. gmcp.comm.tell.message .. '"\n')
end

function ui_echo_say()
    UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.say.from .. ' says: "' .. gmcp.comm.say.message .. '"\n')
end