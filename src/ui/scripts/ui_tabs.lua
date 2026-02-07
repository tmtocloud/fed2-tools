function ui_build_tabs()
  -- Place Overflow/Commodities tabs In Left Navigation Frame (default location)
  UI.tab_left = Adjustable.TabWindow:new(
    {
      name             = "UI.tab_left",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "5%",
      tabs             = {"Overflow", "Commodities"},
      activeTabStyle   = UI.style.active_tab_css,
      inactiveTabStyle = UI.style.inactive_tab_css,
      footerStyle      = UI.style.footer_css,
      centerStyle      = UI.style.center_css,
    },
    UI.left_frame
  )

  -- Build the box to split the right frame in half
  UI.vbox_right = Geyser.VBox:new(
      {
          name   = "UI.vbox_right",
          x      = 0,
          y      = 0,
          width  = "100%",
          height = "100%"
      },
      UI.right_frame
  )

  -- Place Map/Comms tabs on the top of the Right Navigation Frame (default location)
  UI.tab_top_right = Adjustable.TabWindow:new(
    {
      name             = "UI.tab_top_right",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "10%",
      tabs             = {"fedmap","Comm"},
      activeTabStyle   = UI.style.active_tab_css,
      inactiveTabStyle = UI.style.inactive_tab_css,
      footerStyle      = UI.style.footer_css,
      centerStyle      = UI.style.center_css,
    },
    UI.vbox_right
  )
  
  -- Place Cargo/Hauling/Trading tabs on the bottom of the Right Navigation Frame (default location)
  UI.tab_bottom_right = Adjustable.TabWindow:new(
    {
      name             = "UI.tab_bottom_right",
      x                = "0%",
      y                = "0%",
      width            = "100%",
      height           = "100%",
      tabBarHeight     = "10%",
      tabs             = {"Cargo","Hauling","Trading"},
      activeTabStyle   = UI.style.active_tab_css,
      inactiveTabStyle = UI.style.inactive_tab_css,
      footerStyle      = UI.style.footer_css,
      centerStyle      = UI.style.center_css,
    },
    UI.vbox_right
  )
end

-- populate our various tabs
function ui_build_tab_content()
  local text_size = 12

  --put map into map window
  UI.mapper = Geyser.Mapper:new(
    {
      name   = "fedmap",
      x      = 0,
      y      = 0, 
      width  = "100%",
      height = "100%",
    },
    UI.tab_top_right.fedmapcenter
  )

  --put overflow console in overflow tab
  UI.overflow_window = Geyser.MiniConsole:new(
    {
      name      = "UI.overflow_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    UI.tab_left.Overflowcenter
  )
  
  --put commodities console in commodities tab
  UI.commodities_window = Geyser.MiniConsole:new(
    {
      name      = "UI.commodities_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = text_size,
      color     = "black",
    },
    UI.tab_left.Commoditiescenter
  )
  
  --put chat console in chat tab
  UI.chat_window = Geyser.MiniConsole:new(
    {
      name      = "UI.chat_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    UI.tab_top_right.Commcenter
  )
    
  --put cargo console in cargo tab
  UI.cargo_window = Geyser.MiniConsole:new(
    {
      name      = "UI.cargo_window",
      x         = "0%",
      y         = "0%",
      width     = "100%",
      height    = "100%",
      autoWrap  = true,
      scrollBar = false,
      fontSize  = text_size,
      color     = "black",
    },
    UI.tab_bottom_right.Cargocenter
  )
  
  --put hauling container in hauling tab
  UI.hauling_container = Geyser.Container:new(
    {
      name   = "UI.hauling_container",
      x      = "0%",
      y      = "0%",
      width  = "100%",
      height = "100%",
    },
    UI.tab_bottom_right.Haulingcenter
  )
  
  -- Button bar at top
  UI.hauling_button_bar = Geyser.HBox:new(
    {
      name   = "UI.hauling_button_bar",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "25px",
    },
    UI.hauling_container
  )
  
  -- Cargo display window below button bar
  UI.hauling_window = Geyser.MiniConsole:new(
    {
      name      = "UI.hauling_window",
      x         = "0%",
      y         = "25px",
      width     = "100%",
      height    = "100%-25px",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = 12,
      color     = "black",
    },
    UI.hauling_container
  )

--put trading container in trading tab
  UI.trading_container = Geyser.Container:new(
    {
      name   = "UI.trading_container",
      x      = "0%",
      y      = "0%",
      width  = "100%",
      height = "100%",
    },
    UI.tab_bottom_right.Tradingcenter
  )
  
  -- Button bar at top
  UI.trading_button_bar = Geyser.HBox:new(
    {
      name   = "UI.trading_button_bar",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "25px",
    },
    UI.trading_container
  )
  
  -- Cargo display window below button bar
  UI.trading_window = Geyser.MiniConsole:new(
    {
      name      = "UI.trading_window",
      x         = "0%",
      y         = "25px",
      width     = "100%",
      height    = "100%-25px",
      autoWrap  = true,
      scrollBar = true,
      fontSize  = 12,
      color     = "black",
    },
    UI.trading_container
  )
end