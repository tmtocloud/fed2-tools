function ui_echo_com()
  UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.com.from .. ' comms: "' .. gmcp.comm.com.message .. '"\n')
end

function ui_echo_tell()
  UI.chat_window:cecho('<ansiRed>' .. gmcp.comm.tell.from .. ' tight beams you: "' .. gmcp.comm.tell.message .. '"\n')
end

function ui_echo_say()
  UI.chat_window:cecho('<ansiCyan>' .. gmcp.comm.say.from .. ' says: "' .. gmcp.comm.say.message .. '"\n')
end

-- Register the GMCP event handlers
if F2T_CHATCOM_HANDLER_ID then
    killAnonymousEventHandler(F2T_CHATCOM_HANDLER_ID)
end
F2T_CHATCOM_HANDLER_ID = registerAnonymousEventHandler("gmcp.comm.com", "ui_echo_com")

f2t_debug_log("[ui] GMCP Chat Com handler registered")

if F2T_CHATTELL_HANDLER_ID then
    killAnonymousEventHandler(F2T_CHATTELL_HANDLER_ID)
end
F2T_CHATTELL_HANDLER_ID = registerAnonymousEventHandler("gmcp.comm.tell", "ui_echo_tell")

f2t_debug_log("[ui] GMCP Chat Tell handler registered")

if F2T_CHATSAY_HANDLER_ID then
    killAnonymousEventHandler(F2T_CHATSAY_HANDLER_ID)
end
F2T_CHATSAY_HANDLER_ID = registerAnonymousEventHandler("gmcp.comm.say", "ui_echo_say")

f2t_debug_log("[ui] GMCP Chat Say handler registered")