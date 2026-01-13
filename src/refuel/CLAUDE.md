# refuel

Automatically refuels your ship when you enter a shuttlepad and fuel drops below a configurable threshold (default: 50%).

## Usage

- Passive - automatically triggers on room change when enabled
- `refuel` - View current status (enabled/disabled and threshold)
- `refuel <percent>` - Set refuel threshold (1-100) and enable automatic refueling
- `refuel off` - Disable automatic refueling

## How it works

**Automatic Refueling:**
1. GMCP event handler triggers on every room change (`gmcp.room.info`)
2. Checks if automatic refueling is enabled (`REFUEL_ENABLED`)
3. Checks GMCP data for room flags (`gmcp.room.info.flags`)
4. If room has "shuttlepad" flag, checks fuel level (`gmcp.char.ship.fuel`)
5. Buys fuel if current fuel is ≤ configured threshold percentage

**Emergency Refueling:**
1. Triggers on the game message "You have run out of fuel, and are unable to move."
2. Immediately buys fuel without checking location or enabled state
3. Works as a safety net if automatic refueling fails or is disabled

## Implementation Pattern

- **GMCP event handler**: Uses `registerAnonymousEventHandler("gmcp.room.info", ...)` to detect room changes
- **Enable/disable state**: Early return in handler if `REFUEL_ENABLED` is false
- **GMCP data access**: Reads `gmcp.room.info.flags` and `gmcp.char.ship.fuel.*`
- **Persistent settings**: Uses `f2t_settings.refuel.enabled` and `f2t_settings.refuel.threshold` for user configuration
- **Component initialization**: `init.lua` loads enabled state and threshold, `refuel_settings.lua` provides helper functions
- **Shared utilities**: Uses `f2t_has_value()` from shared table utilities
- **Message convention**: All `cecho()` messages start with `\n` to avoid line break issues with game output

## Key Files

- `init.lua` (script) - Initialize enabled state and threshold from persistent storage
- `refuel_settings.lua` (script) - Helper functions: `f2t_refuel_is_enabled()`, `f2t_refuel_enable()`, `f2t_refuel_disable()`, `f2t_refuel_set_threshold(percent)`, `f2t_refuel_show_status()`
- `refuel_gmcp_handler.lua` (script) - GMCP event handler for room changes, checks shuttlepad flag and fuel level
- `emergency_refuel.lua` (trigger) - Emergency fuel purchase when ship runs completely out of fuel
- `refuel.lua` (alias) - User command to view status, enable/disable, or change threshold
- `refuel_help_init.lua` (script) - Help registry initialization
