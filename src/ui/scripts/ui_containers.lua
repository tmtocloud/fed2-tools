-- Adjustable Border Containers System for Mudlet
-- Creates 4 containers attached to borders that resize with each other without overlapping

-- Track previous positions for detecting edge movements
local previous_state = {}

-- Helper function to convert percentage to pixels
local function ui_pct_to_pixels_width(pct)
    local screen_width = getMainWindowSize()
    return math.floor(screen_width * (pct / 100))
end

local function ui_pct_to_pixels_height(pct)
    local _, screen_height = getMainWindowSize()
    return math.floor(screen_height * (pct / 100))
end

-- Store current state for comparison
local function ui_capture_state()
    if not UI.top_left_frame or not UI.top_right_frame then return end
    
    previous_state = {
        top_left_x           = UI.top_left_frame:get_x(),
        top_left_width       = UI.top_left_frame:get_width(),
        top_left_right_edge  = UI.top_left_frame:get_x() +  UI.top_left_frame:get_width(),
        top_right_x          = UI.top_right_frame:get_x(),
        top_right_width      = UI.top_right_frame:get_width(),
        top_right_right_edge = UI.top_right_frame:get_x() + UI.top_right_frame:get_width()
    }
end

-- Create all containers
function ui_create_containers()
    local screen_width, screen_height = getMainWindowSize()
    
    local left_width             = ui_pct_to_pixels_width(f2t_settings_get("ui", "left_width"))
    local right_width            = ui_pct_to_pixels_width(f2t_settings_get("ui", "right_width"))
    local available_center_width = screen_width - left_width - right_width
    
    -- Top container widths are percentage of the available center space
    local top_left_width  = math.floor(available_center_width * (f2t_settings_get("ui", "top_left_width")  / 100))
    local top_right_width = math.floor(available_center_width * (f2t_settings_get("ui", "top_right_width") / 100))
    
    local top_left_height  = ui_pct_to_pixels_height(f2t_settings_get("ui", "top_left_height"))
    local top_right_height = ui_pct_to_pixels_height(f2t_settings_get("ui", "top_right_height"))
    
    -- Create Left Container (attached to left border)
    UI.left_frame = Adjustable.Container:new({
        name          = "UI.left_frame",
        x             = 0,
        y             = 0,
        width         = left_width,
        height        = screen_height,
        locked        = true,
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "left"
    })
    f2t_ui_register_container("UI.left_frame", UI.left_frame)

    -- Create Right Container (attached to right border)
    UI.right_frame = Adjustable.Container:new({
        name          = "UI.right_frame",
        x             = screen_width - right_width,
        y             = 0,
        width         = right_width,
        height        = screen_height,
        locked        = true,
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "right"
    })
    f2t_ui_register_container("UI.right_frame", UI.right_frame)

    -- Create Top Left Container (attached to top and left borders)
    UI.top_left_frame = Adjustable.Container:new({
        name          = "UI.top_left_frame",
        x             = left_width,
        y             = 0,
        width         = top_left_width,
        height        = top_left_height,
        locked        = true,
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "top"
    })
    f2t_ui_register_container("UI.top_left_frame", UI.top_left_frame)

    -- Create Top Right Container (attached to top and right borders)
    UI.top_right_frame = Adjustable.Container:new({
        name          = "UI.top_right_frame",
        x             = screen_width - right_width - top_right_width,
        y             = 0,
        width         = top_right_width,
        height        = top_right_height,
        locked        = true,
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "top"
    })
    f2t_ui_register_container("UI.top_right_frame", UI.top_right_frame)
    
    -- Capture initial state
    tempTimer(0.1, ui_capture_state)
    tempTimer(0.1, ui_on_window_resize)

    -- Enable Adjustable Containers (Tabs), users can move tabs from default starting positions as they wish
    Adjustable.Container:doAll(function(self) self:addConnectMenu() end)
end

-- Register event handlers to sync container sizes when one is resized
function ui_on_container_reposition(event, container_name)
    if not container_name then return end
    
    local screen_width, screen_height = getMainWindowSize()
    local min_pixels = ui_pct_to_pixels_width(5)
    
    local left_width      = UI.left_frame:get_width()
    local right_width     = UI.right_frame:get_width()
    local available_width = screen_width - left_width - right_width
    
    -- When left container resizes, adjust top containers
    if container_name == "UI.left_frame" then
        -- Maintain proportions of top containers
        local top_left_width  = UI.top_left_frame:get_width()
        local top_right_width = UI.top_right_frame:get_width()
        local total_top_width = top_left_width + top_right_width
        local left_ratio      = top_left_width / total_top_width
        
        UI.top_left_frame:move(left_width, 0)
        UI.top_left_frame:resize(math.max(min_pixels, available_width * left_ratio), nil)
        UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
        UI.top_right_frame:resize(math.max(min_pixels, available_width * (1 - left_ratio)), nil)
    end
    
    -- When right container resizes, adjust top containers
    if container_name == "UI.right_frame" then
        -- Maintain proportions of top containers
        local top_left_width  = UI.top_left_frame:get_width()
        local top_right_width = UI.top_right_frame:get_width()
        local total_top_width = top_left_width + top_right_width
        local left_ratio      = top_left_width / total_top_width
        
        UI.top_left_frame:resize(math.max(min_pixels, available_width * left_ratio), nil)
        UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
        UI.top_right_frame:resize(math.max(min_pixels, available_width * (1 - left_ratio)), nil)
        UI.right_frame:move(screen_width - right_width, 0)
    end
    
    -- When top left resizes
    if container_name == "UI.top_left_frame" then
        local current_x          = UI.top_left_frame:get_x()
        local current_width      = UI.top_left_frame:get_width()
        local current_right_edge = current_x + current_width
        
        -- Detect if the LEFT edge was moved (x position changed)
        local left_edge_moved = previous_state.top_left_x and math.abs(current_x - previous_state.top_left_x) > 2
        -- Detect if the RIGHT edge was moved
        local right_edge_moved = previous_state.top_left_right_edge and math.abs(current_right_edge - previous_state.top_left_right_edge) > 2
        
        if left_edge_moved and not right_edge_moved then
            -- Left edge was dragged - snap topLeft back to left container and adjust width
            local new_width = current_right_edge - left_width
            UI.top_left_frame:move(left_width, 0)
            UI.top_left_frame:resize(math.max(min_pixels, new_width), nil)
            
            -- Top right stays where it is
            UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
            UI.top_right_frame:resize(math.max(min_pixels, available_width - UI.top_left_frame:get_width()), nil)
        else
            -- Right edge was dragged - normal behavior
            local top_left_width = UI.top_left_frame:get_width()
            
            -- Ensure topLeft stays anchored to left container
            UI.top_left_frame:move(left_width, 0)
            
            UI.top_right_frame:move(left_width + top_left_width, 0)
            UI.top_right_frame:resize(math.max(min_pixels, available_width - top_left_width), nil)
        end
    end
    
    -- When top right resizes
    if container_name == "UI.top_right_frame" then
        local current_x          = UI.top_right_frame:get_x()
        local current_width      = UI.top_right_frame:get_width()
        local current_right_edge = current_x + current_width
        
        -- Detect if the RIGHT edge was moved
        local right_edge_moved = previous_state.top_right_right_edge and math.abs(current_right_edge - previous_state.top_right_right_edge) > 2
        -- Detect if the LEFT edge was moved
        local left_edge_moved = previous_state.top_right_x and math.abs(current_x - previous_state.top_right_x) > 2
        
        if right_edge_moved and not left_edge_moved then
            -- Right edge was dragged - snap topRight back to right container
            local right_boundary = screen_width - right_width
            local new_width      = right_boundary - current_x
            UI.top_right_frame:resize(math.max(min_pixels, new_width), nil)
            UI.top_right_frame:move(right_boundary - UI.top_right_frame:get_width(), 0)
            
            -- Adjust top left
            UI.top_left_frame:move(left_width, 0)
            UI.top_left_frame:resize(math.max(min_pixels, available_width - UI.top_right_frame:get_width()), nil)
            UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
        else
            -- Left edge was dragged - normal behavior
            local top_right_width = UI.top_right_frame:get_width()
            
            UI.top_left_frame:move(left_width, 0)
            UI.top_left_frame:resize(math.max(min_pixels, available_width - top_right_width), nil)
            UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
        end
    end
    
    -- Update previous state for next comparison
    ui_capture_state()
end

-- Handle window resize
function ui_on_window_resize()
    local screen_width, screen_height = getMainWindowSize()
    local min_pixels = ui_pct_to_pixels_width(5)
    
    local left_width      = UI.left_frame:get_width()
    local right_width     = UI.right_frame:get_width()
    local available_width = screen_width - left_width - right_width
    
    -- Update side containers on window resize
    UI.left_frame:resize(left_width, screen_height)
    UI.right_frame:move(screen_width - right_width, 0)
    UI.right_frame:resize(right_width, screen_height)
    
    -- Maintain ratio for top containers
    local top_left_width  = UI.top_left_frame:get_width()
    local top_right_width = UI.top_right_frame:get_width()
    local total_top_width = top_left_width + top_right_width
    local ratio           = (total_top_width > 0) and (top_left_width / total_top_width) or 0.5
    
    UI.top_left_frame:move(left_width, 0)
    UI.top_left_frame:resize(math.max(min_pixels, available_width * ratio), nil)
    UI.top_right_frame:move(left_width + UI.top_left_frame:get_width(), 0)
    UI.top_right_frame:resize(math.max(min_pixels, available_width * (1 - ratio)), nil)
    
    -- Update state after resize
    ui_capture_state()
end
