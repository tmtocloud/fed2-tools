-- Death monitoring settings registration

f2t_settings_register("shared", "death_monitor_enabled", {
    description = "Enable automatic death recovery (insure, room locking)",
    default = true,
    validator = function(value)
        if value ~= true and value ~= false and value ~= "true" and value ~= "false" then
            return false, "Must be true or false"
        end
        return true
    end
})

f2t_debug_log("[death] Settings registered")
