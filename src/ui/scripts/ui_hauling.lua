function ui_hauling()
  ------------- Work Button --------------------------------
  UI.button_work = Geyser.Label:new(
    {
      name    = "UI.button_work",
      --x       = "100%+160px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>W</center>"
    },
    UI.hauling_button_bar
  )
  
  UI.button_work:setStyleSheet(UI.style.button_css)
  UI.button_work:setClickCallback("ui_work")
  
  ------------- Collect Button -------------------------------
  UI.button_collect = Geyser.Label:new(
    {
      name    = "UI.button_collect",
      --x       = "100%+187px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>C</center>"
    },
    UI.hauling_button_bar
  )
  
  UI.button_collect:setStyleSheet(UI.style.button_css)
  UI.button_collect:setClickCallback("ui_collect")

  ------------- Deliver Button -------------------------------
  UI.button_deliver = Geyser.Label:new(
    {
      name    = "UI.button_deliver",
      --x       = "100%+214px",
      --y       = 127,
      --width   = 25,
      --height  = 20,
      message = "<center>D</center>"
    },
    UI.hauling_button_bar
  )
  UI.button_deliver:setStyleSheet(UI.style.button_css)
  UI.button_deliver:setClickCallback("ui_deliver")
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