-- @patterns:
--   - pattern: ^You have run out of fuel, and are unable to move\.$
--     type: regex
-- Emergency refuel when ship runs out of fuel

f2t_debug_log("[refuel] EMERGENCY: Ship out of fuel!")
cecho("\n<red>[refuel]<reset> <yellow>EMERGENCY:<reset> Out of fuel! Buying fuel immediately...\n")
send("buy fuel", false)
