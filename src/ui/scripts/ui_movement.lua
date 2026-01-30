ui_movement         = ui_movement or {}
ui_movement.visible = true

-- Build Movement Buttons
function ui_build_movement()
  ------------- Main Container -------------------------------
  ui_map_commands_container = Geyser.Container:new(
    {
      name   = "ui_map_commands_container",
      x      = "1%",
      y      = "-170px",
      width  = "25%",
      height = 180
    },
    ui_tab_top_right.fedmapcenter
  )
  
  ------------- IN/OUT Container -----------------------------
  ui_in_out_box = Geyser.Container:new(
    {
      name   = "ui_in_out_box",
      x      = "50%-40px",
      y      = 5,
      width  = 80,
      height = 22
    },
    ui_map_commands_container
  )
  
  ------------- IN Button ------------------------------------
  ui_button_in = Geyser.Label:new(
    {
      name    = "ui_button_in",
      x       = 0,
      y       = 0,
      width   = 37,
      height  = 22,
      message = "<center>IN</center>"
    },
    ui_in_out_box
  )

  ui_button_in:setStyleSheet(ui_style.button_css)
  ui_button_in:setClickCallback("ui_move_in")
  
  ------------- OUT Button -----------------------------------
  ui_button_out = Geyser.Label:new(
    {
      name    = "ui_button_out",
      x       = 42,
      y       = 0,
      width   = 37,
      height  = 22,
      message = "<center>OUT</center>"
    },
    ui_in_out_box
  )

  ui_button_out:setStyleSheet(ui_style.button_css)
  ui_button_out:setClickCallback("ui_move_out")
  
  ------------- Compass Container ----------------------------
  ui_cardinal_box = Geyser.Container:new(
    {
      name   = "ui_cardinal_box",
      x      = "50%-60px",
      y      = 32,
      width  = 120,
      height = 120
    },
    ui_map_commands_container
  )
  
  -- Button standards for compass
  local button_size = 35
  local button_gap  = 5
  
  ------------- NW Button ------------------------------------
  ui_button_nw = Geyser.Label:new(
    {
      name    = "ui_button_nw",
      x       = 0,
      y       = 0,
      width   = button_size,
      height  = button_size,
      message = "<center>NW</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_nw:setStyleSheet(ui_style.button_css)
  ui_button_nw:setClickCallback("ui_move_nw")
  
  ------------- N Button -------------------------------------
  ui_button_n = Geyser.Label:new(
    {
      name    = "ui_button_n",
      x       = button_size + button_gap,
      y       = 0,
      width   = button_size,
      height  = button_size,
      message = "<center>N</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_n:setStyleSheet(ui_style.button_css)
  ui_button_n:setClickCallback("ui_move_n")
  
  ------------- NE Button ------------------------------------
  ui_button_ne = Geyser.Label:new(
    {
      name    = "ui_button_ne",
      x       = (button_size + button_gap) * 2,
      y       = 0,
      width   = button_size,
      height  = button_size,
      message = "<center>NE</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_ne:setStyleSheet(ui_style.button_css)
  ui_button_ne:setClickCallback("ui_move_ne")
  
  ------------- W Button -------------------------------------
  ui_button_w = Geyser.Label:new(
    {
      name    = "ui_button_w",
      x       = 0,
      y       = button_size + button_gap,
      width   = button_size,
      height  = button_size,
      message = "<center>W</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_w:setStyleSheet(ui_style.button_css)
  ui_button_w:setClickCallback("ui_move_w")
  
  ------------- LOOK Button ----------------------------------
  ui_buttonLook = Geyser.Label:new(
    {
      name    = "ui_buttonLook",
      x       = button_size + button_gap,
      y       = button_size + button_gap,
      width   = button_size,
      height  = button_size,
      message = "<center>👁</center>"
    },
    ui_cardinal_box
  )
  
  ui_buttonLook:setStyleSheet(ui_style.button_css)
  ui_buttonLook:setClickCallback("ui_look")
  
  ------------- E Button -------------------------------------
  ui_button_e = Geyser.Label:new(
    {
      name    = "ui_button_e",
      x       = (button_size + button_gap) * 2,
      y       = button_size + button_gap,
      width   = button_size,
      height  = button_size,
      message = "<center>E</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_e:setStyleSheet(ui_style.button_css)
  ui_button_e:setClickCallback("ui_move_e")
  
  ------------- SW Button ------------------------------------
  ui_button_sw = Geyser.Label:new(
    {
      name    = "ui_button_sw",
      x       = 0,
      y       = (button_size + button_gap) * 2,
      width   = button_size,
      height  = button_size,
      message = "<center>SW</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_sw:setStyleSheet(ui_style.button_css)
  ui_button_sw:setClickCallback("ui_move_sw")
  
  ------------- S Button -------------------------------------
  ui_button_s = Geyser.Label:new(
    {
      name    = "ui_button_s",
      x       = button_size + button_gap,
      y       = (button_size + button_gap) * 2,
      width   = button_size,
      height  = button_size,
      message = "<center>S</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_s:setStyleSheet(ui_style.button_css)
  ui_button_s:setClickCallback("ui_move_s")
  
  ------------- SE Button ------------------------------------
  ui_button_se = Geyser.Label:new(
    {
      name    = "ui_button_se",
      x       = (button_size + button_gap) * 2,
      y       = (button_size + button_gap) * 2,
      width   = button_size,
      height  = button_size,
      message = "<center>SE</center>"
    },
    ui_cardinal_box
  )
  
  ui_button_se:setStyleSheet(ui_style.button_css)
  ui_button_se:setClickCallback("ui_move_se")
  
  ------------- UP/DOWN Container ----------------------------
  ui_vertical_box = Geyser.Container:new(
    {
      name   = "ui_vertical_box",
      x      = "50%+60px",
      y      = 61,
      width  = 70,
      height = 120,
    },
    ui_map_commands_container
  )
  
  ------------- UP Button ------------------------------------
  ui_button_up = Geyser.Label:new(
    {
      name    = "ui_button_up",
      x       = 0,
      y       = 0,
      width   = 25,
      height  = 28,
      message = "<center>UP</center>"
    },
    ui_vertical_box
  )
  
  ui_button_up:setStyleSheet(ui_style.button_css)
  ui_button_up:setClickCallback("ui_move_up")
  
  ------------- DOWN Button ----------------------------------
  ui_button_down = Geyser.Label:new(
    {
      name    = "ui_button_down",
      x       = 0,
      y       = 30,
      width   = 25,
      height  = 28,
      message = "<center>DN</center>"
    },
    ui_vertical_box
  )
  
  ui_button_down:setStyleSheet(ui_style.button_css)
  ui_button_down:setClickCallback("ui_move_down")
  
  ------------- Show/Hide Button -----------------------------
  ui_button_show_hide = Geyser.Label:new(
    {
      name    = "ui_button_show_hide",
      x       = "100%",
      y       = 127,
      width   = 80,
      height  = 18,
      message = "<center>Hide Buttons</center>"
    },
    ui_map_commands_container
  )
  
  ui_button_show_hide:setStyleSheet(ui_style.toggle_button_css)
  ui_button_show_hide:setClickCallback("ui_toggle_movement_buttons")
  
  ------------- Buy Fuel Button ------------------------------
  ui_button_buy_fuel = Geyser.Label:new(
    {
      name    = "ui_button_buy_fuel",
      x       = "100%+85px",
      y       = 127,
      width   = 55,
      height  = 18,
      message = "<center>Buy Fuel</center>"
    },
    ui_map_commands_container
  )
  
  ui_button_buy_fuel:setStyleSheet(ui_style.button_css)
  ui_button_buy_fuel:setClickCallback("ui_buy_fuel")
  
 ------------- Score Button -------------------------------
  ui_button_score = Geyser.Label:new(
    {
      name    = "ui_button_score",
      x       = "100%+173px",
      y       = 100,
      width   = 25,
      height  = 20,
      message = "<center>SC</center>"
    },
    ui_map_commands_container
  )
  
  ui_button_score:setStyleSheet(ui_style.button_css)
  ui_button_score:setClickCallback("ui_score")

  ------------- Status Button -------------------------------
  ui_button_status = Geyser.Label:new(
    {
      name    = "ui_button_status",
      x       = "100%+200px",
      y       = 100,
      width   = 25,
      height  = 20,
      message = "<center>ST</center>"
    },
    ui_map_commands_container
  )
  
  ui_button_status:setStyleSheet(ui_style.button_css)
  ui_button_status:setClickCallback("ui_status")

  -------------- Board Button --------------------------------
  ui_button_board = Geyser.Label:new(
    {
      name    = "ui_button_board",
      x       = "0%-7px",
      y       = 5,
      width   = 25,
      height  = 20,
      message = "<center>B</center>"
    },
    ui_map_commands_container
  )
  
  ui_button_board:setStyleSheet(ui_style.button_css)
  ui_button_board:setClickCallback("ui_board")
  
  -- Store button and action references for easy access
  ui_movement.directions = {
    n      = { button = ui_button_n,     action = "ui_move_n"    },
    ne     = { button = ui_button_ne,    action = "ui_move_ne"   },
    e      = { button = ui_button_e,     action = "ui_move_e"    },
    se     = { button = ui_button_se,    action = "ui_move_se"   },
    s      = { button = ui_button_s,     action = "ui_move_s"    },
    sw     = { button = ui_button_sw,    action = "ui_move_sw"   },
    w      = { button = ui_button_w,     action = "ui_move_w"    },
    nw     = { button = ui_button_nw,    action = "ui_move_nw"   },
    up     = { button = ui_button_up,    action = "ui_move_up"   },
    down   = { button = ui_button_down,  action = "ui_move_down" },
    ["in"] = { button = ui_button_in,    action = "ui_move_in"   },
    out    = { button = ui_button_out,   action = "ui_move_out"  },
    board  = { button = ui_button_board, action = "ui_board"    },
  }
end

-- Toggle Movement Buttons Visibility
function ui_toggle_movement_buttons()
  if ui_movement.visible then
    ui_cardinal_box:hide()
    ui_vertical_box:hide()
    ui_in_out_box:hide()
    ui_button_show_hide:echo("<center>Show Buttons</center>")
    ui_button_board:hide()
    ui_button_buy_fuel:hide()
    ui_button_score:hide()
    ui_button_status:hide()
    ui_movement.visible = false
  else
    ui_cardinal_box:show()
    ui_vertical_box:show()
    ui_in_out_box:show()
    ui_button_show_hide:echo("<center>Hide Buttons</center>")
    ui_button_board:show()
    ui_button_buy_fuel:show()
    ui_button_score:show()
    ui_button_status:show()
    ui_movement.visible = true
  end
end

function ui_room_info_event_handler()
  if ui_gmcp_room_handler then killAnonymousEventHandler(ui_gmcp_room_handler) end
  ui_gmcp_room_handler = registerAnonymousEventHandler("gmcp.room.info", ui_on_gmcp_room_info)
end

-- Run on every update to GMCP room info
function ui_on_gmcp_room_info()
  local exits = {}

  -- get all the gmcp room exits and add them to valid exits
  for exit, _ in pairs(gmcp.room.info.exits) do
    table.insert(exits, exit:lower())
  end

  -- Detect shuttlepad or orbit and add board to valid exits
  if f2t_has_value(gmcp.room.info.flags, "shuttlepad") or f2t_has_value(gmcp.room.info.flags, "orbit") or gmcp.room.info.orbit then table.insert(exits, "board") end

  for dir, dirData in pairs(ui_movement.directions) do
    if f2t_has_value(exits, dir) then
      dirData.button:setStyleSheet(ui_style.button_css)
      dirData.button:setClickCallback(dirData.action)
    else
      dirData.button:setStyleSheet(ui_style.disabled_button_css)
      dirData.button:setClickCallback(function() end)
    end
  end
  
  -- grey out buy fuel if in space
  if f2t_has_value(gmcp.room.info.flags, "space") then
    ui_button_buy_fuel:setStyleSheet(ui_style.disabled_button_css)
    ui_button_buy_fuel:setClickCallback(function() end)
  else
    ui_button_buy_fuel:setStyleSheet(ui_style.button_css)
    ui_button_buy_fuel:setClickCallback("ui_buy_fuel")
  end
end

function ui_move_n()
  send("n")
end

function ui_move_ne()
  send("ne")
end

function ui_move_e()
  send("e")
end

function ui_move_se()
  send("se")
end

function ui_moveS()
  send("s")
end

function ui_move_sw()
  send("sw")
end

function ui_move_w()
  send("w")
end

function ui_move_nw()
  send("nw")
end

function ui_move_up()
  send("up")
end

function ui_move_down()
  send("down")
end

function ui_move_in()
  send("in")
end

function ui_move_out()
  send("out")
end

function ui_look()
  send("look")
end

function ui_board()
  send("board")
end

function ui_buy_fuel()
  send("buy fuel")
end

function ui_score()
  send("score")
end

function ui_status()
  send("status")
end