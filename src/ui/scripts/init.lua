-- Initialize UI component
UI = UI or {}

f2t_settings.ui = f2t_settings.ui or {}

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

-- Load saved state (default to enabled)
local saved_enabled = f2t_settings_get("ui", "enabled")
if saved_enabled == nil then
    saved_enabled = true
end

-- UI Manager: Central control for showing/hiding UI and enabling/disabling triggers
-- Following the persistent state pattern from shared/CLAUDE.md
F2T_UI_STATE = F2T_UI_STATE or {
    enabled = true,

    -- Track created UI elements (populate during creation)
    labels       = {}, -- {name = label_object, ...}
    containers   = {}, -- {name = container_object, ...}
    miniconsoles = {}, -- {name = console_object, ...}

    -- Track trigger/alias names to toggle (strings, not IDs)
    -- These are PERMANENT triggers/aliases from the ui component
    triggers = {}, -- {"trigger_name_1", "trigger_name_2", ...}
    aliases  = {}, -- {"alias_name_1", "alias_name_2", ...}
}

-- Register a UI element for management
function f2t_ui_register_label(name, label_object)
    F2T_UI_STATE.labels[name] = label_object
end

function f2t_ui_register_container(name, container_object)
    F2T_UI_STATE.containers[name] = container_object
end

function f2t_ui_register_miniconsole(name, console_object)
    F2T_UI_STATE.miniconsoles[name] = console_object
end

-- Register triggers/aliases that should be toggled with UI
function f2t_ui_register_trigger(trigger_name)
    if not f2t_has_value(F2T_UI_STATE.triggers, trigger_name) then
        table.insert(F2T_UI_STATE.triggers, trigger_name)
    end
end

function f2t_ui_register_alias(alias_name)
    if not f2t_has_value(F2T_UI_STATE.aliases, alias_name) then
        table.insert(F2T_UI_STATE.aliases, alias_name)
    end
end

-- Enable UI (show elements, enable triggers/aliases)
function f2t_ui_enable()
    if F2T_UI_STATE.enabled then
        f2t_debug_log("[ui] UI already enabled")
        return
    end

    F2T_UI_STATE.enabled = true

    -- If the UI was never built, then build it 
    if not ui_Built then ui_built = ui_build() end

    -- Show all UI elements
    for name, label in pairs(F2T_UI_STATE.labels) do
        if label.show then
            label:show()
        elseif showWindow then
            showWindow(name)
        end
        f2t_debug_log("[ui] Showing label: %s", name)
    end

    for name, container in pairs(F2T_UI_STATE.containers) do
        if container.show then
            container:show()
        elseif showWindow then
            showWindow(name)
        end
        f2t_debug_log("[ui] Showing container: %s", name)
    end

    for name, console in pairs(F2T_UI_STATE.miniconsoles) do
        if console.show then
            console:show()
        elseif showWindow then
            showWindow(name)
        end
        f2t_debug_log("[ui] Showing miniconsole: %s", name)
    end

    -- Enable triggers
    for _, trigger_name in ipairs(F2T_UI_STATE.triggers) do
        enableTrigger(trigger_name)
        f2t_debug_log("[ui] Enabled trigger: %s", trigger_name)
    end

    -- Enable aliases
    for _, alias_name in ipairs(F2T_UI_STATE.aliases) do
        enableAlias(alias_name)
        f2t_debug_log("[ui] Enabled alias: %s", alias_name)
    end

    -- Save state
    f2t_settings_set("ui", "enabled", true)

    cecho("\n<green>[ui]<reset> UI enabled\n")
end

-- Disable UI (hide elements, disable triggers/aliases)
function f2t_ui_disable()
    if not F2T_UI_STATE.enabled then
        f2t_debug_log("[ui] UI already disabled")
        return
    end

    F2T_UI_STATE.enabled = false

    -- Hide all UI elements (don't destroy them!)
    for name, label in pairs(F2T_UI_STATE.labels) do
        if label.hide then
            label:hide()
        elseif hideWindow then
            hideWindow(name)
        end
        f2t_debug_log("[ui] Hiding label: %s", name)
    end

    for name, container in pairs(F2T_UI_STATE.containers) do
        if container.hide then
            container:hide()
        elseif hideWindow then
            hideWindow(name)
        end
        f2t_debug_log("[ui] Hiding container: %s", name)
    end

    for name, console in pairs(F2T_UI_STATE.miniconsoles) do
        if console.hide then
            console:hide()
        elseif hideWindow then
            hideWindow(name)
        end
        f2t_debug_log("[ui] Hiding miniconsole: %s", name)
    end

    -- Disable triggers
    for _, trigger_name in ipairs(F2T_UI_STATE.triggers) do
        disableTrigger(trigger_name)
        f2t_debug_log("[ui] Disabled trigger: %s", trigger_name)
    end

    -- Disable aliases
    for _, alias_name in ipairs(F2T_UI_STATE.aliases) do
        disableAlias(alias_name)
        f2t_debug_log("[ui] Disabled alias: %s", alias_name)
    end

    -- Save state
    f2t_settings_set("ui", "enabled", false)

    cecho("\n<yellow>[ui]<reset> UI disabled\n")
end

-- Toggle UI state
function f2t_ui_toggle()
    if F2T_UI_STATE.enabled then
        f2t_ui_disable()
    else
        f2t_ui_enable()
    end
end

-- Check if UI is enabled
function f2t_ui_is_enabled()
    return F2T_UI_STATE.enabled
end

-- Status display
function f2t_ui_status()
    local status = F2T_UI_STATE.enabled and "<green>ENABLED<reset>" or "<red>DISABLED<reset>"
    cecho(string.format("\n<cyan>[ui]<reset> Status: %s\n", status))
    cecho(string.format("  Labels: %d | Containers: %d | Miniconsoles: %d\n", 
        f2t_table_count_keys(F2T_UI_STATE.labels),
        f2t_table_count_keys(F2T_UI_STATE.containers),
        f2t_table_count_keys(F2T_UI_STATE.miniconsoles)))
    cecho(string.format("  Triggers: %d | Aliases: %d\n", 
        #F2T_UI_STATE.triggers,
        #F2T_UI_STATE.aliases))
end

-- Apply saved state on load (after UI elements are created)
tempTimer(0.5, function()
    if not saved_enabled then
        f2t_ui_disable()
    end
end)

f2t_debug_log("[ui] Component initialized, enabled=%s", tostring(saved_enabled))
