-- @patterns:
--   - pattern: ^Your comm unit lights up as your brokers, Messrs Trum.*
--     type: regex
--   - pattern: ^requested spot market p.*
--     type: regex
--   - pattern: .*is not currently trading in this commodity$
--     type: regex

-- If we're in profit search mode, hide command spam
if ui_trading_data.profit_search and ui_trading_data.profit_search.active then
  deleteLine()

  return
end