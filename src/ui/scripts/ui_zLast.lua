function ui_build()
    ui_create_containers()
    ui_build_tabs()
    ui_build_tab_content()
    ui_build_movement()
    ui_room_info_event_handler()
    ui_hauling()
    ui_trading()
    ui_output_commodities()
    ui_update_tabs_for_rank()
end

if F2T_UI_STATE.enabled and not ui_Built then ui_built = ui_build() end
