# po (Planet Owner)

Tools for managing planets in Federation 2.

## Usage

### Economy Command

```
po economy                    # Show economy for current planet (all commodities)
po economy <planet>           # Show economy for specific planet
po economy <group>            # Show current planet, filtered by commodity group
po economy <planet> <group>   # Show specific planet, filtered by group
```

**Short form:** `po econ` works in place of `po economy`.

**Commodity groups:** agricultural (agri), resource, industrial (ind), technological (tech), biological, leisure

### Settings

```
po settings                   # List all settings
```

## Requirements

**Rank:** Founder or above.

**Planet ownership:** You must own the planet's exchange. Non-owners receive an error message.

## How It Works

### Economy Command

1. Sends `display exchange [planet]` and captures the output
2. Sends `display production [group] [planet]` and captures the output (game requires group before planet name; defaults to `all`)
3. Merges both datasets with base prices from `commodities.json`
4. Displays a formatted table with columns: Commodity, Value, Diff (from base), Spread, Efficiency, Production, Consumption, Net, Stock, Min, Max

### Two-Phase Capture

The command uses sequential capture:
- **Phase 1 (Exchange):** Explicit end marker detection — the summary line (`"N commodities, ... total value"`) signals completion
- **Phase 2 (Production):** Timer-based completion — 0.5s of silence signals completion

### Exchange Output Wrapping

Exchange data wraps each commodity across two lines:
```
           Alloys: value 137ig/ton  Spread: 20%   Stock: current 800/min 100/max 800  Efficiency:
105%  Net: 44
```
The parser pairs consecutive lines for extraction.

### Reusable Capture Functions

Other tools can use the capture functions independently:

```lua
-- Capture exchange data only
f2t_po_capture_exchange(planet, function(exchange_data)
    -- exchange_data: array of {name, value, spread, stock_current, stock_min, stock_max, efficiency, net}
end)

-- Capture production data only (group defaults to "all" when planet specified)
f2t_po_capture_production(planet, function(production_data)
    -- production_data: table keyed by name {["Alloys"] = {production=45, consumption=1}, ...}
end, group)
```

Only one capture can run at a time.

## Key Files

### Alias
- `po.lua` — Consolidated alias with rank check, subcommand routing, argument parsing

### Scripts
- `init.lua` — State initialization and reset function
- `po_help_init.lua` — Help registration
- `po_commodity_groups.lua` — Group resolver and base price lookup from commodities.json
- `po_economy_capture.lua` — Capture control: start, timer, phase transitions, abort, economy orchestrator
- `po_economy_parser.lua` — Parse exchange (two-line) and production (single-line) output, merge with base prices
- `po_economy_formatter.lua` — Table display via `f2t_render_table()`

### Triggers
- `po_exchange_header.lua` — Detects `"exchange - all products:"` (exchange start)
- `po_exchange_summary.lua` — Detects `"N commodities,"` (exchange end)
- `po_production_header.lua` — Detects `"exchange - production and consumption:"` (production start)
- `po_capture_line.lua` — Captures commodity data lines (3 patterns: `: value `, `^\d+%\s+Net:`, `: production `)
- `po_error_not_owner.lua` — Detects ownership error, aborts capture
- `po_error_invalid_planet.lua` — Detects invalid planet name errors from exchange or production commands

## Data Structures

### Exchange Record (from parser)
```lua
{name, value, spread, stock_current, stock_min, stock_max, efficiency, net}
```

### Production Record (from parser)
```lua
{production, consumption}  -- keyed by commodity name
```

### Merged Economy Record
```lua
{name, value, diff, spread, efficiency, production, consumption, net,
 stock_current, stock_min, stock_max, base_price, group}
```
