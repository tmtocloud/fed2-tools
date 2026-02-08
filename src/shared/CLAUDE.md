# shared

Common utility functions and resources used across all fed2-tools components.

**📖 Quick Navigation:** See [CLAUDE_INDEX.md](../../CLAUDE_INDEX.md) for documentation index.

## Utility Functions

### Table Utilities (`f2t_table_utils.lua`)

**`has_value(tab, val)`** - Check if a table contains a specific value

```lua
local flags = gmcp.room.info.flags
if has_value(flags, "shuttlepad") then
    -- Do something when at a shuttlepad
end
```

Returns `true` if the value is found in the table, `false` otherwise. Uses `ipairs()` for array-like tables.

**`f2t_table_get_sorted_keys(tbl)`** - Get sorted keys from a table

```lua
local planets = {Earth = true, Mars = true, Venus = true}
local sorted_names = f2t_table_get_sorted_keys(planets)
-- Returns: {"Earth", "Mars", "Venus"}

-- Common use: Display hash table keys in alphabetical order
for _, planet in ipairs(sorted_names) do
    cecho(string.format("  %s\n", planet))
end
```

Returns an array of keys sorted alphabetically. Useful for consistent display of hash tables.

**`f2t_table_count_keys(tbl)`** - Count keys in a table

```lua
local planets = {Earth = true, Mars = true, Venus = true}
local count = f2t_table_count_keys(planets)  -- Returns: 3

-- Useful for hash tables where # operator doesn't work
local player_scores = {Alice = 100, Bob = 200, Charlie = 150}
cecho(string.format("Total players: %d\n", f2t_table_count_keys(player_scores)))
```

Returns the number of key-value pairs in a table. Works for hash tables where Lua's `#` operator returns 0.

### Debug Utilities (`f2t_debug.lua`)

**`f2t_debug_log(message)`** - Log a debug message if debug mode is enabled

```lua
f2t_debug_log("[component-name] Debug information here")
```

Only outputs if `F2T_DEBUG` is `true`. Add a newline at the start of debug messages to avoid line break issues with game output.

**`f2t_set_debug(enabled)`** - Enable or disable debug mode

**Global Variable**: `F2T_DEBUG` - Boolean flag for debug mode

### Argument Parsing Utilities (`f2t_arg_parser.lua`)

Shared helper functions for parsing command arguments consistently across all components.

#### Basic Parsing

**`f2t_parse_words(str)`** - Split arguments into words (space-separated)

```lua
local words = f2t_parse_words(args)  -- ["word1", "word2", ...]
```

**`f2t_parse_rest(words, start_index)`** - Get remaining arguments as single string

```lua
local name = f2t_parse_rest(words, 3)  -- Joins words[3] onwards with spaces
```

**`f2t_parse_subcommand(args, subcommand)`** - Extract subcommand with rest-of-line capture

```lua
local rest = f2t_parse_subcommand(args, "settings")  -- nil if doesn't start with "settings"
```

#### Argument Validation

**`f2t_parse_required_arg(words, index, component, usage_msg)`** - Parse required argument with automatic error handling

```lua
local planet = f2t_parse_required_arg(words, 2, "hauling", "Usage: haul start <planet>")
if not planet then return end  -- Error already shown to user
```

**`f2t_parse_required_number(words, index, component, usage_msg)`** - Parse required number with validation

```lua
local threshold = f2t_parse_required_number(words, 2, "refuel", "Usage: refuel <threshold>")
if not threshold then return end
```

**`f2t_parse_optional_number(words, index, default)`** - Parse optional number argument with default

```lua
local count = f2t_parse_optional_number(words, 2, 5)  -- Default: 5
```

**`f2t_parse_choice(words, index, choices, component, default)`** - Parse argument from allowed choices

```lua
local mode = f2t_parse_choice(words, 2, {"shuttlepad", "orbit"}, "map", "shuttlepad")
if not mode then return end  -- Error already shown
```

#### Design Principles

1. **Error messages built-in:** Validation functions display errors automatically
2. **Component name parameter:** Ensures consistent `[component]` prefix in error messages
3. **Return nil on error:** Caller just checks nil and returns early
4. **No exceptions:** Pure Lua, no error() calls

#### When NOT to Use

- Complex regex parsing (do it inline)
- State-dependent parsing (context matters)
- One-off special cases (not worth abstracting)

### Initialization (`init.lua`)

- Initializes the `f2t_settings` table for persistent storage
- Loads debug setting from persistent storage (defaults to `false`)
- Sets up `F2T_DEBUG` global variable

### Table Renderer (`f2t_table_renderer.lua`)

**`f2t_render_table(config)`** - Render tabular data with automatic layout and styling

Declarative API for displaying data in formatted tables with:
- Automatic column width calculation (max 100 columns for Fed2)
- Built-in formatters (compact numbers, percentages, booleans)
- Flexible styling (colors, alignment, truncation)
- Footer support with aggregations (sum, avg, min, max, count)

**Basic Example:**
```lua
f2t_render_table({
    title = "Player Inventory",
    columns = {
        {header = "Item", field = "name"},
        {header = "Qty", field = "quantity", align = "right", format = "number"},
        {header = "Value", field = "value", align = "right", format = "compact"}
    },
    data = {
        {name = "Alloys", quantity = 5, value = 50000},
        {name = "Crystals", quantity = 3, value = 75000}
    }
})
```

**Column Configuration:**
```lua
{
    header = "Name",          -- Required: Column header text
    field = "field_name",     -- Required: Field name in data rows
    align = "left",           -- Optional: "left", "right", "center" (default: "left")
    width = nil,              -- Optional: Fixed width (nil = auto-calculate)
    min_width = nil,          -- Optional: Minimum width (default: header length)
    max_width = nil,          -- Optional: Maximum width to prevent overflow
    format = "string",        -- Optional: "string", "number", "compact", "percent", "boolean"
    formatter = nil,          -- Optional: Custom function(value, row) -> string
    color = nil,              -- Optional: Static color: "green", "red", "yellow", etc.
    color_fn = nil,           -- Optional: Dynamic function(value, row) -> color
    truncate = true,          -- Optional: Truncate if exceeds max_width (default: true)
    hidden = false            -- Optional: Hide column (default: false)
}
```

**Built-in Formatters:**
- `"string"` - Convert to string (default)
- `"number"` - Floor to integer
- `"compact"` - Large numbers (1000 → 1K, 1500000 → 1.50M)
- `"percent"` - Decimal to percentage (0.75 → 75%)
- `"boolean"` - Boolean to Y/N

**Footer Aggregations:**
```lua
footer = {
    aggregations = {
        {field = "quantity", method = "sum"},
        {field = "value", method = "sum"},
        {
            field = "profit",
            method = "sum",
            color_fn = function(val) return val >= 0 and "green" or "red" end
        }
    }
}
```

**Supported Aggregation Methods:**
- `"sum"` - Total of all values
- `"avg"` - Average of all values
- `"min"` - Minimum value
- `"max"` - Maximum value
- `"count"` - Count of non-nil values

**Advanced Example (Factory Status):**
```lua
f2t_render_table({
    title = "Factory Status",
    max_width = COLS or 100,
    columns = {
        {header = "#", field = "number", align = "right", width = 2},
        {header = "Location", field = "location", max_width = 15, truncate = true},
        {
            header = "St",
            field = "status",
            width = 2,
            formatter = function(val) return val:sub(1, 1) end,
            color_fn = function(val, row)
                return row.status == "Running" and "green" or "yellow"
            end
        },
        {
            header = "P/L",
            field = "profit",
            align = "right",
            format = "compact",
            color_fn = function(val) return val >= 0 and "green" or "red" end
        }
    },
    data = factories,
    footer = {
        aggregations = {
            {field = "working_capital", method = "sum"},
            {field = "profit", method = "sum", color_fn = function(val) return val >= 0 and "green" or "red" end}
        }
    }
})
```

**Width Calculation Algorithm:**
1. Pre-calculates footer aggregations if configured
2. Calculates minimum widths (header length, explicit min_width, sampled data)
3. Calculates desired widths from content including footer row (up to max_width if specified)
4. If total fits within max_width, uses desired widths
5. Otherwise, shrinks flexible columns proportionally while respecting minimums
6. Fixed-width columns always get their specified width

**Performance Notes:**
- Samples large datasets (first 20 rows + every 10th row) for width calculation
- Footer row values included in width calculation to prevent truncation
- Renders rows incrementally to minimize memory usage
- Color codes stripped for accurate width measurement

**Alignment Notes:**
- Headers use the same alignment as their column data
- Set `align` to control both header and data alignment
- Default alignment is "left" if not specified

## Connection Management (`connection_handler.lua`)

Tracks connection state to prevent initialization issues.

**Global Flag**: `F2T_CONNECTED` - Boolean indicating if connected to game

**`f2t_check_connection()`** - Check current connection state

Returns `true` if connected, `false` otherwise. Uses `getConnectionInfo()`.

**Event Handling:**
- Monitors `sysConnectionEvent` for connection/disconnection
- Auto-detects connection state on package load
- Updates `F2T_CONNECTED` flag automatically

**Usage:**
```lua
-- In init scripts that need connection
if F2T_CONNECTED then
    -- Safe to send commands or access GMCP
    send("look")
end
```

Map component uses this to defer GMCP-dependent initialization until after connection.

## Version Checker (`f2t_version_checker.lua`)

Checks GitHub releases API for the latest version when user runs `f2t version`.

**Command:** `f2t version`

**Behavior:**
1. Shows current version immediately
2. If prerelease version (e.g., `1.0.0-abc123`), skips update check
3. If `getHTTP` unavailable (Mudlet <4.10), skips update check
4. Otherwise, async fetches latest release from GitHub API
5. Compares versions and displays update availability

**Global State:** `F2T_VERSION_CHECK_STATE`

```lua
{
    checking = false,           -- Is check in progress?
    handler_id = nil,           -- Success event handler ID
    error_handler_id = nil,     -- Error event handler ID
    timeout_timer_id = nil      -- Timeout timer ID
}
```

**Functions:**

- `f2t_check_latest_version()` - Main entry point, displays version and checks for updates
- `f2t_version_is_prerelease(version)` - Returns true if version contains hyphen suffix
- `f2t_version_is_newer(v1, v2)` - Semver comparison, returns true if v1 > v2
- `f2t_version_check_cleanup()` - Kills handlers and resets state

**Requirements:**
- Mudlet 4.10+ for update checking (gracefully degrades on older versions)
- Network access to `api.github.com`

## Rank Management (`f2t_rank.lua`)

Federation 2 rank checking utilities. Supports all 16 ranks.

**Rank Progression (1-16):**
Groundhog → Commander → Captain → Adventurer/Adventuress → Merchant → Trader → Industrialist → Manufacturer → Financier → Founder → Engineer → Mogul → Technocrat → Gengineer → Magnate → Plutocrat

**Note:** Adventurer/Adventuress are gender-specific variants at the same level (4).

### Query Functions

**`f2t_get_rank()`** - Get character's current rank

Returns rank string from `gmcp.char.vitals.rank`, or `nil` if unavailable.

**`f2t_get_rank_level(rank_name)`** - Get numeric level for a rank

Returns 1-16 (or `nil` if unknown). Case-insensitive.

### Comparison Functions

**`f2t_is_rank_or_above(required_rank)`** - Check if at/above rank

```lua
if f2t_is_rank_or_above("Merchant") then
    -- Character is Merchant or higher
end
```

**`f2t_is_rank_below(rank_name)`** - Check if below rank

```lua
if f2t_is_rank_below("Financier") then
    -- Character hasn't reached Financier yet
end
```

**`f2t_is_rank_exactly(rank_name)`** - Check exact rank match

```lua
if f2t_is_rank_exactly("Trader") then
    -- Character is exactly Trader rank
end
```

### Requirement Checking

**`f2t_check_rank_requirement(required_rank, feature_name)`** - Check and display error

Returns `true` if requirement met, `false` with user-facing error message otherwise.

```lua
-- In hauling automation
if not f2t_check_rank_requirement("Merchant", "Hauling automation") then
    return  -- Shows: "Hauling automation requires rank Merchant or higher"
end
```

## Tool Availability (`f2t_tools.lua`)

Checks game tools/upgrades available to the player via `gmcp.char.vitals.tools`.

### Query Functions

**`f2t_get_tool(tool_name)`** - Get tool data from GMCP

Returns the tool's data table (e.g., `{days = 20}`), or `nil` if not available. Safely checks the full GMCP path.

```lua
local cert = f2t_get_tool("remote-access-cert")
if cert then
    -- cert.days = days remaining
end
```

**`f2t_has_tool(tool_name)`** - Check if player has a tool

Returns `true`/`false`. Convenience wrapper around `f2t_get_tool()`.

```lua
if f2t_has_tool("remote-access-cert") then
    -- Player has the certificate
end
```

### Requirement Checking

**`f2t_check_tool_requirement(tool_name, feature_name, display_name)`** - Check and display error

Returns `true` if tool exists, `false` with user-facing error message otherwise. Mirrors `f2t_check_rank_requirement()`. Optional `display_name` provides a user-friendly name (defaults to `tool_name`).

```lua
if not f2t_check_tool_requirement("remote-access-cert", "Price checking", "Remote Price Check Service") then
    return  -- Shows: "Price checking requires the Remote Price Check Service tool"
end
```

## Resources

### `commodities.json`

Game data file containing commodity information. Access using:

```lua
local filePath = getMudletHomeDir() .. "/@PKGNAME@/shared/commodities.json"
local file = io.open(filePath, "r")
local jsonString = file:read("*all")
file:close()

local data = yajl.to_value(jsonString)  -- Parse JSON to Lua table
```

### Settings Persistence (`f2t_settings.lua`)

**IMPORTANT**: Mudlet does **NOT** automatically persist global Lua tables. Settings must be explicitly saved to disk.

**`f2t_save_settings()`** - Save the settings table to disk

```lua
-- Save settings after making changes
f2t_settings.my_component.enabled = true
f2t_save_settings()  -- REQUIRED to persist
```

**`f2t_load_settings()`** - Load settings from disk (called automatically on init)

Settings are stored at: `<mudlet_home>/fed2-tools_settings.lua`

## Persistent Settings Pattern

Components should use the shared `f2t_settings` table for storing persistent configuration:

```lua
-- Initialize your component's settings (in init.lua)
f2t_settings = f2t_settings or {}
f2t_settings.my_component = f2t_settings.my_component or {}

-- Load saved settings with defaults
local my_enabled = f2t_settings.my_component.enabled or false
local my_value = f2t_settings.my_component.value or "default"

-- Save settings when they change
function save_my_setting(key, value)
    f2t_settings.my_component[key] = value
    f2t_save_settings()  -- REQUIRED: Explicitly save to disk
end
```

**Example from refuel component**:
```lua
function f2t_refuel_set_threshold(percent)
    FUEL_REFUEL_THRESHOLD = percent
    f2t_settings.refuel.threshold = percent
    f2t_save_settings()  -- Save to disk immediately
    return true
end
```

**Why use `f2t_settings`:**
- Centralized settings for all fed2-tools components
- Explicitly persisted to disk with `f2t_save_settings()`
- Prevents global namespace pollution
- Easy to inspect/debug all settings in one place
- Survives Mudlet restarts when properly saved

## Help System (`f2t_help_registry.lua`, `f2t_help.lua`)

**CRITICAL**: Every user-facing command MUST provide help via `help`.

### Help Registry (PREFERRED)

Register help once in component init, use everywhere. Eliminates code duplication.

**`f2t_register_help(command, config)`** - Register help for a command

```lua
-- In component init script (e.g., map_help_init.lua)
f2t_register_help("nav", {
    description = "Navigate to a destination using speedwalk",
    usage = {
        {cmd = "nav <destination>", desc = "Navigate to saved destination"},
        {cmd = "nav <room_id>", desc = "Navigate to Mudlet room ID"},
        {cmd = "", desc = ""},  -- Visual separator
        {cmd = "nav stop", desc = "Stop active speedwalk"},
        {cmd = "nav pause", desc = "Pause active speedwalk"}
    },
    examples = {
        "nav Earth              # Navigate to Earth's shuttlepad",
        "",  -- Visual separator
        "nav pause              # Pause current speedwalk"
    }
})
```

**`f2t_handle_help(command, arg)`** - Check for help request and display registered help

```lua
-- In alias
local args = matches[2]

if f2t_handle_help("nav", args) then
    return  -- Help was shown, exit
end

-- Continue with command logic
```

**Benefits:**
- Help defined once, used everywhere
- No code duplication in aliases
- Easy to update help across all commands
- Clear separation: registration vs usage

### Direct Help Display (For Dynamic Help)

Use when help needs to be customized per invocation.

**`f2t_is_help_request(args)`** - Check if user requested help

Returns `true` if args is `help`

**`f2t_show_help(command, description, usage, examples)`** - Display formatted help

```lua
if f2t_is_help_request(args) then
    f2t_show_help("nav", "Navigate to a destination", {
        {cmd = "nav <destination>", desc = "Navigate to destination"},
        {cmd = "nav stop", desc = "Stop speedwalk"}
    }, {
        "nav Earth",
        "nav stop"
    })
    return
end
```

**Parameters:**
- `command` (string): Command name for header
- `description` (string): Brief description
- `usage` (table): Array of `{cmd, desc}` tables (use `{cmd = "", desc = ""}` for separators)
- `examples` (table, optional): Array of example strings (use `""` for separators)

**`f2t_show_help_hint(command)`** - Show "use X help for more info" hint

```lua
-- When user provides invalid arguments
cecho("\n<red>[command]<reset> Invalid argument\n")
f2t_show_help_hint("command")  -- Shows: "Use 'command help' for more information."
```

**`f2t_show_registered_help(command)`** - Display help from registry

Usually called via `f2t_handle_help()`, but can be called directly.

## Settings Management System (`f2t_settings_manager.lua`)

Unified settings system with automatic type conversion, validation, and persistence.

### Registration

**`f2t_settings_register(component, name, config)`** - Register a setting

```lua
-- In component init script
f2t_settings_register("refuel", "threshold", {
    description = "Fuel percentage threshold for refueling (0-100)",
    default = 50,
    validator = function(value)
        if type(value) ~= "number" then
            return false, "Must be a number"
        end
        if value < 0 or value > 100 then
            return false, "Must be between 0 and 100"
        end
        return true
    end
})

f2t_settings_register("map", "enabled", {
    description = "Enable/disable auto-mapping",
    default = true,
    validator = function(value)
        if type(value) ~= "boolean" then
            return false, "Must be true or false"
        end
        return true
    end
})
```

**Config Parameters:**
- `description` (string): User-facing description
- `default` (any): Default value
- `validator` (function, optional): `function(value) -> boolean, error_msg`

### Getting Settings

**`f2t_settings_get(component, name)`** - Get setting value

Returns the current value or default if not set.

```lua
local threshold = f2t_settings_get("refuel", "threshold")  -- Returns 50 (or user value)
local enabled = f2t_settings_get("map", "enabled")  -- Returns true (or user value)
```

### Setting Values

**`f2t_settings_set(component, name, value)`** - Set and validate setting

Returns `true, nil` on success or `false, error_msg` on failure.

```lua
local success, err = f2t_settings_set("refuel", "threshold", 80)
if not success then
    cecho(string.format("\n<red>[refuel]<reset> Error: %s\n", err))
    return
end

-- Automatically persists to disk
```

**Type Conversion:**
- String `"true"` / `"false"` → boolean
- String numbers `"80"` → number
- Preserves actual types when called programmatically

### Clearing Settings

**`f2t_settings_clear(component, name)`** - Reset to default

```lua
f2t_settings_clear("refuel", "threshold")
local default = f2t_settings_get("refuel", "threshold")  -- Returns 50
```

### Display Functions

**`f2t_settings_show_list(component)`** - List all registered settings

Displays table showing: setting name, value, default, description

**`f2t_settings_show_get(component, name)`** - Show specific setting

Displays: current value, default, description

### User Commands

Components should provide these commands:

```
<component> settings                    # List all
<component> settings get <name>         # Get specific
<component> settings set <name> <value> # Set value
<component> settings clear <name>       # Reset to default
```

**Example Implementation:**
```lua
-- In alias for "refuel settings ..."
local subcommand = words[1]

if subcommand == "list" or not subcommand then
    f2t_settings_show_list("refuel")
elseif subcommand == "get" then
    f2t_settings_show_get("refuel", words[2])
elseif subcommand == "set" then
    local success, err = f2t_settings_set("refuel", words[2], words[3])
    if not success then
        cecho(string.format("\n<red>[refuel]<reset> Error: %s\n", err))
    end
elseif subcommand == "clear" then
    f2t_settings_clear("refuel", words[2])
end
```

### Complex Data Structures

For nested tables (destinations, blacklists), use direct `f2t_settings` access:

```lua
-- Initialize
f2t_settings.map = f2t_settings.map or {}
f2t_settings.map.destinations = f2t_settings.map.destinations or {}

-- Add entry
f2t_settings.map.destinations["earth_ex"] = "Sol.Earth.123"
f2t_save_settings()  -- REQUIRED

-- These don't go through the registry - handle validation manually
```

## Stamina Monitoring System (`f2t_stamina_monitor.lua`, `f2t_stamina_settings.lua`)

**Always-on** stamina monitoring that works in two modes:

1. **Component mode** - When a component like hauling is active, automatically pauses the activity, navigates to food source, buys food, returns, and resumes.

2. **Standalone mode** - When no component is active, prompts the user with a y/n question before starting a food trip.

### Architecture

**Always-On Monitoring**: Stamina monitoring starts automatically on package load (if `stamina_threshold > 0`). It continues running until the threshold is set to 0.

**Dual-Mode Operation**:
- If a registered component's `check_active()` returns `true` → Component mode (automatic)
- Otherwise → Standalone mode (y/n prompt)

**Phase Flow**:
1. `idle` - Monitoring stamina levels
2. `navigating_to_food` - Traveling to food source
3. `buying_food` - Buying food until stamina is full
4. `navigating_back` - Returning to original location
5. Resume client (or just finish for standalone) → back to `idle`

### Settings

Registered in the `shared` component:

```lua
-- Threshold percentage to trigger food buying (0=disabled, 1-99=enabled)
f2t_settings_get("shared", "stamina_threshold")  -- default: 25

-- Food source location: Fed2 room hash OR saved destination name
-- Examples: "Sol.Earth.454", "earth", "Sol Exchange"
f2t_settings_get("shared", "food_source")  -- default: "Sol.Earth.454"
```

### Client Registration

Components that need stamina monitoring must register with the system:

```lua
-- In component init.lua
f2t_stamina_register_client({
    pause_callback = function()
        -- Pause your component's activity
        -- Example: F2T_HAULING_STATE.paused = true
    end,

    resume_callback = function()
        -- Resume your component's activity
        -- Example: F2T_HAULING_STATE.paused = false
    end,

    check_active = function()
        -- Return true if component is actively running
        -- Example: return F2T_HAULING_STATE.active and not F2T_HAULING_STATE.paused
    end
})
```

**Callback Requirements**:
- `pause_callback`: Called when stamina is low - must pause component activity
- `resume_callback`: Called when stamina is restored - must resume component activity
- `check_active`: **CRITICAL** - Returns boolean indicating if component is currently running
  - Must return `true` only when actively running (not just registered)
  - Callbacks are ONLY called when `check_active()` returns `true`
  - If `false`, stamina monitor uses standalone mode (y/n prompt)

**Integration Pattern**:
1. Register callbacks once at component init (not at start)
2. `check_active()` gates whether callbacks are used
3. Multiple components can register; only active ones are paused
4. Last registration overwrites previous (single-client model for now)

### Monitoring Control

**Automatic Start**: Monitoring starts automatically on package load via `tempTimer` in `init.lua`. Components do NOT need to call `f2t_stamina_start_monitoring()`.

**Prompt Cancellation**: When a component becomes active while a standalone prompt is showing, call:
```lua
if f2t_stamina_cancel_standalone_prompt then
    f2t_stamina_cancel_standalone_prompt()
end
```

**Manual Control** (rarely needed):
```lua
f2t_stamina_start_monitoring()  -- Start if not running
f2t_stamina_stop_monitoring()   -- Stop completely
```

### State Management

**Global State**: `F2T_STAMINA_STATE`

```lua
{
    monitoring_active = false,       -- Is monitoring running?
    current_phase = "idle",          -- Current phase

    -- Client callbacks
    client_pause_callback = nil,
    client_resume_callback = nil,
    client_check_active = nil,

    -- Trip tracking
    return_location = nil,           -- Where to go back to
    client_was_paused = false,       -- Did we pause the client?

    -- Stamina tracking
    current_stamina = 0,
    max_stamina = 1,

    -- GMCP event handler IDs
    gmcp_handler_id = nil,               -- Stamina vitals handler
    nav_handler_id = nil,                -- Navigation completion handler

    -- Standalone mode (yes/no prompt)
    standalone_prompt_active = false,    -- Is prompt showing?
    standalone_prompt_aliases = {},      -- Alias IDs for cleanup
    standalone_prompt_timer = nil,       -- Timeout timer ID (30s)
    standalone_dismissed_at = nil        -- Timestamp when dismissed/timed out
}
```

**Constants**:
- `F2T_STAMINA_DISMISS_COOLDOWN = 300` - 5 minutes before re-prompting after dismiss/timeout
- `F2T_STAMINA_PROMPT_TIMEOUT = 30` - Prompt auto-dismisses after 30 seconds

### Standalone Mode Behavior

When no component is active and stamina drops below threshold:

1. System shows y/n prompt: "Low stamina: X% (threshold: Y%). Would you like to go refill? (y/n):"
2. User types `y` → Starts food trip (same as component mode but without pause/resume callbacks)
3. User types `n` → Dismisses prompt, starts 5-minute cooldown before re-prompting
4. If user starts a component (e.g., hauling) while prompt is active → Prompt is cancelled

### Integration Example (Hauling Component)

```lua
-- src/hauling/scripts/init.lua

-- Register with stamina monitor (once at init)
f2t_stamina_register_client({
    pause_callback = f2t_hauling_pause,
    resume_callback = f2t_hauling_resume,
    check_active = function()
        return F2T_HAULING_STATE.active and not F2T_HAULING_STATE.paused
    end
})

-- src/hauling/scripts/state_machine.lua

function f2t_hauling_start()
    -- ... setup code ...

    -- Cancel any standalone stamina prompt (hauling will handle it)
    if f2t_stamina_cancel_standalone_prompt then
        f2t_stamina_cancel_standalone_prompt()
    end

    -- ... continue with hauling ...
end

function f2t_hauling_do_stop()
    -- ... cleanup code ...

    -- Note: Stamina monitoring continues running (always-on mode)
    -- It will revert to standalone prompt mode now that hauling is inactive

    -- ... reset state ...
end
```

### How It Works

**Component Mode** (when registered client is active):
1. **Monitoring**: Registers GMCP event handler on `gmcp.char.vitals.stamina` updates
2. **Detection**: When stamina drops below threshold AND client is active, trigger food trip
3. **Pause**: Call client's `pause_callback()` to halt current activity
4. **Navigate**: Use map system (`f2t_map_navigate()`) to reach food source
5. **Buy Food**: Repeatedly `buy food` (which auto-consumes, +10 stamina each) until stamina = 100%
6. **Return**: Navigate back to saved location
7. **Resume**: Call client's `resume_callback()` to continue activity

**Standalone Mode** (no active client):
1. **Monitoring**: Same GMCP handler
2. **Detection**: When stamina drops below threshold, show y/n prompt
3. **Wait for Input**: User types `y` or `n`
4. **If Yes**: Navigate to food, buy food, return to original location
5. **If No**: Set 5-minute cooldown before re-prompting

### Key Design Patterns

**Caller-Driven Pausing**: The stamina monitor doesn't know how to pause/resume specific components. Each component provides its own callbacks.

**GMCP-Driven**: Uses GMCP events for stamina updates and room changes, not polling timers.

**State Preservation**: Saves original location and client state to enable clean resumption.

**Non-Blocking**: Uses `tempTimer()` for delays between food purchases to allow GMCP updates.

**Navigation Ownership**: Stamina sets navigation ownership when starting food trips to handle interrupts (customs, out-of-fuel) gracefully. See `src/map/CLAUDE.md` section "Navigation Ownership Model" for the full pattern.

### Food Buying Logic

The game command `buy food` automatically consumes the food and increases stamina by 10 points. The system:

1. Buys food
2. Waits 0.5s for GMCP stamina update
3. Checks if stamina < 100%
4. If still hungry, recursively calls `f2t_stamina_phase_buy_food()` again
5. If full, transitions to return navigation

This continues until stamina reaches 100%.

### Error Handling

- **Navigation Failure**: If can't navigate to food source or back, resume client at current location
- **Missing GMCP**: Silently skips if stamina vitals unavailable
- **Already Active**: Ignores duplicate food trip requests if already in progress
- **Client Check**: Only triggers when client's `check_active()` returns true

### Dependencies

- Map system (`f2t_map_navigate()`, `F2T_SPEEDWALK_ACTIVE`)
- Settings system (`f2t_settings_get()`, `f2t_settings_register()`)
- GMCP (`gmcp.char.vitals.stamina`, `gmcp.room.info`)
- Debug logging (`f2t_debug_log()`)

## Death Monitoring System (`f2t_death_monitor.lua`, `f2t_death_settings.lua`)

**Always-on** death monitoring that automatically:
1. Detects death via the message "Darkness closes in. Farewell!"
2. Captures the death room location BEFORE respawn teleport
3. Stops all active automation (hauling, explore, speedwalk)
4. Issues `insure` command after respawning
5. Permanently locks the death room (navigation avoids it)
6. Annotates the room with death metadata

### Architecture

**Trigger-Based Detection**: Uses permanent trigger on death message. Trigger fires BEFORE the game teleports the player, allowing location capture.

**GMCP-Based Respawn Detection**: Registers temporary GMCP handler to detect room change after death.

**Phase Flow**:
1. `idle` - Normal gameplay, monitoring active
2. `awaiting_respawn` - Death detected, waiting for room change
3. `processing` - Respawned, executing recovery (insure + lock)
4. Return to `idle`

### Settings

```lua
-- Enable/disable death monitoring
f2t_settings_get("shared", "death_monitor_enabled")  -- default: true
```

### State Management

**Global State**: `F2T_DEATH_STATE`

```lua
{
    monitoring_active = false,      -- Is monitoring initialized?
    active = false,                 -- Is death recovery in progress?
    current_phase = "idle",         -- idle, awaiting_respawn, processing

    -- Death location
    death_room_hash = nil,          -- "system.area.num" format
    death_room_id = nil,            -- Mudlet room ID for locking

    -- GMCP handler
    gmcp_handler_id = nil,          -- Respawn detection handler

    -- Timeout
    timeout_timer_id = nil          -- 30s safety timeout
}
```

### Components Stopped on Death

When death is detected, the system immediately stops all active automation:

1. **Hauling** - `f2t_hauling_terminate()` (full stop, not pause)
2. **Map Exploration** - `f2t_map_explore_stop()`
3. **Speedwalk/Navigation** - `f2t_map_speedwalk_stop()`
4. **Navigation Ownership** - `f2t_map_clear_nav_owner()`

### Room Locking

Death rooms are locked using the map's existing lock system:

```lua
-- Lock the room
f2t_map_manual_lock_room(room_id)

-- Add death-specific metadata
setRoomUserData(room_id, "f2t_locked_reason", "death")
setRoomUserData(room_id, "f2t_death_date", os.date("%Y-%m-%d %H:%M:%S"))
```

**View death room status:**
```
map room info <room_id>
```

Shows: Room locked status + death location timestamp

### User Summary

After recovery completes, displays summary box:

```
+-------------------------------------------+
|            DEATH RECOVERY                 |
+-------------------------------------------+
|  Death Location: Sol.Earth.519            |
|  Room: Park (if mapped)                   |
|  Insurance: Claimed                       |
|  Room Status: LOCKED (navigation avoids)  |
+-------------------------------------------+
```

### User Commands

No new commands - system is automatic and always-on.

**Existing commands:**
```
f2t settings                                    # Shows death_monitor_enabled
f2t settings set death_monitor_enabled false    # Disable
f2t settings set death_monitor_enabled true     # Enable
map room info <id>                            # Shows death metadata
map room unlock <id>                            # Unlock at own risk
```

### Timing

| Event | Delay | Reason |
|-------|-------|--------|
| Trigger → capture | 0ms | Must capture before teleport |
| GMCP check | 0.1s | Let GMCP update propagate |
| Respawn → insure | 0.3s | Game state stabilization |
| Insure → lock | 0.5s | Let insure process |
| Timeout | 30s | Safety if GMCP fails |

### Key Files

- `scripts/f2t_death_monitor.lua` - Core state machine
- `scripts/f2t_death_settings.lua` - Settings registration
- `triggers/death_detected.lua` - Death trigger

### Dependencies

- Map system (`f2t_map_manual_lock_room()`, `F2T_MAP_CURRENT_ROOM_ID`)
- Map navigation (`f2t_map_speedwalk_stop()`, `f2t_map_clear_nav_owner()`)
- Map explore (`f2t_map_explore_stop()`)
- Hauling (`f2t_hauling_terminate()`)
- Settings system (`f2t_settings_register()`, `f2t_settings_get()`)
- GMCP (`gmcp.room.info`)
- Debug logging (`f2t_debug_log()`)
