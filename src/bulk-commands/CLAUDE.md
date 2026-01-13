# bulk-commands

Provides bulk buy and sell commands for commodity trading at exchanges.

## Usage

- `bb <commodity>` - Buy until hold is full
- `bb <commodity> <count>` - Buy specific number of lots
- `bs` - Sell all cargo (all commodities)
- `bs <commodity>` - Sell all of specific commodity
- `bs <commodity> <count>` - Sell specific number of lots

## How it works

1. Verifies you're in a commodity exchange (checks for "exchange" room flag)
2. For bulk buy: Calculates available hold space (`gmcp.char.ship.hold.cur / 75`) and buys up to that limit
3. For bulk sell:
   - If no commodity specified: Gets all unique commodities from cargo and sells them sequentially
   - If commodity specified: Counts lots of that commodity and sells them
   - Uses case-insensitive matching for commodity names
   - **Margin reporting**: Extracts cost data from `gmcp.char.ship.cargo` and price data from sell success messages to calculate and display profit margins
4. Uses triggers to detect success/error messages from the game
5. Automatically stops on errors or when limits are reached

## Margin Reporting (Bulk Sell)

The bulk sell command tracks costs, revenue, and profit margins when selling commodities.

**Data Sources:**
- **Cost**: Extracted from `gmcp.char.ship.cargo` table (each cargo item has a `cost` field)
- **Revenue**: Captured from game's sell success message: "75 tons of X sold to the exchange for Yig"

**Displayed Information:**
- Total cost (sum of all `cost` fields for sold commodity)
- Total revenue (sum of all sale prices)
- Average cost per ton and revenue per ton
- Total profit (revenue - cost)
- Profit margin percentage: `(profit / cost) * 100`

**Color Coding:**
- Profit: Green (≥0) or Red (<0)
- Margin: Green (≥40%), Yellow (≥20%), White (>0%), Red (<0%)

**Example Output:**
```
Complete: Sold 5 lots of alloys (375 tons)
  Cost: 45000 ig (120 ig/ton) | Revenue: 56250 ig (150 ig/ton)
  Profit: 11250 ig | Margin: 25.0%
```

## Implementation Pattern

- **State machine**: Uses `F2T_BULK_STATE` global to track active operations
- **Trigger-driven**: Success/error triggers advance or stop the bulk operation
- **GMCP integration**:
  - Buy: Reads `gmcp.char.ship.hold.cur` (available space) to calculate capacity
  - Sell: Counts lots in `gmcp.char.ship.cargo` table (each entry = 1 lot of 75 tons)
- **Sequential commands**: Sends one command at a time, waits for response
- **Commodity queue**: When selling all cargo, maintains a queue of commodities and processes them sequentially
- **Capacity calculation**:
  - Buy: `maxLots = floor(availableSpace / 75)` where availableSpace = `gmcp.char.ship.hold.cur`
  - Sell: Count entries in `gmcp.char.ship.cargo` matching commodity name (case-insensitive)

## Key Files

- `init.lua` (script) - Initialize state tracking
- `bulk_buy.lua` (script) - Bulk buy logic and functions
- `bulk_sell.lua` (script) - Bulk sell logic and functions
- `buy_success.lua` (trigger) - Detect successful purchase
- `buy_error_*.lua` (triggers) - Detect buy errors
- `sell_success.lua` (trigger) - Detect successful sale
- `sell_error_*.lua` (triggers) - Detect sell errors
- `bb.lua` (alias) - Bulk buy command
- `bs.lua` (alias) - Bulk sell command

## Important Notes

- Commodities are traded in 75 ton lots. The system automatically accounts for this when calculating hold capacity.
- All messages start with a newline to avoid line break issues with game output
