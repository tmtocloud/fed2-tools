# fed2-tools Common Code Patterns

Quick reference for frequently-used implementation patterns. Copy-paste these as starting points.

**Full documentation:** See [CLAUDE.md](CLAUDE.md) and [src/shared/CLAUDE.md](src/shared/CLAUDE.md)

## Table of Contents

1. [Consolidated Alias Pattern](#consolidated-alias-pattern)
2. [Help System Integration](#help-system-integration)
3. [Settings Registration](#settings-registration)
4. [Capturing Game Output](#capturing-game-output)
5. [Component Initialization](#component-initialization)
6. [GMCP Data Access](#gmcp-data-access)
7. [Dual-Mode Command Pattern](#dual-mode-command-pattern)
8. [Debug Logging](#debug-logging)
9. [Table Rendering](#table-rendering)
10. [Event-Driven State Machine Pattern](#event-driven-state-machine-pattern)
11. [Common Pitfalls and Lessons Learned](#common-pitfalls-and-lessons-learned)

---

## Consolidated Alias Pattern

**One alias file per command with all subcommands.**

### Simple Command (No Subcommands)

```lua
-- File: bb.lua
-- @regex: ^bb(?:\s+(.+))?$

local args = matches[2]

-- No arguments - show help
if not args or args == "" then
    f2t_show_registered_help("bb")
    return
end

-- Check for help request
if f2t_handle_help("bb", args) then return end

-- Parse arguments
local commodity, count_str = args:match("^(%S+)%s*(%d*)$")
local count = count_str ~= "" and tonumber(count_str) or nil

-- Execute command
f2t_bulk_buy_start(commodity, count)
```

### Command with Subcommands

```lua
-- File: nav.lua
-- @regex: ^(?:nav|go|goto)(?:\s+(.+))?$

local args = matches[2]

-- No arguments - show help
if not args or args == "" then
    f2t_show_registered_help("nav")
    return
end

-- Check for help request
if f2t_handle_help("nav", args) then return end

-- Parse subcommand
local subcommand = string.lower(args):match("^(%S+)")

if subcommand == "stop" then
    f2t_map_speedwalk_stop()
elseif subcommand == "pause" then
    f2t_map_speedwalk_pause()
elseif subcommand == "resume" then
    f2t_map_speedwalk_resume()
else
    -- Default: treat as destination
    f2t_map_navigate(args)
end
```

### Settings Subcommand Pattern

```lua
-- File: refuel.lua
-- @regex: ^refuel(?:\s+(.+))?$

local args = matches[2]

-- No arguments - show status
if not args or args == "" then
    f2t_refuel_show_status()
    return
end

-- Check for help request
if f2t_handle_help("refuel", args) then return end

-- Parse subcommand
local subcommand = string.lower(args):match("^(%S+)")

if subcommand == "settings" then
    -- Parse settings subcommand
    local rest = args:match("^settings%s+(.+)")

    if not rest or rest == "" then
        f2t_settings_show_list("refuel")
        return
    end

    local words = {}
    for word in string.gmatch(rest, "%S+") do
        table.insert(words, word)
    end

    local subcmd = words[1]

    if subcmd == "list" then
        f2t_settings_show_list("refuel")
    elseif subcmd == "get" then
        if not words[2] then
            cecho("\n<red>[refuel]<reset> Usage: refuel settings get <name>\n")
            return
        end
        f2t_settings_show_get("refuel", words[2])
    elseif subcmd == "set" then
        if not words[2] or not words[3] then
            cecho("\n<red>[refuel]<reset> Usage: refuel settings set <name> <value>\n")
            return
        end
        local success, err = f2t_settings_set("refuel", words[2], words[3])
        if success then
            cecho(string.format("\n<green>[refuel]<reset> Setting <cyan>%s<reset> set to <yellow>%s<reset>\n",
                words[2], words[3]))
        else
            cecho(string.format("\n<red>[refuel]<reset> Error: %s\n", err))
        end
    elseif subcmd == "clear" then
        if not words[2] then
            cecho("\n<red>[refuel]<reset> Usage: refuel settings clear <name>\n")
            return
        end
        f2t_settings_clear("refuel", words[2])
        local default = f2t_settings_get("refuel", words[2])
        cecho(string.format("\n<green>[refuel]<reset> Setting <cyan>%s<reset> cleared (default: <yellow>%s<reset>)\n",
            words[2], tostring(default)))
    else
        cecho("\n<red>[refuel]<reset> Unknown subcommand: list, get, set, clear\n")
    end

elseif subcommand == "off" then
    f2t_refuel_disable()

else
    -- Parse as threshold number
    local threshold = tonumber(args)
    if threshold then
        f2t_refuel_set_threshold(threshold)
    else
        cecho("\n<red>[refuel]<reset> Invalid argument\n")
        f2t_show_help_hint("refuel")
    end
end
```

---

## Help System Integration

### Help Registry (Preferred)

**Step 1: Register help in component init script**

```lua
-- File: src/component/scripts/help_init.lua

f2t_register_help("command", {
    description = "Brief description of command",
    usage = {
        {cmd = "command <arg>", desc = "Do something with arg"},
        {cmd = "command stop", desc = "Stop the command"},
        {cmd = "", desc = ""},  -- Visual separator
        {cmd = "command settings", desc = "Manage settings"}
    },
    examples = {
        "command foo       # Example with comment",
        "command stop      # Another example",
        "",  -- Visual separator
        "command settings  # Settings example"
    }
})
```

**Step 2: Use in alias**

```lua
-- File: command.lua
-- @regex: ^command(?:\s+(.+))?$

local args = matches[2]

-- Check for help and show registered help
if f2t_handle_help("command", args) then
    return
end

-- Continue with command logic
```

### Direct Help Display (Dynamic Help)

```lua
-- When help needs to be customized per invocation
if f2t_is_help_request(args) then
    f2t_show_help("command", "Description", {
        {cmd = "command <arg>", desc = "Do something"},
        {cmd = "command stop", desc = "Stop command"}
    }, {
        "command foo",
        "command stop"
    })
    return
end
```

---

## Settings Registration

### In Component Init Script

```lua
-- File: src/component/scripts/init.lua

-- Register settings
f2t_settings_register("component", "setting_name", {
    description = "User-facing description of setting",
    default = default_value,
    validator = function(value)
        if type(value) ~= "expected_type" then
            return false, "Must be a <type>"
        end
        if value < min or value > max then
            return false, string.format("Must be between %d and %d", min, max)
        end
        return true
    end
})

-- Initialize from settings
COMPONENT_SETTING = f2t_settings_get("component", "setting_name")
```

### Common Validator Patterns

```lua
-- Number range validator
validator = function(value)
    if type(value) ~= "number" then
        return false, "Must be a number"
    end
    if value < 0 or value > 100 then
        return false, "Must be between 0 and 100"
    end
    return true
end

-- Boolean validator
validator = function(value)
    if type(value) ~= "boolean" then
        return false, "Must be true or false"
    end
    return true
end

-- String enum validator
validator = function(value)
    if type(value) ~= "string" then
        return false, "Must be a string"
    end
    local valid = {shuttlepad = true, orbit = true}
    if not valid[value] then
        return false, "Must be 'shuttlepad' or 'orbit'"
    end
    return true
end
```

### Using Settings

```lua
-- Get setting
local value = f2t_settings_get("component", "setting_name")

-- Set setting (with validation)
local success, err = f2t_settings_set("component", "setting_name", new_value)
if not success then
    cecho(string.format("\n<red>[component]<reset> Error: %s\n", err))
    return
end
-- Automatically persists to disk

-- Clear setting (reset to default)
f2t_settings_clear("component", "setting_name")
```

---

## Capturing Game Output

**⚠️ CRITICAL MUDLET LIMITATIONS:**

1. **Individual regex patterns CANNOT match text across line breaks** - Mudlet processes game output line-by-line. Even with `isMultiline="yes"`, individual patterns only match within a single line.

2. **`isMultiline="yes"` does NOT enable cross-line matching** - This flag enables AND trigger mode (multiple patterns matching within line delta), NOT the ability for a single regex to span lines.

3. **Text wrapping can occur ANYWHERE** - Don't assume where line breaks will appear. The game server may wrap text at any position based on line length limits.

**Solutions:** Use these patterns to work within Mudlet's line-by-line processing model.

### Pattern Selection Guide

Use this decision tree to choose the right pattern:

```
Is the output variable-length (unknown # of lines)?
├─ YES → Pattern 2: Timer-Based Capture
└─ NO  → Continue...

Is there an explicit end marker (prompt, specific message)?
├─ YES → Pattern 1: Explicit End Trigger
└─ NO  → Continue...

Is this just 2 lines that might wrap?
├─ YES → Pattern 3: Text Accumulation
└─ NO  → Consider Event-Driven State Machine (see below)
```

**Quick Reference:**

| Pattern | Use Case | Examples |
|---------|----------|----------|
| **Pattern 1: Explicit End** | Known end marker | Price output (ends with prompt) |
| **Pattern 2: Timer-Based** | Variable-length, no end marker | Factory status, AC jobs |
| **Pattern 3: Text Accumulation** | Simple 2-line wraps | AC delivery fee, single values |

---

### Pattern 1: Explicit End Marker Capture

**⚠️ CRITICAL: Fed2 does NOT reliably send prompts. NEVER use prompt triggers (`type: prompt`) for completion detection.**

Use when output has a known start pattern and a **specific text end marker** (NOT a prompt).

**Global state (in init.lua):**

```lua
F2T_COMPONENT_CAPTURE_ACTIVE = false
F2T_COMPONENT_CAPTURE_DATA = {}
```

**Start trigger:**

```lua
-- File: src/component/triggers/capture_start.lua
-- @pattern: ^Output starts here
-- @pattern-type: regex

if not F2T_COMPONENT_CAPTURE_ACTIVE then
    deleteLine()  -- REQUIRED: Hide game output
    F2T_COMPONENT_CAPTURE_ACTIVE = true
    F2T_COMPONENT_CAPTURE_DATA = {}
    f2t_debug_log("[component] Capture started")
end
```

**Capture trigger:**

```lua
-- File: src/component/triggers/capture_line.lua
-- @pattern: ^(.+data pattern.+)$
-- @pattern-type: regex

if F2T_COMPONENT_CAPTURE_ACTIVE then
    deleteLine()  -- REQUIRED: Hide game output
    table.insert(F2T_COMPONENT_CAPTURE_DATA, line)
end
```

**End trigger (explicit text marker - NEVER use prompt triggers!):**

```lua
-- File: src/component/triggers/capture_end.lua
-- @pattern: ^Explicit end marker text from game$
-- @pattern-type: regex

if F2T_COMPONENT_CAPTURE_ACTIVE then
    f2t_debug_log("[component] Captured %d lines", #F2T_COMPONENT_CAPTURE_DATA)

    -- Process captured data
    local results = process_data(F2T_COMPONENT_CAPTURE_DATA)

    -- Display formatted output
    display_formatted_results(results)

    -- Reset state
    F2T_COMPONENT_CAPTURE_ACTIVE = false
    F2T_COMPONENT_CAPTURE_DATA = {}
end
```

**Real-world example:** See `src/hauling/triggers/hauling_akaturi_job_end_marker.lua` which uses:
```lua
-- @pattern: ^Delivery details will be provided when you collect the package\.$
```

### Pattern 2: Timer-Based Capture (Broad Pattern)

Use when output format is unknown or variable, no clear end marker. Captures ALL lines when active, timer expires after 0.5s of silence to detect completion.

**Benefits:**
- Works with unknown/variable output formats
- Simple: one trigger instead of multiple specific patterns
- Reliable: timer-based completion detection
- Resilient: handles wrapped lines, extra blank lines, etc.

**Examples:** `factory status`, `jump` (in map component)

**⚠️ CRITICAL TIMER REQUIREMENT:**
The timer callback MUST always finish capture when it expires, regardless of data captured. Never check `#data > 0` in the timer condition or capture will stay active forever if pattern matching fails.

**Global state (in init.lua):**

```lua
F2T_COMPONENT_CAPTURE = {
    active = false,
    data = {}
}

local component_timer_id = nil
```

**Single capture trigger (captures ALL lines):**

```lua
-- File: src/component/triggers/capture_line.lua
-- @pattern: ^.+$
-- @pattern-type: regex

-- Only capture when actively capturing
if F2T_COMPONENT_CAPTURE.active then
    deleteLine()  -- REQUIRED: Hide game output

    -- Parse and store line data
    -- (Custom parsing logic here based on line content)
    table.insert(F2T_COMPONENT_CAPTURE.data, line)

    -- Reset timer on each line
    f2t_component_reset_timer()
end
```

**Timer functions (in script):**

```lua
-- File: src/component/scripts/capture_timer.lua

-- Start/reset capture completion timer
function f2t_component_reset_timer()
    -- Cancel existing timer
    if component_timer_id then
        killTimer(component_timer_id)
    end

    -- Start new timer - if no more lines arrive in 0.5s, we're done
    component_timer_id = tempTimer(0.5, function()
        -- CRITICAL: Always finish capture when timer expires, even with zero data
        -- Don't check for data > 0 or capture will stay active forever!
        if F2T_COMPONENT_CAPTURE.active then
            f2t_debug_log("[component] Capture timeout - processing %d lines", #F2T_COMPONENT_CAPTURE.data)
            f2t_component_process_capture()
        end
        component_timer_id = nil
    end)
end

-- Process captured data
function f2t_component_process_capture()
    -- Process the data
    local results = process_data(F2T_COMPONENT_CAPTURE.data)

    -- Display formatted output
    display_formatted_results(results)

    -- Reset state
    F2T_COMPONENT_CAPTURE.active = false
    F2T_COMPONENT_CAPTURE.data = {}
end
```

**Initiate capture:**

```lua
-- Start capture when sending command
function f2t_component_start()
    F2T_COMPONENT_CAPTURE.active = true
    F2T_COMPONENT_CAPTURE.data = {}

    send("game command")

    -- OPTIONAL: Start timer immediately for responsiveness
    -- If you do this, ensure ALL triggers (including start markers) reset the timer!
    -- See "Network Latency Race Condition" warning below
end
```

**⚠️ WARNING: Network Latency Race Condition**

If you start the timer immediately after sending the command (rather than letting the first trigger start it), you create a race condition with network latency:

```lua
-- ❌ WRONG: Race condition
function f2t_component_start()
    F2T_COMPONENT_CAPTURE.active = true
    F2T_COMPONENT_CAPTURE.data = {}
    send("game command")
    f2t_component_reset_timer()  -- Timer starts, but response hasn't arrived yet!
end

-- Single capture trigger
if F2T_COMPONENT_CAPTURE.active then
    deleteLine()
    table.insert(F2T_COMPONENT_CAPTURE.data, line)
    f2t_component_reset_timer()  -- Resets timer, but might be too late!
end
```

**Problem:** If network latency > 500ms, timer fires before first line arrives, capture completes with zero data.

**Solution 1 (Preferred):** Let the first trigger start the timer:

```lua
-- ✅ CORRECT: Timer starts when output arrives
function f2t_component_start()
    F2T_COMPONENT_CAPTURE.active = true
    F2T_COMPONENT_CAPTURE.data = {}
    send("game command")
    -- No timer start here
end
```

**Solution 2:** If you must start timer early (for timeout detection), ensure ALL triggers reset it:

```lua
-- ✅ CORRECT: Start marker also resets timer
-- Trigger for start marker (e.g., header line)
if F2T_COMPONENT_CAPTURE.active then
    deleteLine()
    f2t_component_reset_timer()  -- Critical: prevents premature timeout
end

-- Trigger for data lines
if F2T_COMPONENT_CAPTURE.active then
    deleteLine()
    table.insert(F2T_COMPONENT_CAPTURE.data, line)
    f2t_component_reset_timer()  -- Also resets on each data line
end
```

**Key Differences:**

| Feature | Prompt-Based | Timer-Based |
|---------|--------------|-------------|
| Triggers | 3+ (start, capture, end) | 1 (capture all) |
| End detection | Prompt trigger | Timer timeout |
| Pattern matching | Specific patterns | Broad `^.+$` |
| Line parsing | In triggers | In timer callback |
| Best for | Known formats | Unknown/variable formats |
| Examples | commodities, bulk-commands | factory, map jump |

---

### Pattern 3: Text Accumulation

**Use when:**
- Simple case: 2-part message that might wrap
- Single datum (number, name, status) that might span lines
- Line breaks can occur ANYWHERE in the message
- Not variable-length output

**How it works:**
1. Trigger 1 captures first part independently
2. Trigger 2 captures second part independently
3. Match them by state/phase context, not by requiring them on same line

**Reference Implementation:** `src/hauling/triggers/hauling_ac_deliver_*` (AC delivery fee)

**⚠️ CRITICAL: Fully Decouple the Two Parts**

Don't assume ANY parts will be on the same line. Text can wrap at any position:
```
"and your fee of 900ig has been transferred to your account."  ← All on one line
```
```
"and your fee of
900ig has been transferred to your account."  ← Break after "of"
```
```
"and your fee of 900ig
has been transferred to your account."  ← Break after amount
```

**Solution:** Capture each part independently without requiring them on same line.

**State Storage (in init.lua or state_machine.lua):**

```lua
-- Add to state structure:
COMPONENT_STATE.captured_value = nil

-- Reset in cleanup:
COMPONENT_STATE.captured_value = nil
```

**First Part Trigger (Capture Value):**

```lua
-- File: src/component/triggers/component_capture_value.lua
-- @pattern: ([\d,]+)ig
-- @pattern-type: regex

-- Capture the numeric value during active phase
if not (COMPONENT_STATE.active and COMPONENT_STATE.phase == "target_phase") then
    return
end

-- Don't capture multiple times
if COMPONENT_STATE.captured_value then
    return
end

-- Extract and store value
local value_str = matches[2]:gsub(",", "")
local value = tonumber(value_str)

if not value then
    f2t_debug_log("[component] Could not parse value: %s", matches[2])
    return
end

COMPONENT_STATE.captured_value = value
f2t_debug_log("[component] Captured value: %d (waiting for confirmation)", value)
```

**Second Part Trigger (Confirm and Process):**

```lua
-- File: src/component/triggers/component_confirm.lua
-- @pattern: has been transferred to your account
-- @pattern-type: substring

-- Confirm transaction using previously captured value
if not (COMPONENT_STATE.active and COMPONENT_STATE.phase == "target_phase") then
    return
end

-- Check if we captured a value
if not COMPONENT_STATE.captured_value then
    f2t_debug_log("[component] Confirmation seen but no value captured")
    return
end

local value = COMPONENT_STATE.captured_value
f2t_debug_log("[component] Transaction confirmed: %d", value)

-- Process the confirmed value
component_process_value(value)

-- Schedule next phase after brief delay
tempTimer(0.1, function()
    if COMPONENT_STATE.active and COMPONENT_STATE.phase == "target_phase" then
        component_transition_to_next_phase()
    end
end)
```

**Real Example: AC Delivery Fee**

Game output can wrap ANYWHERE:
```
"and your fee of 900ig
has been transferred to your account."
```

But the line break position varies unpredictably.

**Implementation:**
1. `hauling_ac_deliver_capture_payment.lua` - Pattern: `([\d,]+)ig`
   - Captures ANY number followed by "ig" during delivery phase
   - Stores in `F2T_HAULING_STATE.ac_payment_amount`

2. `hauling_ac_deliver_success.lua` - Pattern: `has been transferred to your account` (substring)
   - Confirms delivery using stored amount
   - Triggers phase completion

This handles breaks at **any position** because we don't require both parts on same line.

**Key Points:**
- Store captured data, not just a boolean flag
- Each trigger matches independently
- Match them via state/phase context
- Works regardless of where line breaks occur
- Simpler than timer-based for 2-part messages
- Clear captured data in cleanup

---

### ⚠️ CRITICAL: Content-Based Deletion Principle

**NEVER delete lines blindly.** Always check line content BEFORE calling `deleteLine()`.

**Problem:** Using broad patterns (`^.*$`) with immediate `deleteLine()` will delete ALL game output when capture is active, including unrelated text like room descriptions, speedwalk output, or other commands.

**Solution:** Check if the line actually matches your expected output format before deleting.

**Anti-Pattern (WRONG):**
```lua
-- This deletes EVERYTHING when active - breaks speedwalk, hides rooms, etc.
if F2T_COMPONENT_CAPTURE.active then
    deleteLine()  -- ❌ WRONG: Deletes before checking content

    if line:find("expected pattern") then
        -- Process line
    end
end
```

**Correct Pattern:**
```lua
-- Only deletes lines that actually match expected output
if F2T_COMPONENT_CAPTURE.expecting or F2T_COMPONENT_CAPTURE.active then
    local is_output_line = false

    -- Check content FIRST
    if line:find("^Expected Header:") then
        is_output_line = true
        F2T_COMPONENT_CAPTURE.active = true
        F2T_COMPONENT_CAPTURE.expecting = false
    elseif F2T_COMPONENT_CAPTURE.active and line:match("^%s+.+") then
        -- This line matches our expected format
        is_output_line = true
        -- Store data
    end

    -- ONLY delete if we confirmed this is our output
    if is_output_line then
        deleteLine()  -- ✅ CORRECT: Only deletes confirmed lines
    end
end
```

**Key Principles:**

1. **Two-Phase State:** Use `expecting` (waiting) and `active` (confirmed) flags
2. **Content Validation:** Always validate line format before deleting
3. **Specific Patterns:** Match your specific output format (headers, indentation, etc.)
4. **False Positives:** Better to miss a line than delete someone else's output

**When Pattern 2 Fails:**

Pattern 2 (Timer-Based Capture) assumes your output arrives immediately and exclusively. It fails when:
- Output is delayed by server processing
- Output interleaves with speedwalk commands
- Other game events happen during capture
- Multiple systems are capturing simultaneously

In these cases, you MUST implement content-based validation like shown above.

**Real Example (from map jump):**
```lua
-- Only delete lines that match jump output format:
-- - "Inter-Cartel destinations available:" or "Local destinations available:"
-- - Lines starting with whitespace (destination names)
-- - Empty lines (when already in output section)
if line:find("^Inter%-Cartel destinations available:") or
   line:find("^Local destinations available:") or
   (F2T_MAP_JUMP_CAPTURE.in_output and line:match("^%s+.+")) or
   (F2T_MAP_JUMP_CAPTURE.in_output and line == "") then
    deleteLine()  -- Safe: we confirmed this is jump output
else
    -- Not our output, let it display normally
end
```

---

## Component Initialization

### Minimal init.lua Pattern

```lua
-- File: src/component/scripts/init.lua
-- Initialize component

-- Create settings namespace
f2t_settings = f2t_settings or {}
f2t_settings.component = f2t_settings.component or {}

-- Load saved settings with defaults
COMPONENT_ENABLED = f2t_settings.component.enabled or false
COMPONENT_VALUE = f2t_settings.component.value or "default"

-- Initialize global state
F2T_COMPONENT_ACTIVE = false
F2T_COMPONENT_DATA = {}

-- Initialization message
if F2T_DEBUG then
    cecho("<green>[component]<reset> Initialized\n")
end
```

---

## GMCP Data Access

### Safe GMCP Access Pattern

```lua
-- ✅ CORRECT: Check for existence
local fuel = gmcp.char and gmcp.char.ship and gmcp.char.ship.fuel
if not fuel or not fuel.cur or not fuel.max then
    cecho("\n<red>[component]<reset> Error: Fuel data not available\n")
    return
end

local current = fuel.cur
local max = fuel.max
local percent = math.floor((current / max) * 100)
```

### GMCP as Authoritative Source

```lua
-- ✅ CORRECT: GMCP first, fallback to stored data
local system = gmcp.room and gmcp.room.info and gmcp.room.info.system
if not system then
    system = getRoomUserData(room_id, "fed2_system")
end

-- ❌ INCORRECT: Using stored data when GMCP is available
local system = getRoomUserData(room_id, "fed2_system")
```

### Common GMCP Paths

```lua
-- Room information
local room_flags = gmcp.room.info.flags           -- Array
local system = gmcp.room.info.system              -- String
local area = gmcp.room.info.area                  -- String
local room_num = gmcp.room.info.num               -- Number

-- Ship information
local fuel_cur = gmcp.char.ship.fuel.cur          -- Number
local fuel_max = gmcp.char.ship.fuel.max          -- Number
local hold_cur = gmcp.char.ship.hold.cur          -- AVAILABLE space (not used!)
local hold_max = gmcp.char.ship.hold.max          -- Number
local cargo = gmcp.char.ship.cargo                -- Array of lots

-- Check room flags
if has_value(gmcp.room.info.flags, "shuttlepad") then
    -- At a shuttlepad
end
```

---

## Dual-Mode Command Pattern

**CRITICAL CONVENTION:** Components may be used both by users AND by other components. Commands must support both modes.

### Why This Matters

Components build on each other:
- Hauling uses bulk-buy/sell
- Price checking uses commodity lookup
- Navigation uses mapping

These need to work **silently** when called programmatically, but show **helpful output** when users run them directly.

### Two Modes

**User Mode** (interactive):
- Pretty formatted output, tables, colors
- Confirmation messages, progress updates
- Error messages with helpful hints
- Sensible defaults

**Programmatic Mode** (API):
- Silent operation (no cecho/echo)
- Callbacks with raw data
- Status codes/error returns
- GMCP event monitoring

### Implementation Pattern

**Use optional callback parameter to distinguish modes:**

```lua
-- File: src/component/scripts/component_action.lua

-- Public API function
function f2t_component_action(arg1, arg2, callback)
    -- Set up state
    F2T_COMPONENT_STATE.active = true
    F2T_COMPONENT_STATE.callback = callback  -- nil = user mode, function = programmatic mode

    -- Only show user feedback if no callback
    if not callback then
        cecho("\n<green>[component]<reset> Starting operation...\n")
    end

    f2t_debug_log("[component] Action started: arg1=%s, arg2=%s, mode=%s",
        tostring(arg1), tostring(arg2), callback and "programmatic" or "user")

    -- Perform action
    send("game command")
end

-- Internal completion function
function f2t_component_finish()
    local results = process_results()

    -- User mode: show formatted output
    if not F2T_COMPONENT_STATE.callback then
        cecho(string.format("\n<green>[component]<reset> Complete: %d items\n", results.count))
        f2t_render_table(results.table_data)

    -- Programmatic mode: call callback with data
    else
        F2T_COMPONENT_STATE.callback(results.data, results.count, results.status)
    end

    -- Reset state
    F2T_COMPONENT_STATE.active = false
    F2T_COMPONENT_STATE.callback = nil
end
```

### Real Examples

**Commodities (price command):**
```lua
-- User mode
price alloys           -- Shows formatted table with colors

-- Programmatic mode
f2t_price_check_commodity("alloys", function(commodity, data, analysis)
    -- Callback receives parsed data, no output shown
    local best_buy = analysis.top_buy[1]
    navigate_to(best_buy.planet)
end)
```

**Bulk Buy/Sell:**
```lua
-- User mode
bb alloys 5            -- Shows "Buying..." messages, final count

-- Programmatic mode (hauling component)
f2t_bulk_buy_start("alloys", 5, function(commodity, lots_bought, status)
    -- Silent operation, callback when complete
    if status == "success" then
        navigate_to_sell_location()
    end
end)
```

### Callback Signature Guidelines

**Be consistent with callback parameters:**

```lua
-- ✅ GOOD: Meaningful parameter order
callback(primary_data, count, status, error_message)
callback(commodity_name, lots_bought, "success")
callback(destination, path_found, "failed", "No path exists")

-- ❌ BAD: Inconsistent or unclear parameters
callback(status, data)  -- Status should be last
callback(true, data, 5)  -- Use status strings, not booleans
```

### State Management

**Store callback in component state:**

```lua
-- In init.lua
F2T_COMPONENT_STATE = {
    active = false,
    callback = nil,  -- Stores callback function
    data = {}
}

-- In action function
function f2t_component_start(arg, callback)
    F2T_COMPONENT_STATE.callback = callback
    -- ... rest of logic
end

-- In completion function
function f2t_component_finish()
    if F2T_COMPONENT_STATE.callback then
        F2T_COMPONENT_STATE.callback(data, count, status)
    end
    F2T_COMPONENT_STATE.callback = nil
end
```

### GMCP Event Monitoring

**Use GMCP events to detect async changes:**

```lua
-- Register GMCP event handler for cargo changes
registerAnonymousEventHandler("gmcp.char.ship.cargo", function()
    if F2T_BULK_STATE.active and F2T_BULK_STATE.callback then
        -- Cargo changed - check if operation complete
        check_operation_status()
    end
end)
```

### Key Principles

1. **Callback presence determines mode**: `nil` = user, `function` = programmatic
2. **Never show output in programmatic mode**: Check `if not callback` before cecho
3. **Always provide data to callback**: Include all relevant info (counts, status, error messages)
4. **Use consistent callback signatures**: Primary data first, status last
5. **Monitor GMCP for async changes**: React to ship hold, cargo, fuel changes
6. **Debug log both modes**: Always log operations regardless of mode

### Benefits

- **Composability**: Components can build on each other
- **Testability**: Programmatic mode easier to test
- **User Experience**: Interactive use shows helpful output
- **Flexibility**: Same command works both ways
- **Maintainability**: One implementation for both modes

---

## Debug Logging

### Using f2t_debug_log()

```lua
-- Variadic arguments (preferred)
f2t_debug_log("[component] Processing %d items", count)
f2t_debug_log("[component] User %s has %d gold", name, gold)
f2t_debug_log("[component] State: %s, threshold: %d%%", state, threshold)

-- Simple messages
f2t_debug_log("[component] Starting initialization")
f2t_debug_log("[component] Operation complete")

-- Error conditions
if not data then
    f2t_debug_log("[component] ERROR: Data not available")
    return
end
```

### When to Log

```lua
-- ✅ Log these:
f2t_debug_log("[component] Initialized: enabled=%s", tostring(enabled))
f2t_debug_log("[component] State changed: %s -> %s", old_state, new_state)
f2t_debug_log("[component] Starting operation with %d items", count)
f2t_debug_log("[component] Operation complete: %d processed", success)
f2t_debug_log("[component] ERROR: Invalid input: %s", tostring(input))

-- ❌ Don't log these:
-- Every loop iteration
-- Trivial variable assignments
-- Redundant information
```

---

## Table Rendering

### Basic Table

```lua
f2t_render_table({
    title = "Table Title",
    columns = {
        {header = "Name", field = "name"},
        {header = "Value", field = "value", align = "right"}
    },
    data = {
        {name = "Item 1", value = 100},
        {name = "Item 2", value = 200}
    }
})
```

### Advanced Table with Formatting

```lua
f2t_render_table({
    title = "Factory Status",
    max_width = 100,
    columns = {
        {header = "#", field = "number", align = "right", width = 2},
        {header = "Location", field = "location", max_width = 15, truncate = true},
        {
            header = "Status",
            field = "status",
            width = 7,
            color_fn = function(val)
                return val == "Running" and "green" or "yellow"
            end
        },
        {
            header = "P/L",
            field = "profit",
            align = "right",
            format = "compact",
            color_fn = function(val)
                return val >= 0 and "green" or "red"
            end
        }
    },
    data = factories,
    footer = {
        aggregations = {
            {field = "profit", method = "sum",
             color_fn = function(val) return val >= 0 and "green" or "red" end}
        }
    }
})
```

### Built-in Formatters

```lua
-- Formatters
format = "string"    -- Convert to string (default)
format = "number"    -- Floor to integer
format = "compact"   -- 1000 → 1K, 1500000 → 1.50M
format = "percent"   -- 0.75 → 75%
format = "boolean"   -- true → Y, false → N

-- Aggregation methods
method = "sum"       -- Total
method = "avg"       -- Average
method = "min"       -- Minimum
method = "max"       -- Maximum
method = "count"     -- Count of non-nil values
```

---

## Message Formatting

### All messages start with \n

```lua
-- ✅ CORRECT
cecho("\n<green>[component]<reset> Message here\n")
cecho(string.format("\n<green>[component]<reset> Value: %d\n", value))

-- ❌ INCORRECT: Missing leading newline
cecho("<green>[component]<reset> Message here\n")
```

### Color Echo Examples

```lua
-- Success message
cecho("\n<green>[component]<reset> Operation successful\n")

-- Error message
cecho("\n<red>[component]<reset> Error: Something went wrong\n")

-- Warning message
cecho("\n<yellow>[component]<reset> Warning: Check your settings\n")

-- Info message
cecho("\n<cyan>[component]<reset> Processing data...\n")

-- With formatted values
cecho(string.format("\n<green>[component]<reset> Threshold set to <yellow>%d%%<reset>\n", percent))
```

---

## Event-Driven State Machine Pattern

**Use for:** Multi-phase workflows with unpredictable timing, complex automation sequences

**Pattern:** Create triggers dynamically using `tempRegexTrigger()`, kill them when done, couple lifecycle to state

**Examples:** Circuit travel (`nav circuit red`), train/tube navigation (future)

### When to Use This Pattern

✅ Multi-phase workflows (boarding → traveling → arrival)
✅ Unpredictable timing (may wait seconds or minutes)
✅ Dynamic patterns that vary per invocation
✅ Runs infrequently (creation overhead doesn't matter)
✅ Complex state transitions with cleanup requirements

❌ **Don't use for:** Data capture (use permanent triggers), frequent operations, simple state tracking

### Complete Example (Circuit Travel)

**State object:**

```lua
-- File: src/component/scripts/init.lua
F2T_CIRCUIT_STATE = {
    active = false,
    phase = nil,  -- "waiting_boarding", "waiting_arrival"

    -- Workflow data
    destination_stop = nil,
    destination_room = nil,
    exit_command = nil,

    -- Trigger IDs for cleanup
    boarding_trigger_id = nil,
    arrival_trigger_id = nil
}
```

**Start workflow:**

```lua
-- File: src/component/scripts/circuit.lua
function f2t_circuit_begin(stop_name)
    -- Initialize state
    F2T_CIRCUIT_STATE = {
        active = true,
        phase = "waiting_boarding",
        destination_stop = stop_name,
        destination_room = get_destination_room(stop_name),
        exit_command = "exit",
        boarding_trigger_id = nil,
        arrival_trigger_id = nil
    }

    -- Create first trigger only
    f2t_circuit_create_boarding_trigger()

    f2t_debug_log("[circuit] Waiting for boarding announcement")
end

function f2t_circuit_create_boarding_trigger()
    local pattern = "^The .+ announces its arrival"

    F2T_CIRCUIT_STATE.boarding_trigger_id = tempRegexTrigger(
        pattern,
        function()
            f2t_circuit_handle_boarding()
        end
    )

    f2t_debug_log("[circuit] Created boarding trigger")
end
```

**Phase 1 handler (boarding):**

```lua
function f2t_circuit_handle_boarding()
    -- Guard #1: Check active
    if not F2T_CIRCUIT_STATE.active then
        return
    end

    -- Guard #2: Check phase
    if F2T_CIRCUIT_STATE.phase ~= "waiting_boarding" then
        return
    end

    f2t_debug_log("[circuit] Boarding trigger fired")

    -- Kill boarding trigger immediately
    if F2T_CIRCUIT_STATE.boarding_trigger_id then
        killTrigger(F2T_CIRCUIT_STATE.boarding_trigger_id)
        F2T_CIRCUIT_STATE.boarding_trigger_id = nil
    end

    -- Board the vehicle
    send("board")

    -- Change phase
    F2T_CIRCUIT_STATE.phase = "waiting_arrival"

    -- Create arrival trigger after delay (avoid race conditions)
    tempTimer(0.5, function()
        if F2T_CIRCUIT_STATE.active and F2T_CIRCUIT_STATE.phase == "waiting_arrival" then
            f2t_circuit_create_arrival_trigger()
        end
    end)
end

function f2t_circuit_create_arrival_trigger()
    local pattern = string.format("^The .+ has arrived at %s", F2T_CIRCUIT_STATE.destination_stop)

    F2T_CIRCUIT_STATE.arrival_trigger_id = tempRegexTrigger(
        pattern,
        function()
            f2t_circuit_handle_arrival()
        end
    )

    f2t_debug_log("[circuit] Created arrival trigger for: %s", F2T_CIRCUIT_STATE.destination_stop)
end
```

**Phase 2 handler (arrival):**

```lua
function f2t_circuit_handle_arrival()
    -- Guard checks
    if not F2T_CIRCUIT_STATE.active then return end
    if F2T_CIRCUIT_STATE.phase ~= "waiting_arrival" then return end

    f2t_debug_log("[circuit] Arrival trigger fired")

    -- Kill arrival trigger immediately
    if F2T_CIRCUIT_STATE.arrival_trigger_id then
        killTrigger(F2T_CIRCUIT_STATE.arrival_trigger_id)
        F2T_CIRCUIT_STATE.arrival_trigger_id = nil
    end

    -- Exit vehicle
    send(F2T_CIRCUIT_STATE.exit_command)

    -- Verify arrival after delay
    tempTimer(0.5, function()
        if F2T_CIRCUIT_STATE.active then
            f2t_circuit_verify_and_complete()
        end
    end)
end
```

**Completion and cleanup:**

```lua
function f2t_circuit_verify_and_complete()
    local current_room = get_current_room_id()
    local expected_room = F2T_CIRCUIT_STATE.destination_room

    if current_room == expected_room then
        -- Success
        cecho(string.format("\n<green>[circuit]<reset> Arrived at %s\n",
            F2T_CIRCUIT_STATE.destination_stop))
        f2t_circuit_cleanup()
        resume_speedwalk()
    else
        -- Error
        cecho(string.format("\n<red>[circuit]<reset> Error: Expected room %d, at room %d\n",
            expected_room, current_room))
        f2t_circuit_cleanup()
        stop_speedwalk()
    end
end

function f2t_circuit_cleanup()
    -- Kill all triggers
    if F2T_CIRCUIT_STATE.boarding_trigger_id then
        killTrigger(F2T_CIRCUIT_STATE.boarding_trigger_id)
        F2T_CIRCUIT_STATE.boarding_trigger_id = nil
    end
    if F2T_CIRCUIT_STATE.arrival_trigger_id then
        killTrigger(F2T_CIRCUIT_STATE.arrival_trigger_id)
        F2T_CIRCUIT_STATE.arrival_trigger_id = nil
    end

    -- Reset state
    F2T_CIRCUIT_STATE = {active = false}

    f2t_debug_log("[circuit] Cleanup complete")
end

function f2t_circuit_stop()
    if not F2T_CIRCUIT_STATE.active then
        cecho("\n<yellow>[circuit]<reset> No active circuit travel\n")
        return
    end

    cecho("\n<yellow>[circuit]<reset> Circuit travel stopped\n")
    f2t_circuit_cleanup()
end
```

### Key Principles

**1. Progressive Trigger Creation**

Don't create all triggers at start. Create them as needed, phase by phase:

```lua
-- ✅ CORRECT: Create arrival trigger AFTER boarding
tempTimer(0.5, function()
    if STATE.active and STATE.phase == "waiting_arrival" then
        create_arrival_trigger()
    end
end)

-- ❌ WRONG: Create both triggers at start
create_boarding_trigger()
create_arrival_trigger()  -- May fire too early!
```

**2. Immediate Trigger Cleanup**

Kill triggers as soon as they fire (don't wait for workflow completion):

```lua
-- ✅ CORRECT
function handle_event()
    if STATE.trigger_id then
        killTrigger(STATE.trigger_id)  -- Kill immediately
        STATE.trigger_id = nil
    end
    do_work()
end

-- ❌ WRONG: Trigger stays alive until complete
function handle_event()
    do_work()
    // Trigger cleanup happens later in cleanup() function
end
```

**3. State-Driven Guards**

Every handler checks state before doing anything:

```lua
function handle_event()
    if not STATE.active then return end           // Master switch
    if STATE.phase ~= "expected_phase" then return end  // Phase check
    // Safe to proceed
end
```

**4. Cleanup on ALL Exit Paths**

Success, error, manual stop - all must cleanup:

```lua
function complete() { cleanup(); continue_workflow(); }
function error() { cleanup(); abort_workflow(); }
function stop() { cleanup(); show_message(); }
```

**5. Store Trigger/Timer IDs**

Must store IDs to kill them later:

```lua
STATE.trigger_id = tempRegexTrigger(pattern, handler)
STATE.timer_id = tempTimer(delay, handler)

// Later:
if STATE.trigger_id then killTrigger(STATE.trigger_id) end
if STATE.timer_id then killTimer(STATE.timer_id) end
```

**6. Use tempTimer for Delays**

Non-blocking delays with state checks:

```lua
tempTimer(0.5, function()
    if STATE.active then  // Always check state
        do_action()
    end
end)
```

### Pattern Decision Flowchart

```
Do you need to capture multi-line command output?
├─ YES → Use Permanent Triggers (Pattern 1 or 2)
│         • factory status, price alloys, work listings
│
└─ NO → Is this a multi-phase workflow with unpredictable timing?
    ├─ YES → Use Event-Driven State Machine (tempRegexTrigger)
    │         • circuit travel, train navigation, complex automation
    │
    └─ NO → Is this tracking a single GMCP event?
        ├─ YES → Use GMCP Event Handler
        │         • room change, cargo change, fuel change
        │
        └─ NO → Simple trigger or script function
```

### Benefits vs. Trade-offs

**Benefits:**
- ✅ Zero interference when inactive (triggers don't exist)
- ✅ Lifecycle safety (trigger dies with workflow)
- ✅ Dynamic patterns (can vary per invocation)
- ✅ State isolation (no global pollution)
- ✅ Memory efficient (resources freed)

**Trade-offs:**
- ❌ More complex code (ID tracking, cleanup)
- ❌ Harder to debug (triggers not visible when inactive)
- ❌ Creation overhead (not for frequent operations)
- ❌ More boilerplate (guards, cleanup, state management)

**When to Use:** Infrequent, complex workflows where safety and isolation outweigh complexity.

**Reference:** See `src/map/scripts/map_circuit.lua` for complete working implementation.

---

## Common Pitfalls and Lessons Learned

### Mudlet Line Break Handling

**Problem:** Trying to match text that spans line breaks with a single regex pattern.

**What Doesn't Work:**
```lua
-- ❌ WRONG: Trying to match across lines with regex
-- @pattern: your fee of\s+([\d,]+)ig has been transferred
-- Even with multiline flag, this CANNOT match if text wraps:
-- Line 1: "and your fee of 900ig"
-- Line 2: "has been transferred to your account."
```

**Why:** Mudlet processes game output line-by-line. Individual regex patterns only see one line at a time, regardless of trigger settings.

**What `isMultiline` Actually Does:**
- Enables AND trigger mode (multiple patterns must all match within N lines)
- Does NOT enable cross-line regex matching like in text editors
- Does NOT make `.` match newlines
- Does NOT let `\s+` match line breaks

**Solution - Fully Decouple Pattern Parts:**
```lua
-- ✅ CORRECT: Two independent triggers
-- Trigger 1: Capture number
-- @pattern: ([\d,]+)ig
if STATE.active and STATE.phase == "delivering" then
    STATE.payment_amount = tonumber(matches[2]:gsub(",", ""))
end

-- Trigger 2: Confirm transaction
-- @pattern: has been transferred to your account
if STATE.active and STATE.phase == "delivering" and STATE.payment_amount then
    process_payment(STATE.payment_amount)
end
```

**Key Insight:** Don't assume where line breaks will occur. The game may wrap at ANY position based on line length.

### Debugging Line Break Issues

**When text matching fails unexpectedly:**

1. **Enable debug logging to see actual output:**
   ```lua
   if F2T_DEBUG then
       cecho(string.format("\n<yellow>[debug]<reset> Line: '%s'\n", line))
   end
   ```

2. **Check for hidden characters:**
   - Line breaks (`\n`)
   - Carriage returns (`\r`)
   - Extra spaces

3. **Test with different message lengths:**
   - Short messages may not wrap
   - Long messages wrap at different positions
   - Wrapping behavior may change with terminal width

4. **Don't rely on specific wrap positions:**
   ```lua
   -- ❌ BAD: Assumes amount is on first line
   -- @pattern: your fee of ([\d,]+)ig$

   -- ✅ GOOD: Captures amount regardless of position
   -- @pattern: ([\d,]+)ig
   ```

### Progressive Refinement Approach

**Real-world debugging example from AC delivery trigger:**

1. **Initial attempt:** Pattern tried to match entire message on one line
   - Failed when text wrapped

2. **Second attempt:** Added multiline flag thinking it would help
   - Still failed - discovered multiline doesn't enable cross-line matching

3. **Third attempt:** Used text accumulation with expectation flag
   - Better, but still assumed "900ig has been transferred" on same line
   - Failed when break occurred between number and text

4. **Final solution:** Fully decoupled the two parts
   - Trigger 1: Captures ANY `([\d,]+)ig` during delivery phase
   - Trigger 2: Confirms with substring `has been transferred`
   - Works regardless of where line breaks occur

**Lesson:** When text matching fails, progressively simplify and decouple until each pattern matches independently.

### State-Based Matching vs. Pattern-Based Matching

**Problem:** Relying only on pattern matching to determine which lines to process.

**Better Approach:** Use state/phase context to filter lines:

```lua
-- ❌ FRAGILE: Relies on complex pattern to avoid false matches
-- @pattern: ^.*your fee of ([\d,]+)ig.*$

-- ✅ ROBUST: Simple pattern + state context
-- @pattern: ([\d,]+)ig
if not (STATE.active and STATE.phase == "delivering") then
    return  -- Not in delivery phase, ignore this line
end
if STATE.payment_amount then
    return  -- Already captured payment
end
STATE.payment_amount = tonumber(matches[2]:gsub(",", ""))
```

**Benefits:**
- Simpler patterns (less error-prone)
- Avoids false positives from unrelated game output
- Clear separation of concerns (pattern matching vs. business logic)
- Easier to debug (can log why lines were skipped)

### When to Use Each Pattern

**Use Pattern 1 (Explicit End)** when:
- ✅ Output has clear start and end markers
- ✅ Ends with game prompt
- ✅ Format is well-known and stable

**Use Pattern 2 (Timer-Based)** when:
- ✅ Variable-length output
- ✅ No explicit end marker
- ✅ Unknown/complex format
- ✅ Don't want to write specific patterns for every line

**Use Pattern 3 (Text Accumulation)** when:
- ✅ 2-part message that might wrap
- ✅ Line breaks can occur anywhere
- ✅ Single value to capture
- ✅ Simpler than timer-based for this use case

**Use Event-Driven State Machine** when:
- ✅ Multi-phase workflow
- ✅ Unpredictable timing (waiting for events)
- ✅ Complex state transitions
- ✅ Need lifecycle management

**Wrong Pattern Choice Example:**
```lua
// Using Pattern 2 (timer-based) for simple 2-line wrap:
// - Overkill complexity
// - 0.5s delay before processing
// - Requires timer management

// Should use Pattern 3 (text accumulation):
// - Immediate processing
// - Simpler code
// - Two focused triggers
```

---

## Quick Reference Links

- **Full Conventions:** [CLAUDE.md](CLAUDE.md)
- **Shared APIs:** [src/shared/CLAUDE.md](src/shared/CLAUDE.md)
- **Documentation Index:** [CLAUDE_INDEX.md](CLAUDE_INDEX.md)
