ui_style = ui_style or {}

ui_style.frame_css = [[
  background-color: black;
  border-style: solid;
  border-width: 1px;
  border-radius: 5;
  border-color: white;
  margin: 1px;
]]
  
-- style the labels: background color and a little border between each label
ui_style.label_css = [[
  background-color: rgba(77,77,77,100); /*because DimGrey is not dark enough*/
  border-right-style: solid;
  border-left-style: solid;
  border-width: 1px;
  border-radius: 1;
  border-color: white;
]]

-- Styling for tabs
--future?: some method to set text size on tabs
ui_style.active_tab_text    = "white"     --active tab text color
ui_style.active_tab_color   = "black"     --active tab window color
ui_style.inactive_tab_text  = "lightgrey" --inactive tab text color
ui_style.inactive_tab_color = "dimgrey"   --inactive tab window color

-- active tab 
ui_style.active_tab_css = ui_style.active_tab_css or [[
  background-color: ]] .. ui_style.active_tab_color .. [[;
  color: ]] .. ui_style.active_tab_text .. [[;
  border-top-left-radius: 10px;
  border-top-right-radius: 10px;
  border-width: 1px;
  border-style: solid;
  border-color: ]] .. ui_style.active_tab_text .. [[;
  margin-right: 1px;
  margin-left: 1px;
  qproperty-alignment: 'AlignVCenter';
]]
  
-- inactive tab - will highlight with the active tab colors on mouseover
ui_style.inactive_tab_css = ui_style.inactive_tab_css or [[
  QLabel::hover{
    background-color: ]] .. ui_style.active_tab_color .. [[;
    color: ]] .. ui_style.active_tab_text .. [[;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    border-width: 1px;
    border-style: solid;
    border-color: ]] .. ui_style.active_tab_text .. [[;
    margin-right: 1px;
    margin-left: 1px;
    qproperty-alignment: 'AlignVCenter';
  }
  QLabel::!hover{
    background-color: ]] .. ui_style.inactive_tab_color .. [[;
    color: ]] .. ui_style.inactive_tab_text .. [[;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    margin-right: 1px;
    margin-left: 1px;
    qproperty-alignment: 'AlignVCenter';
  }
]]

-- The outer border of the window, which should never be seen since it's being covered by a container
ui_style.footer_css = [[
  background-color: ]] .. ui_style.active_tab_color .. [[;
  border-bottom-left-radius: 1px;
  border-bottom-right-radius: 1px;
  border-width: 1px;
  border-style: solid;
  border-color: ]] .. ui_style.active_tab_text .. [[;
]]

-- The core of the window, which should never be seen because we're using it as a container
ui_style.center_css = [[
  background-color: ]] .. ui_style.inactive_tab_color .. [[;
  border-radius: 5px;
  margin: 5px;
]]

-- Modern button styling
ui_style.button_css = [[
  QLabel{
    background-color: rgba(40, 40, 45, 200);
    border-style: solid;
    border-width: 1px;
    border-radius: 3px;
    border-color: rgba(100, 100, 110, 180);
    color: rgba(200, 200, 210, 255);
    font-size: 11px;
    font-weight: bold;
  }
  QLabel::hover{
    background-color: rgba(60, 60, 70, 220);
    border-color: rgba(120, 180, 255, 200);
    color: white;
  }
]]

ui_style.disabled_button_css = [[
  QLabel{
    background-color: rgba(25, 25, 28, 150);
    border-style: solid;
    border-width: 1px;
    border-radius: 3px;
    border-color: rgba(60, 60, 65, 120);
    color: rgba(80, 80, 85, 180);
    font-size: 11px;
    font-weight: bold;
  }
]]

ui_style.toggle_button_css = [[
  QLabel{
    background-color: rgba(50, 50, 55, 220);
    border-style: solid;
    border-width: 1px;
    border-radius: 3px;
    border-color: rgba(120, 120, 130, 200);
    color: rgba(220, 220, 230, 255);
    font-size: 10px;
    font-weight: bold;
  }
  QLabel::hover{
    background-color: rgba(70, 130, 180, 240);
    border-color: rgba(150, 200, 255, 230);
    color: white;
  }
]]