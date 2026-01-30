function ui_build_tabs()
  -- Place Overflow/Commodities tabs In Left Navigation Frame (default location)
  ui_tab_left = Adjustable.TabWindow:new(
    {
      name             = "ui_tab_left",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "5%",
      tabs             = {"Overflow", "Commodities"},
      activeTabStyle   = ui_style.active_tab_css,
      inactiveTabStyle = ui_style.inactive_tab_css,
      footerStyle      = ui_style.footer_css,
      centerStyle      = ui_style.center_css,
    },
    ui_left_frame
  )
  
  -- Place Map/Comms tabs on the top of the Right Navigation Frame (default location)
  ui_tab_top_right = Adjustable.TabWindow:new(
    {
      name             = "ui_tab_top_right",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "10%",
      tabs             = {"fedmap","Comm"},
      activeTabStyle   = ui_style.active_tab_css,
      inactiveTabStyle = ui_style.inactive_tab_css,
      footerStyle      = ui_style.footer_css,
      centerStyle      = ui_style.center_css,
    },
    ui_vbox_right
  )
  
  -- Place Cargo/Hauling/Trading tabs on the bottom of the Right Navigation Frame (default location)
  ui_tab_bottom_right = Adjustable.TabWindow:new(
    {
      name             = "ui_tab_bottom_right",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "10%",
      tabs             = {"Cargo","Hauling","Trading"},
      activeTabStyle   = ui_style.active_tab_css,
      inactiveTabStyle = ui_style.inactive_tab_css,
      footerStyle      = ui_style.footer_css,
      centerStyle      = ui_style.center_css,
    },
    ui_vbox_right
  )
end

function ui_update_tabs_for_rank()
  local rank = (gmcp.char and gmcp.char.vitals and gmcp.char.vitals.rank) or {}
  local rank_level = ui_ranks[rank] or 0

  -- Hauling: only rank 1+
  if rank_level < 1 then
    ui_tab_bottom_right:removeTab("Hauling")
  else
    if not table.contains(ui_tab_bottom_right.tabs, "Hauling") then
      ui_tab_bottom_right:addTab("Hauling", 2)
    end
  end

  -- Trading: only rank 4+
  if rank_level < 4 then
    ui_tab_bottom_right:removeTab("Trading")
  else
    if not table.contains(ui_tab_bottom_right.tabs, "Trading") then
      ui_tab_bottom_right:addTab("Trading", 3)
    end
  end
end

-- populate our various tabs
function ui_build_tab_content()
  local text_size = 12

  --put map into map window
  ui_mapper = Geyser.Mapper:new(
    {
      name   = "fedmap",
      x      = 0,
      y      = 0, 
      width  = "100%",
      height = "100%",
    },
    ui_tab_top_right.fedmapcenter
  )

  --put overflow console in overflow tab
  ui_overflow_window = Geyser.MiniConsole:new(
    {
      name      = "ui_overflow_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    ui_tab_left.Overflowcenter
  )
  
  --put commodities console in commodities tab
  ui_commodities_window = Geyser.MiniConsole:new(
    {
      name      = "ui_commodities_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = text_size,
      color     = "black",
    },
    ui_tab_left.Commoditiescenter
  )
  
  --put chat console in chat tab
  ui_chat_window = Geyser.MiniConsole:new(
    {
      name      = "ui_chat_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    ui_tab_top_right.Commcenter
  )
    
  --put cargo console in cargo tab
  ui_cargo_window = Geyser.MiniConsole:new(
    {
      name      = "ui_cargo_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    ui_tab_bottom_right.Cargocenter
  )
  
  --put hauling container in hauling tab
  ui_hauling_container = Geyser.Container:new(
    {
      name   = "ui_hauling_container",
      x      = "0%",
      y      = "0%",
      width  = "100%",
      height = "100%",
    },
    ui_tab_bottom_right.Haulingcenter
  )
  
  -- Button bar at top
  ui_hauling_button_bar = Geyser.HBox:new(
    {
      name   = "ui_hauling_button_bar",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "25px",
    },
    ui_hauling_container
  )
  
  -- Cargo display window below button bar
  ui_hauling_window = Geyser.MiniConsole:new(
    {
      name      = "ui_hauling_window",
      x         = "0%",
      y         = "25px",
      width     = "100%",
      height    = "100%-25px",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = 12,
      color     = "black",
    },
    ui_hauling_container
  )

--put trading container in trading tab
  ui_trading_container = Geyser.Container:new(
    {
      name   = "ui_trading_container",
      x      = "0%",
      y      = "0%",
      width  = "100%",
      height = "100%",
    },
    ui_tab_bottom_right.Tradingcenter
  )
  
  -- Button bar at top
  ui_trading_button_bar = Geyser.HBox:new(
    {
      name   = "ui_trading_button_bar",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "25px",
    },
    ui_trading_container
  )
  
  -- Cargo display window below button bar
  ui_trading_window = Geyser.MiniConsole:new(
    {
      name      = "ui_trading_window",
      x         = "0%",
      y         = "25px",
      width     = "100%",
      height    = "100%-25px",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = 12,
      color     = "black",
    },
    ui_trading_container
  )
end