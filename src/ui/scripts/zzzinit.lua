-- ========================================
-- Initialization
-- ========================================
function ui_build()
  ui_build_frames()
  ui_build_header()
  ui_build_tabs()
  ui_build_tab_content()
  ui_build_movement()
  ui_room_info_event_handler()
  ui_hauling()
  ui_trading()
  ui_output_commodities()
  ui_update_tabs_for_rank()
end

f2t_settings_register("ui", "enabled", {
    description = "Enable/disable ui",
    default = true,
    validator = function(value)
        if value ~= true and value ~= false and value ~= "true" and value ~= "false" then
            return false, "Must be true or false"
        end
        return true
    end
})

F2T_UI_ENABLED = f2t_settings_get("ui", "enabled")

if F2T_UI_ENABLED then
    cecho("\n<green>[ui]<reset> ui <yellow>ENABLED<reset>\n")
    ui_build()
    f2t_debug_log("[ui] ui initialized (enabled)")
else
    cecho("\n<dim_grey>[ui]<reset> ui <red>DISABLED<reset>\n")
    f2t_debug_log("[ui] ui initialized (disabled)")
end