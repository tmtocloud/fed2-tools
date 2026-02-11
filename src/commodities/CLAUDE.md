# Commodities Component

Commodity trading tools for Federation 2: price analysis via the cartel broker system, and bulk buy/sell commands for exchanges.

## Features

- Check prices for individual commodities across all exchanges
- Analyze all commodities to find most profitable opportunities
- Display top buy/sell locations with price data
- Calculate projected profits per ton and per 75-ton lot
- Configurable number of results
- Bulk buy commodities to fill cargo hold
- Bulk sell cargo (all or specific commodity)
- Margin reporting on bulk sell (cost, revenue, profit)

## Commands

### Check Single Commodity

```
price <commodity>    # Full command
pr <commodity>       # Shorthand
```

Shows top exchanges (default: 5) to buy/sell, including:
- Location (System: Planet)
- Price per ton
- Quantity available (color-coded: green ≥15K tons, yellow 5-15K, white <5K)
- Average prices and projected profit

**Examples:** `price alloys`, `pr cereals`, `price nanofabrics`

### Analyze All Commodities

```
price all
pr all
```

Checks all 64 commodities sequentially (0.5s delay each, ~30-40s total). Displays summary table sorted by profitability:
- Commodity name
- Average buy price (where you buy from exchanges)
- Average sell price (where you sell to exchanges)
- Profit per ton
- Profit per 75-ton lot

### Bulk Buy

```
bb <commodity>           # Buy until cargo full
bb <commodity> <count>   # Buy specific number of lots
```

Verifies exchange location, calculates available hold space, sends sequential buy commands.

### Bulk Sell

```
bs                       # Sell all cargo (all commodities)
bs <commodity>           # Sell all of specific commodity
bs <commodity> <count>   # Sell specific number of lots
```

Sells sequentially. When selling all cargo, queues each unique commodity. Reports margin (cost vs revenue) on completion.

### Settings

```
price settings                         # List all
price settings get <name>              # Get specific
price settings set <name> <value>      # Set value
price settings clear <name>            # Reset to default
```

**Available:**
- `results_count` (number, 1-20, default: 5) - Top exchanges shown in tables

**Examples:**
```
price settings set results_count 10    # Show top 10
price settings clear results_count     # Reset to 5
```

## How It Works

### Game Integration

Uses Fed2 cartel broker command: `check price <commodity> cartel`

**Requirements:** Merchant rank or higher, `remote-access-cert` tool, access to any exchange

Both prerequisites are checked proactively before sending the game command.

### Price Capture Flow

1. User runs `price <commodity>`
2. Send game command: `check price <commodity> cartel`
3. Detect output start: "Your comm unit lights up..."
4. Capture price lines via regex trigger
5. Detect output end: Next game prompt
6. Parse, analyze, display results

### Data Processing

**Parsing** (`price_parser.lua`):
- Extract system, planet, action, quantity, price
- Separate buy/sell exchanges
- Sort by optimal prices

**Analysis** (`price_analyzer.lua`):
- Get top N exchanges (configurable)
- Calculate averages
- Compute profit margins

**Display** (`price_display.lua`):
- Uses `f2t_render_table()` for formatting
- Color-codes quantities and profits

### Price All Operation

1. Load commodity list from `shared/resources/commodities.json`
2. Iterate all 64 commodities (0.5s delay between)
3. Use callback system to collect results without individual displays
4. Display comprehensive summary when complete

**State Management:** `price_all_state` tracks progress, prevents concurrent operations

### Bulk Buy/Sell

- **State machine**: Uses `F2T_BULK_STATE` global to track active operations
- **Trigger-driven**: Success/error triggers advance or stop the bulk operation
- **Sequential commands**: Sends one command at a time, waits for response
- **GMCP integration**:
  - Buy: Reads `gmcp.char.ship.hold.cur` (available space) to calculate capacity
  - Sell: Counts lots in `gmcp.char.ship.cargo` table (each entry = 1 lot of 75 tons)
- **Commodity queue**: When selling all cargo, maintains a queue of commodities and processes them sequentially
- **Margin reporting**: Extracts cost from `gmcp.char.ship.cargo` and revenue from sell success trigger to calculate profit margins

**Margin Color Coding:**
- Profit: Green (>=0) or Red (<0)
- Margin: Green (>=40%), Yellow (>=20%), White (>0%), Red (<0%)

## Key Files

**Scripts:**
- `init.lua` - Initialization, settings/help registration, bulk state setup
- `price_control.lua` - Main control functions
- `price_parser.lua` - Parse game output
- `price_analyzer.lua` - Analyze data, calculate profitability
- `price_display.lua` - Display formatted tables
- `price_all.lua` - "Price all" functionality
- `bulk_buy.lua` - Bulk buy logic and functions
- `bulk_sell.lua` - Bulk sell logic and functions

**Triggers:**
- `price_output_start.lua` - Detect output start
- `price_output_continuation.lua` - Detect multi-page continuation
- `price_capture.lua` - Capture price lines
- `buy_success.lua` - Detect successful purchase
- `buy_error_*.lua` - Detect buy errors (insufficient funds, invalid, not selling)
- `sell_success.lua` - Detect successful sale
- `sell_error_*.lua` - Detect sell errors (invalid, no cargo, not buying)

**Aliases:**
- `price.lua` - Consolidated price alias (all subcommands)
- `bb.lua` - Bulk buy command
- `bs.lua` - Bulk sell command

## Public API

### User-Facing

**`f2t_price_show(commodity)`**
Check and display prices for single commodity.

**`f2t_price_show_all()`**
Check and display prices for all commodities.

### Bulk Buy/Sell

**`f2t_bulk_buy_start(commodity, requested_lots, callback)`**
Start a bulk buy operation. Optional callback for programmatic mode.

**`f2t_bulk_sell_start(commodity, requested_lots, callback)`**
Start a bulk sell operation. Pass `nil` commodity to sell all cargo.

### Programmatic

**`f2t_price_check_commodity(commodity, callback)`**
Get price data with optional callback.
- `callback` - Optional `function(commodity, parsed_data, analysis)`
- If no callback, displays table automatically

**`f2t_price_get_all_data(callback)`**
Get all commodity data programmatically (no display).
- `callback` - `function(results)` array when complete
- Returns `true` if started, `false` if already in progress

```lua
f2t_price_get_all_data(function(results)
    for _, analysis in ipairs(results) do
        print(analysis.commodity, analysis.profit)
    end
end)
```

### Display

**`f2t_price_display_commodity(commodity, analysis)`**
Display formatted table for single commodity.

**`f2t_price_display_all(all_analysis)`**
Display summary table (auto-sorted by profit).

### Data Processing

**`f2t_price_parse_data(raw_lines)`**
Parse captured lines → `{buy = {}, sell = {}}`

**`f2t_price_get_top_exchanges(parsed_data, count)`**
Get top N exchanges (respects `results_count` setting).

**`f2t_price_calculate_average(exchanges)`**
Calculate average price.

**`f2t_price_analyze_commodity(commodity, parsed_data)`**
Analyze commodity → `{commodity, top_buy, top_sell, avg_buy_price, avg_sell_price, profit}`

## Trading Tips

**Understanding:**
- **Buying** (You → Exchange): Look for exchanges selling at LOW prices
- **Selling** (Exchange → You): Look for exchanges buying at HIGH prices
- **Quantity**: Green (≥15K tons) = stable pricing for bulk purchases

**Using Data:**
1. **Single Commodity**: Specific buy/sell locations for focused trading
2. **Price All**: Identifies currently most profitable commodities
3. **Profit Calculation**: `profit = avg_sell_price - avg_buy_price` (where exchanges buy from you at sell_price)

## Error Handling

**"You need to be at least a merchant to use the exchange!"**
- Need merchant rank to use `check price` command

**"not currently trading in this commodity"**
- Normal - not all exchanges trade all commodities
- Component filters these out automatically

## Settings Storage

All settings in `f2t_settings.commodities`:

```lua
f2t_settings.commodities = {
    results_count = 5
}
```

Persisted via `f2t_save_settings()`, auto-loaded on startup.

## Debug Logging

```
f2t debug on
```

Output includes:
- Component initialization
- Price capture start/end
- Lines captured count
- Commodity processing during "price all"
- Parser/analyzer activity
- Bulk buy/sell operations and state changes
- Margin calculations

## Future Enhancements

- Route planning (buy from X, sell to Y)
- Historical price tracking
- Price alerts
- Filtering by system/region
