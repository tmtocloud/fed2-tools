-- Adjustable Border Containers System for Mudlet
-- Using percentages to avoid window resize issues

-- Track previous positions for detecting edge movements
local previous_state = {}

-- Base percentage configuration
UI.container_config = {
    left_width_pct = 20,
    right_width_pct = 20,
    top_left_center_ratio = 0.93,  -- 93% of center space
    top_left_height_pct = 5,
    top_right_height_pct = 7,
    cargo_width_pct = 15
}

-- Helper to convert pixels back to percentage
local function pixels_to_pct_width(pixels)
    local screen_width = getMainWindowSize()
    return (pixels / screen_width) * 100
end

local function pixels_to_pct_height(pixels)
    local _, screen_height = getMainWindowSize()
    return (pixels / screen_height) * 100
end

-- Store current state for comparison
local function ui_capture_state()
    if not UI.top_left_frame or not UI.top_right_frame then return end
    
    local screen_width = getMainWindowSize()
    
    previous_state = {
        top_left_x_pct = pixels_to_pct_width(UI.top_left_frame:get_x()),
        top_left_width_pct = pixels_to_pct_width(UI.top_left_frame:get_width()),
        top_right_x_pct = pixels_to_pct_width(UI.top_right_frame:get_x()),
        top_right_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
    }
end

-- Create all containers
function ui_create_containers()
    local screen_width, screen_height = getMainWindowSize()
    
    local left_width_pct = UI.container_config.left_width_pct
    local right_width_pct = UI.container_config.right_width_pct
    
    -- Calculate center space percentages
    local available_center_pct = 100 - left_width_pct - right_width_pct
    local top_left_width_pct = available_center_pct * UI.container_config.top_left_center_ratio
    local top_right_width_pct = available_center_pct - top_left_width_pct
    
    local top_left_height_pct = UI.container_config.top_left_height_pct
    local top_right_height_pct = UI.container_config.top_right_height_pct
    local top_height_diff_pct = top_right_height_pct - top_left_height_pct
    
    local cargo_width_pct = UI.container_config.cargo_width_pct
   
    -- Create Left Container (attached to left border)
    UI.left_frame = Adjustable.Container:new({
        name          = "UI.left_frame",
        x             = 0,
        y             = 0,
        width         = left_width_pct .. "%",
        height        = "100%",
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "left",
        autoSave      = false,
        autoLoad      = false
    })
    UI.left_frame:connectToBorder("left")
    UI.left_frame:lockContainer("border")
    f2t_ui_register_container("UI.left_frame", UI.left_frame)

    -- Create Right Container (attached to right border)
    UI.right_frame = Adjustable.Container:new({
        name          = "UI.right_frame",
        x             = (100 - right_width_pct) .. "%",
        y             = 0,
        width         = right_width_pct .. "%",
        height        = "100%",
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "right",
        autoSave      = false,
        autoLoad      = false
    })
    UI.right_frame:connectToBorder("right")
    UI.right_frame:lockContainer("border")
    f2t_ui_register_container("UI.right_frame", UI.right_frame)

    -- Create Top Left Container (attached to top and left borders)
    UI.top_left_frame = Adjustable.Container:new({
        name          = "UI.top_left_frame",
        x             = left_width_pct .. "%",
        y             = 0,
        width         = top_left_width_pct .. "%",
        height        = top_left_height_pct .. "%",
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "top",
        autoSave      = false,
        autoLoad      = false
    })
    UI.top_left_frame:lockContainer("border")
    f2t_ui_register_container("UI.top_left_frame", UI.top_left_frame)

    -- Create Top Right Container (attached to top and right borders)
    UI.top_right_frame = Adjustable.Container:new({
        name          = "UI.top_right_frame",
        x             = (left_width_pct + top_left_width_pct) .. "%",
        y             = 0,
        width         = top_right_width_pct .. "%",
        height        = top_right_height_pct .. "%",
        lockStyle     = "border",
        adjLabelstyle = UI.style.frame_css,
        attached      = "top",
        noLimit       = false,
        autoSave      = false,
        autoLoad      = false
    })
    UI.top_right_frame:lockContainer("border")
    f2t_ui_register_container("UI.top_right_frame", UI.top_right_frame)

    -- Calculate cargo position (to the left of right_frame)
    local cargo_x_pct = 100 - right_width_pct - cargo_width_pct
    
    -- Gap filler - seamless top section with label
    UI.cargo_gap_filler = Geyser.Label:new({
        name   = "UI.cargo_gap_filler",
        x      = cargo_x_pct .. "%",
        y      = top_left_height_pct .. "%",
        width  = (cargo_width_pct - top_right_width_pct) .. "%",
        height = top_height_diff_pct .. "%",
        message = "<center><dim_grey><b>Hold Contents:</b></dim_grey></center>"
    })
    UI.cargo_gap_filler:setStyleSheet([[
        background-color: rgba(255,255,255,0.035);
        border-left: 2px solid rgba(255,255,255,0.46);
        border-right: none;
        border-top: none;
        border-bottom: none;
        padding: 1px;
        margin: 0px;
        box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.10),
        0 10px 30px rgba(0,0,0,0.6),
        0 0 18px rgba(255,255,255,0.02);
        transition: transform 120ms ease, box-shadow 160ms ease, border-color 120ms ease, background 120ms ease;
        color: rgba(255,255,255,0.95);
        -webkit-backdrop-filter: blur(4px) saturate(110%);
        backdrop-filter: blur(4px) saturate(110%);
    ]])
    UI.cargo_gap_filler:hide()

    -- Create the cargo dropdown container
    UI.cargo_dropdown = Adjustable.Container:new({
        name          = "UI.cargo_dropdown",
        x             = cargo_x_pct .. "%",
        y             = top_right_height_pct .. "%",
        width         = cargo_width_pct .. "%",
        height        = "20%",  -- Initial height
        lockStyle     = "border",
        adjLabelstyle = [[
            background-color: rgba(255,255,255,0.035);
            border-left: 2px solid rgba(255,255,255,0.46);
            border-right: 2px solid rgba(255,255,255,0.46);
            border-bottom: 2px solid rgba(255,255,255,0.46);
            border-top: none;
            padding: 1px;
            margin: 0px;
            box-shadow:
            inset 0 1px 0 rgba(255,255,255,0.10),
            0 10px 30px rgba(0,0,0,0.6),
            0 0 18px rgba(255,255,255,0.02);
            transition: transform 120ms ease, box-shadow 160ms ease, border-color 120ms ease, background 120ms ease;
            color: rgba(255,255,255,0.95);
            -webkit-backdrop-filter: blur(4px) saturate(110%);
            backdrop-filter: blur(4px) saturate(110%);
        ]],
        autoSave      = false,
        autoLoad      = false
    })
    UI.cargo_dropdown:lockContainer("border")
    UI.cargo_dropdown:hide()

    -- Put cargo console in cargo dropdown
    UI.cargo_window = Geyser.MiniConsole:new({
        name      = "UI.cargo_window",
        x         = "0%",
        y         = "0%",
        width     = "100%",
        height    = "100%",
        autoWrap  = true,
        scrollBar = false,
        fontSize  = text_size,
        color     = "black",
    }, UI.cargo_dropdown)

    -- Capture initial state
    tempTimer(0.1, ui_capture_state)

    -- Enable Adjustable Containers (Tabs)
    Adjustable.Container:doAll(function(self) self:addConnectMenu() end)
end

-- Register event handlers to sync container sizes when one is resized
function ui_on_container_reposition(event, container_name)
    if not container_name then return end
    
    local screen_width = getMainWindowSize()
    
    -- Get current percentage values
    local left_width_pct = pixels_to_pct_width(UI.left_frame:get_width())
    local right_width_pct = pixels_to_pct_width(UI.right_frame:get_width())
    local available_pct = 100 - left_width_pct - right_width_pct
    
    -- Helper to update cargo position
    local function update_cargo_position()
        if UI.cargo_gap_filler and UI.cargo_dropdown then
            local cargo_width_pct = pixels_to_pct_width(UI.cargo_dropdown:get_width())
            local cargo_x_pct = 100 - right_width_pct - cargo_width_pct
            
            local top_left_height_pct = pixels_to_pct_height(UI.top_left_frame:get_height())
            local top_right_height_pct = pixels_to_pct_height(UI.top_right_frame:get_height())
            local top_right_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
            local top_height_diff_pct = top_right_height_pct - top_left_height_pct
            
            UI.cargo_gap_filler:move(cargo_x_pct .. "%", top_left_height_pct .. "%")
            UI.cargo_gap_filler:resize((cargo_width_pct - top_right_width_pct) .. "%", top_height_diff_pct .. "%")
            
            UI.cargo_dropdown:move(cargo_x_pct .. "%", top_right_height_pct .. "%")
        end
    end
    
    -- When left container resizes
    if container_name == "UI.left_frame" then
        local top_left_width_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        local top_right_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
        local total_top_pct = top_left_width_pct + top_right_width_pct
        local ratio = top_left_width_pct / total_top_pct
        
        UI.top_left_frame:move(left_width_pct .. "%", 0)
        UI.top_left_frame:resize((available_pct * ratio) .. "%", nil)
        
        local new_top_left_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        UI.top_right_frame:move((left_width_pct + new_top_left_pct) .. "%", 0)
        UI.top_right_frame:resize((available_pct * (1 - ratio)) .. "%", nil)
        
        update_cargo_position()
    end
    
    -- When right container resizes
    if container_name == "UI.right_frame" then
        local top_left_width_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        local top_right_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
        local total_top_pct = top_left_width_pct + top_right_width_pct
        local ratio = top_left_width_pct / total_top_pct
        
        UI.top_left_frame:resize((available_pct * ratio) .. "%", nil)
        
        local new_top_left_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        UI.top_right_frame:move((left_width_pct + new_top_left_pct) .. "%", 0)
        UI.top_right_frame:resize((available_pct * (1 - ratio)) .. "%", nil)
        UI.right_frame:move((100 - right_width_pct) .. "%", 0)
        
        update_cargo_position()
    end
    
    -- When top left resizes
    if container_name == "UI.top_left_frame" then
        local current_x_pct = pixels_to_pct_width(UI.top_left_frame:get_x())
        local current_width_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        
        -- Detect edge movements
        local left_edge_moved = previous_state.top_left_x_pct and math.abs(current_x_pct - previous_state.top_left_x_pct) > 0.5
        local right_edge_moved = previous_state.top_left_width_pct and math.abs(current_width_pct - previous_state.top_left_width_pct) > 0.5
        
        if left_edge_moved and not right_edge_moved then
            -- Snap back to left frame
            UI.top_left_frame:move(left_width_pct .. "%", 0)
            local new_width_pct = current_x_pct + current_width_pct - left_width_pct
            UI.top_left_frame:resize(new_width_pct .. "%", nil)
        end
        
        local top_left_final_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        UI.top_right_frame:move((left_width_pct + top_left_final_pct) .. "%", 0)
        UI.top_right_frame:resize((available_pct - top_left_final_pct) .. "%", nil)
        
        update_cargo_position()
    end
    
    -- When top right resizes
    if container_name == "UI.top_right_frame" then
        local current_x_pct = pixels_to_pct_width(UI.top_right_frame:get_x())
        local current_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
        
        -- Detect edge movements
        local right_edge_moved = previous_state.top_right_width_pct and math.abs(current_width_pct - previous_state.top_right_width_pct) > 0.5
        local left_edge_moved = previous_state.top_right_x_pct and math.abs(current_x_pct - previous_state.top_right_x_pct) > 0.5
        
        if right_edge_moved and not left_edge_moved then
            -- Snap to right frame
            local right_boundary_pct = 100 - right_width_pct
            UI.top_right_frame:move((right_boundary_pct - current_width_pct) .. "%", 0)
        end
        
        local top_right_final_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
        local top_right_x_pct = pixels_to_pct_width(UI.top_right_frame:get_x())
        
        UI.top_left_frame:move(left_width_pct .. "%", 0)
        UI.top_left_frame:resize((available_pct - top_right_final_pct) .. "%", nil)
        
        local top_left_final_pct = pixels_to_pct_width(UI.top_left_frame:get_width())
        UI.top_right_frame:move((left_width_pct + top_left_final_pct) .. "%", 0)
        
        update_cargo_position()
    end
    
    -- Update previous state
    ui_capture_state()
end

-- Handle window resize
function ui_on_window_resize()
    -- Update cargo position after resize
    if UI.cargo_gap_filler and UI.cargo_dropdown then
        local left_width_pct = pixels_to_pct_width(UI.left_frame:get_width())
        local right_width_pct = pixels_to_pct_width(UI.right_frame:get_width())
        local cargo_width_pct = pixels_to_pct_width(UI.cargo_dropdown:get_width())
        local cargo_x_pct = 100 - right_width_pct - cargo_width_pct
        
        local top_left_height_pct = pixels_to_pct_height(UI.top_left_frame:get_height())
        local top_right_height_pct = pixels_to_pct_height(UI.top_right_frame:get_height())
        local top_right_width_pct = pixels_to_pct_width(UI.top_right_frame:get_width())
        local top_height_diff_pct = top_right_height_pct - top_left_height_pct
        
        UI.cargo_gap_filler:move(cargo_x_pct .. "%", top_left_height_pct .. "%")
        UI.cargo_gap_filler:resize((cargo_width_pct - top_right_width_pct) .. "%", top_height_diff_pct .. "%")
        
        UI.cargo_dropdown:move(cargo_x_pct .. "%", top_right_height_pct .. "%")
    end
    
    -- Update state after resize
    ui_capture_state()
end