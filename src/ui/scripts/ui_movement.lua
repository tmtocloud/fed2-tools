UI.movement         = UI.movement or {}
UI.movement.visible = true

-- Build Movement Buttons
function ui_build_movement()
    ------------- Main Container -------------------------------
    UI.map_commands_container = Geyser.Container:new(
        {
            name   = "UI.map_commands_container",
            x      = "1%",
            y      = "-170px",
            width  = "25%",
            height = 180
        },
        UI.tab_top_right.fedmapcenter
    )

    ------------- IN/OUT Container -----------------------------
    UI.in_out_box = Geyser.Container:new(
        {
            name   = "UI.in_out_box",
            x      = "50%-40px",
            y      = 5,
            width  = 80,
            height = 22
        },
        UI.map_commands_container
    )

    ------------- IN Button ------------------------------------
    UI.button_in = Geyser.Label:new(
        {
            name    = "UI.button_in",
            x       = 0,
            y       = 0,
            width   = 37,
            height  = 22,
            message = "<center>IN</center>"
        },
        UI.in_out_box
    )

    UI.button_in:setStyleSheet(UI.style.button_css)
    UI.button_in:setClickCallback("ui_move_in")

    ------------- OUT Button -----------------------------------
    UI.button_out = Geyser.Label:new(
        {
            name    = "UI.button_out",
            x       = 42,
            y       = 0,
            width   = 37,
            height  = 22,
            message = "<center>OUT</center>"
        },
        UI.in_out_box
    )

    UI.button_out:setStyleSheet(UI.style.button_css)
    UI.button_out:setClickCallback("ui_move_out")

    ------------- Compass Container ----------------------------
    UI.cardinal_box = Geyser.Container:new(
        {
            name   = "UI.cardinal_box",
            x      = "50%-60px",
            y      = 32,
            width  = 120,
            height = 120
        },
        UI.map_commands_container
    )

    -- Button standards for compass
    local button_size = 35
    local button_gap  = 5

    ------------- NW Button ------------------------------------
    UI.button_nw = Geyser.Label:new(
        {
            name    = "UI.button_nw",
            x       = 0,
            y       = 0,
            width   = button_size,
            height  = button_size,
            message = "<center>NW</center>"
        },
        UI.cardinal_box
    )

    UI.button_nw:setStyleSheet(UI.style.button_css)
    UI.button_nw:setClickCallback("ui_move_nw")

    ------------- N Button -------------------------------------
    UI.button_n = Geyser.Label:new(
        {
            name    = "UI.button_n",
            x       = button_size + button_gap,
            y       = 0,
            width   = button_size,
            height  = button_size,
            message = "<center>N</center>"
        },
        UI.cardinal_box
    )

    UI.button_n:setStyleSheet(UI.style.button_css)
    UI.button_n:setClickCallback("ui_move_n")

    ------------- NE Button ------------------------------------
    UI.button_ne = Geyser.Label:new(
        {
            name    = "UI.button_ne",
            x       = (button_size + button_gap) * 2,
            y       = 0,
            width   = button_size,
            height  = button_size,
            message = "<center>NE</center>"
        },
        UI.cardinal_box
    )

    UI.button_ne:setStyleSheet(UI.style.button_css)
    UI.button_ne:setClickCallback("ui_move_ne")

    ------------- W Button -------------------------------------
    UI.button_w = Geyser.Label:new(
        {
            name    = "UI.button_w",
            x       = 0,
            y       = button_size + button_gap,
            width   = button_size,
            height  = button_size,
            message = "<center>W</center>"
        },
        UI.cardinal_box
    )

    UI.button_w:setStyleSheet(UI.style.button_css)
    UI.button_w:setClickCallback("ui_move_w")

    ------------- LOOK Button ----------------------------------
    UI.buttonLook = Geyser.Label:new(
        {
            name    = "UI.buttonLook",
            x       = button_size + button_gap,
            y       = button_size + button_gap,
            width   = button_size,
            height  = button_size,
            message = "<center>👁</center>"
        },
        UI.cardinal_box
    )

    UI.buttonLook:setStyleSheet(UI.style.button_css)
    UI.buttonLook:setClickCallback("ui_look")

    ------------- E Button -------------------------------------
    UI.button_e = Geyser.Label:new(
        {
            name    = "UI.button_e",
            x       = (button_size + button_gap) * 2,
            y       = button_size + button_gap,
            width   = button_size,
            height  = button_size,
            message = "<center>E</center>"
        },
        UI.cardinal_box
    )

    UI.button_e:setStyleSheet(UI.style.button_css)
    UI.button_e:setClickCallback("ui_move_e")

    ------------- SW Button ------------------------------------
    UI.button_sw = Geyser.Label:new(
        {
            name    = "UI.button_sw",
            x       = 0,
            y       = (button_size + button_gap) * 2,
            width   = button_size,
            height  = button_size,
            message = "<center>SW</center>"
        },
        UI.cardinal_box
    )

    UI.button_sw:setStyleSheet(UI.style.button_css)
    UI.button_sw:setClickCallback("ui_move_sw")

    ------------- S Button -------------------------------------
    UI.button_s = Geyser.Label:new(
        {
            name    = "UI.button_s",
            x       = button_size + button_gap,
            y       = (button_size + button_gap) * 2,
            width   = button_size,
            height  = button_size,
            message = "<center>S</center>"
        },
        UI.cardinal_box
    )

    UI.button_s:setStyleSheet(UI.style.button_css)
    UI.button_s:setClickCallback("ui_move_s")

    ------------- SE Button ------------------------------------
    UI.button_se = Geyser.Label:new(
        {
            name    = "UI.button_se",
            x       = (button_size + button_gap) * 2,
            y       = (button_size + button_gap) * 2,
            width   = button_size,
            height  = button_size,
            message = "<center>SE</center>"
        },
        UI.cardinal_box
    )

    UI.button_se:setStyleSheet(UI.style.button_css)
    UI.button_se:setClickCallback("ui_move_se")

    ------------- UP/DOWN Container ----------------------------
    UI.vertical_box = Geyser.Container:new(
        {
            name   = "UI.vertical_box",
            x      = "50%+60px",
            y      = 61,
            width  = 70,
            height = 120,
        },
        UI.map_commands_container
    )

    ------------- UP Button ------------------------------------
    UI.button_up = Geyser.Label:new(
        {
            name    = "UI.button_up",
            x       = 0,
            y       = 0,
            width   = 25,
            height  = 28,
            message = "<center>UP</center>"
        },
        UI.vertical_box
    )

    UI.button_up:setStyleSheet(UI.style.button_css)
    UI.button_up:setClickCallback("ui_move_up")

    ------------- DOWN Button ----------------------------------
    UI.button_down = Geyser.Label:new(
        {
            name    = "UI.button_down",
            x       = 0,
            y       = 30,
            width   = 25,
            height  = 28,
            message = "<center>DN</center>"
        },
        UI.vertical_box
    )

    UI.button_down:setStyleSheet(UI.style.button_css)
    UI.button_down:setClickCallback("ui_move_down")

    ------------- Show/Hide Button -----------------------------
    UI.button_show_hide = Geyser.Label:new(
        {
            name    = "UI.button_show_hide",
            x       = "100%",
            y       = 127,
            width   = 80,
            height  = 18,
            message = "<center>Hide Buttons</center>"
        },
        UI.map_commands_container
    )

    UI.button_show_hide:setStyleSheet(UI.style.toggle_button_css)
    UI.button_show_hide:setClickCallback("ui_toggle_movement_buttons")

    -------------- Board Button --------------------------------
    UI.button_board = Geyser.Label:new(
        {
            name    = "UI.button_board",
            x       = "0%-7px",
            y       = 5,
            width   = 25,
            height  = 20,
            message = "<center>B</center>"
        },
        UI.map_commands_container
    )

    UI.button_board:setStyleSheet(UI.style.button_css)
    UI.button_board:setClickCallback("ui_board")

    -- Store button and action references for easy access
    UI.movement.directions = {
        n      = { button = UI.button_n,     action = "ui_move_n"    },
        ne     = { button = UI.button_ne,    action = "ui_move_ne"   },
        e      = { button = UI.button_e,     action = "ui_move_e"    },
        se     = { button = UI.button_se,    action = "ui_move_se"   },
        s      = { button = UI.button_s,     action = "ui_move_s"    },
        sw     = { button = UI.button_sw,    action = "ui_move_sw"   },
        w      = { button = UI.button_w,     action = "ui_move_w"    },
        nw     = { button = UI.button_nw,    action = "ui_move_nw"   },
        up     = { button = UI.button_up,    action = "ui_move_up"   },
        down   = { button = UI.button_down,  action = "ui_move_down" },
        ["in"] = { button = UI.button_in,    action = "ui_move_in"   },
        out    = { button = UI.button_out,   action = "ui_move_out"  },
        board  = { button = UI.button_board, action = "ui_board"     } 
    }
end

-- Toggle Movement Buttons Visibility
function ui_toggle_movement_buttons()
    if UI.movement.visible then
        UI.cardinal_box:hide()
        UI.vertical_box:hide()
        UI.in_out_box:hide()
        UI.button_show_hide:echo("<center>Show Buttons</center>")
        UI.button_board:hide()
        UI.movement.visible = false
    else
        UI.cardinal_box:show()
        UI.vertical_box:show()
        UI.in_out_box:show()
        UI.button_show_hide:echo("<center>Hide Buttons</center>")
        UI.button_board:show()
        UI.movement.visible = true
    end
end

function ui_move_n()
    send("n", false)
end

function ui_move_ne()
    send("ne", false)
end

function ui_move_e()
    send("e", false)
end

function ui_move_se()
    send("se", false)
end

function ui_move_s()
    send("s", false)
end

function ui_move_sw()
    send("sw", false)
end

function ui_move_w()
    send("w", false)
end

function ui_move_nw()
    send("nw", false)
end

function ui_move_up()
    send("up", false)
end

function ui_move_down()
    send("down", false)
end

function ui_move_in()
    send("in", false)
end

function ui_move_out()
    send("out", false)
end

function ui_look()
    send("look", false)
end

function ui_board()
    send("board", false)
end
