-- Build the frames to hold everything
function ui_build_frames()
-- Left Navigation Frame
  UI.left_frame = Adjustable.Container:new(
    { 
      name          = "UI.left_frame",
      titleText     = "UI.left_frame",
      x             = "0%",
      y             = "0%",
      width         = "15%",
      height        = "100%",
      adjLabelstyle = UI.style.frame_css, 
      attached      = "left" 
    }
  )
  UI.left_frame:connectToBorder("left")
  UI.left_frame:lockContainer("border")

-- Right Navigation Frame
  UI.right_frame = Adjustable.Container:new(
    { 
      name          = "UI.right_frame",
      titleText     = "UI.right_frame",
      x             = "-20%",
      y             = "0%",
      width         = "20%",
      height        = "100%",
      adjLabelstyle = UI.style.frame_css, 
      attached      = "right" 
    }
  )
  UI.right_frame:connectToBorder("right")
  UI.right_frame:lockContainer("border")

  -- Build the box to split the right frame in half
  UI.vbox_right = Geyser.VBox:new(
    {
      name   = "UI.vbox_right",
      x      = 0,
      y      = 0,
      width  = "100%",
      height = "100%",
    },
    UI.right_frame
  )

  -- Top Status Frame
  UI.top_frame = Adjustable.Container:new(
    {
      name          = "UI.top_frame",
      titleText     = "UI.top_frame",
      x             = "15%",
      y             = "0%",
      width         = "65%",
      height        = "5%",
      adjLabelstyle = UI.style.frame_css, 
      attached      = "top" 
    }
  )
  UI.top_frame:connectToBorder("left")
  UI.top_frame:connectToBorder("right")
  UI.top_frame:lockContainer("border")

-- Enable Adjustable Containers (Tabs), users can move tabs from default starting positions as they wish
  Adjustable.Container:doAll(function(self) self:addConnectMenu() end)
end

