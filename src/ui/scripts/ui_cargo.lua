--echoes cargo information to the cargo console
function ui_cargo()
  local cargo = gmcp.char.ship.cargo --this is a table, and possibly a table of tables

  if cargo then
    clearWindow("ui_cargo_window") --reset the window, no need to have old cargo sticking around

    ui_cargo_window:cecho("<b>Current Cargo:</b>\n")

    for key, value in pairs(cargo) do
      ui_cargo_window:cecho("<b>"..value.commodity) --name of the commodity
      ui_cargo_window:cecho("</b> at ")
      ui_cargo_window:echo(value.cost) --how much you paid for it
      ui_cargo_window:echo("/")
      ui_cargo_window:echo(value.base) --default price of commodity

      if value.base-value.cost >=0 then
        ui_cargo_window:cecho(" (<green>+"..value.base-value.cost)
      else
        ui_cargo_window:cecho(" (<red>-"..value.base-value.cost)
      end

      ui_cargo_window:cecho("<reset>) from ")
      ui_cargo_window:cecho("<b>"..value.origin) --what planet you bought it from
      ui_cargo_window:cecho("</b>\n")
    end

    ui_cargo_window:echo("\n")
  end
end

-- Register the GMCP event handler
if F2T_CARGO_HANDLER_ID then
    killAnonymousEventHandler(F2T_CARGO_HANDLER_ID)
end
F2T_CARGO_HANDLER_ID = registerAnonymousEventHandler("gmcp.char.ship.cargo", "ui_cargo")

f2t_debug_log("[ui] GMCP Cargo handler registered")