-- Build the frames to hold everything
function ui_build_frames()
-- Left Navigation Frame
  ui_left_frame = Adjustable.Container:new(
    { 
      name          = "ui_left_frame",
      titleText     = "ui_left_frame",
      x             = "0%",
      y             = "0%",
      width         = "15%",
      height        = "100%",
      adjLabelstyle = ui_style.frame_css, 
      attached      = "left" 
    }
  )
  ui_left_frame:connectToBorder("left")
  ui_left_frame:lockContainer("border")

-- Right Navigation Frame
  ui_right_frame = Adjustable.Container:new(
    { 
      name          = "ui_right_frame",
      titleText     = "ui_right_frame",
      x             = "-20%",
      y             = "0%",
      width         = "20%",
      height        = "100%",
      adjLabelstyle = ui_style.frame_css, 
      attached      = "right" 
    }
  )
  ui_right_frame:connectToBorder("right")
  ui_right_frame:lockContainer("border")

  -- Build the box to split the right frame in half
  ui_vboxRight = Geyser.VBox:new(
    {
      name   = "ui_vboxRight",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "100%",
    },
    ui_right_frame
  )

  -- Top Status Frame
  ui_top_frame = Adjustable.Container:new(
    {
      name          = "ui_top_frame",
      titleText     = "ui_top_frame",
      x             = "15%",
      y             = "0%",
      width         = "65%",
      height        = "5%",
      adjLabelstyle = ui_style.frame_css, 
      attached      = "top" 
    }
  )
  ui_top_frame:connectToBorder("left")
  ui_top_frame:connectToBorder("right")
  ui_top_frame:lockContainer("border")

-- Enable Adjustable Containers (Tabs), users can move tabs from default starting positions as they wish
  Adjustable.Container:doAll(function(self) self:addConnectMenu() end)
end

