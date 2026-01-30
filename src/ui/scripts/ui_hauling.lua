function ui_hauling()
  ------------- Work Button --------------------------------
  ui_button_work = Geyser.Label:new(
    {
      name    = "ui_button_work",
      --x       = "100%+160px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>W</center>"
    },
    ui_hauling_button_bar
  )
  
  ui_button_work:setStyleSheet(ui_style.button_css)
  ui_button_work:setClickCallback("ui_work")
  
  ------------- Collect Button -------------------------------
  ui_button_collect = Geyser.Label:new(
    {
      name    = "ui_button_collect",
      --x       = "100%+187px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>C</center>"
    },
    ui_hauling_button_bar
  )
  
  ui_button_collect:setStyleSheet(ui_style.button_css)
  ui_button_collect:setClickCallback("ui_collect")

  ------------- Deliver Button -------------------------------
  ui_button_deliver = Geyser.Label:new(
    {
      name    = "ui_button_deliver",
      --x       = "100%+214px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>D</center>"
    },
    ui_hauling_button_bar
  )
  ui_button_deliver:setStyleSheet(ui_style.button_css)
  ui_button_deliver:setClickCallback("ui_deliver")
 end
 
function ui_work()
  send("work")
end

function ui_collect()
  send("collect")
end

function ui_deliver()
  send("deliver")
end