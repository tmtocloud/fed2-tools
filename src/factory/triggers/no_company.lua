-- Detect when player has no company/business
-- @patterns:
--   - pattern: ^You don't have a company or business, let alone factories!$
--     type: regex

if f2t_factory.capturing then
    deleteLine()
    f2t_debug_log("[factory-status] Player has no company or business")

    -- Stop capturing
    f2t_factory.capturing = false

    -- Show error message
    cecho("\n<yellow>[Factory Status]<reset> You don't have a company or business.\n")
    cecho("<dim_grey>You need to purchase a company first before building factories.<reset>\n")

    -- Reset state
    f2t_factory_reset()
end
