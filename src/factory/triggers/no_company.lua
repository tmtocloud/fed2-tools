-- Detect when player has no company/business
-- @patterns:
--   - pattern: ^You don't have a company or business, let alone factories!$
--     type: regex

if f2t_factory.capturing then
    deleteLine()
    f2t_debug_log("[factory-status] Player has no company or business")

    -- Show error message
    cecho("\n<yellow>[factory]<reset> You don't have a company or business.\n")
    cecho("<dim_grey>You need to purchase a company first before building factories.<reset>\n")

    -- Reset state
    f2t_factory_reset()

elseif f2t_factory.flushing then
    deleteLine()
    f2t_debug_log("[factory-flush] Player has no company or business")

    -- Reset flush state
    f2t_factory.flushing = false
    f2t_factory.current_number = 0
    f2t_factory.flush_count = 0

    -- Show error message
    cecho("\n<yellow>[factory]<reset> You don't have a company or business.\n")
    cecho("<dim_grey>You need to purchase a company first before building factories.<reset>\n")
end
