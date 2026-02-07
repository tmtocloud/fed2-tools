UI.style = UI.style or {}

UI.style.frame_css = [[
    /* Slightly translucent light panel so frames read on black backgrounds */
    background: rgba(255,255,255,0.035);            /* a touch of light so panels aren't 'black on black' */
    border-radius: 1px;
    padding: 1px;
    margin: 1px;

    /* Thin, visible light border that contrasts on black */
    border: 2px solid rgba(255,255,255,0.46);

    /* Soft inner sheen and faint outer halo for separation from the black background */
    box-shadow:
        inset 0 1px 0 rgba(255,255,255,0.10),    /* inner top highlight */
        0 10px 30px rgba(0,0,0,0.6),            /* soft silhouette */
        0 0 18px rgba(255,255,255,0.02);        /* subtle light rim to help edges read */

    /* Faster, crisp interactions */
    transition: transform 120ms ease, box-shadow 160ms ease, border-color 120ms ease, background 120ms ease;
    color: rgba(255,255,255,0.95);
    -webkit-backdrop-filter: blur(4px) saturate(110%);
    backdrop-filter: blur(4px) saturate(110%);
]]

-- style the labels: background color and a little border between each label
UI.style.label_css = [[
    background-color: rgba(77,77,77,100); /*because DimGrey is not dark enough*/
    border-right-style: solid;
    border-left-style: solid;
    border-width: 1px;
    border-radius: 1;
    border-color: white;
]]

UI.style.header_label_css = [[
    background-color: qlineargradient(x1:0, y1:0, x2:0, y2:1,
        stop:0 #2a2a3a,
        stop:0.4 #1e1e2a,
        stop:1 #16161e);
    color: #c8c8d0;
    border: none;
    border-right: 1px solid #3a3a4a;
    padding: 4px 8px;
    font-family: "Consolas", "Monaco", monospace;
]]

-- Styling for tabs
--future?: some method to set text size on tabs
UI.style.active_tab_text    = "white"     --active tab text color
UI.style.active_tab_color   = "black"     --active tab window color
UI.style.inactive_tab_text  = "lightgrey" --inactive tab text color
UI.style.inactive_tab_color = "dimgrey"   --inactive tab window color

-- active tab 
UI.style.active_tab_css = UI.style.active_tab_css or [[
    background-color: ]] .. UI.style.active_tab_color .. [[;
    color: ]] .. UI.style.active_tab_text .. [[;
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
    border-width: 1px;
    border-style: solid;
    border-color: ]] .. UI.style.active_tab_text .. [[;
    margin-right: 1px;
    margin-left: 1px;
    qproperty-alignment: 'AlignVCenter';
]]

-- inactive tab - will highlight with the active tab colors on mouseover
UI.style.inactive_tab_css = UI.style.inactive_tab_css or [[
    QLabel::hover{
        background-color: ]] .. UI.style.active_tab_color .. [[;
        color: ]] .. UI.style.active_tab_text .. [[;
        border-top-left-radius: 10px;
        border-top-right-radius: 10px;
        border-width: 1px;
        border-style: solid;
        border-color: ]] .. UI.style.active_tab_text .. [[;
        margin-right: 1px;
        margin-left: 1px;
        qproperty-alignment: 'AlignVCenter';
    }
    QLabel::!hover{
        background-color: ]] .. UI.style.inactive_tab_color .. [[;
        color: ]] .. UI.style.inactive_tab_text .. [[;
        border-top-left-radius: 10px;
        border-top-right-radius: 10px;
        margin-right: 1px;
        margin-left: 1px;
        qproperty-alignment: 'AlignVCenter';
    }
]]

-- The outer border of the window, which should never be seen since it's being covered by a container
UI.style.footer_css = [[
    background-color: ]] .. UI.style.active_tab_color .. [[;
    border-bottom-left-radius: 1px;
    border-bottom-right-radius: 1px;
    border-width: 1px;
    border-style: solid;
    border-color: ]] .. UI.style.active_tab_text .. [[;
]]

-- The core of the window, which should never be seen because we're using it as a container
UI.style.center_css = [[
    background-color: ]] .. UI.style.inactive_tab_color .. [[;
    border-radius: 5px;
    margin: 5px;
]]

-- Modern button styling
UI.style.button_css = [[
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

UI.style.disabled_button_css = [[
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

UI.style.toggle_button_css = [[
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