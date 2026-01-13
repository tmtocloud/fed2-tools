# factory

Manages player factories: displays status in a table view and flushes production to market.

## Usage

### Status Command

```
factory status    # View all factories
fac status       # Shorthand
```

### Flush Command

```
factory flush     # Flush all factories
fac flush        # Shorthand
```

Sends production from all factories to market by issuing `flush factory N` for each factory sequentially.

### Settings

```
factory settings                              # List all settings
factory settings set auto_flush_before_reset true   # Enable auto-flush
factory settings get auto_flush_before_reset  # View specific setting
```

**Available Settings:**
- `auto_flush_before_reset` (boolean, default: false) - Automatically flush all factories 4 minutes before daily game reset

## Requirements

**Rank:** Only Industrialist or Manufacturer can use factory commands. Other ranks will see an error message.

## How it works

### Status Command

1. Determines max factory slots based on rank (Industrialist: 8, Manufacturer: 15)
2. Sends `display factory 1`, `display factory 2`, etc. sequentially up to max
3. Captures and hides game output using triggers with `deleteLine()`
4. Parses factory data (location, status, finances, workers, inputs, efficiency)
5. If a factory slot is empty (destroyed/never built), records it as missing and continues
6. Stops when all slots have been queried
7. Calculates additional metrics:
   - Efficiency percentage (current/max)
   - Workers percentage (hired/required)
   - Storage usage percentage
   - Income to Expense ratio (income/expenditure)
8. Displays all factory data in a formatted table (missing slots shown as "(No factory)")

### Flush Command

1. Determines max factory slots based on rank (Industrialist: 8, Manufacturer: 15)
2. Sends `flush factory 1`, `flush factory 2`, etc. sequentially up to max
3. Captures and hides success messages using triggers with `deleteLine()`
4. Tracks count of successfully flushed factories
5. If a factory slot is empty (destroyed/never built), skips it and continues
6. Stops when all slots have been attempted
7. Displays completion message with count

### Auto-Flush Before Reset

When `auto_flush_before_reset` setting is enabled:

1. Trigger detects game shutdown warning: "Federation II will be closing down for a short while in six minutes time."
2. Sets a 4-minute timer (leaving 2 minutes before shutdown)
3. When timer expires, automatically flushes all factories
4. Notifies user when scheduling and when executing the flush

## Implementation Pattern

### Status
- **Timer-based capture**: Uses `tempTimer()` to detect when factory output is complete (0.3s timeout after last line)
- **State machine**: Tracks `capturing` flag and current factory number
- **Buffer accumulation**: Stores all output lines in `capture_buffer` before parsing
- **Sequential queries**: Processes one factory at a time, then queries next

### Flush
- **Event-driven**: Triggers on success message to continue to next factory
- **State machine**: Tracks `flushing` flag and flush count
- **Sequential commands**: Sends one flush command at a time
- **Auto-stop**: Stops when error message received

## Metrics Explained

### Income to Expense Ratio (I/E)

The I/E ratio helps compare factory investment efficiency by showing how much income is generated per unit of expense:

- **> 1.0** (green): Profitable - factory generates more income than it spends
- **< 1.0** (red): Losing money - factory spends more than it generates
- **= 1.0** (yellow): Breaking even
- **-** (grey): No expenses yet (new factory or no data)

**Examples:**
- `I/E = 1.50`: For every 1ig spent, factory generates 1.50ig income (50% profit margin)
- `I/E = 0.80`: For every 1ig spent, factory only generates 0.80ig income (20% loss)

The footer shows the **average I/E ratio** across all factories, providing an overall investment efficiency metric.

## Key Files

### Status Command
- `init.lua` - State management and query control
- `factory_parser.lua` - Extracts structured data from game output
- `factory_formatter.lua` - Creates formatted table display (includes I/E ratio calculation)
- `factory_capture_timer.lua` - Timer-based completion detection
- `factory_capture_line.lua` (trigger) - Captures and hides output lines
- `no_factory.lua` (trigger) - Detects empty factory slot, records as missing

### Flush Command
- `init.lua` - State management (shared with status), settings registration
- `factory_flush.lua` - Flush iteration logic
- `factory_flush_success.lua` (trigger) - Detects flush success, continues to next
- `factory_flush_no_factory.lua` (trigger) - Detects empty factory slot, skips to next
- `game_shutdown_warning.lua` (trigger) - Auto-flush before game reset if enabled

### Shared
- `factory.lua` (alias) - Command routing for status and flush
- `factory_help_init.lua` - Help registration

## Reusable Pattern

This pattern can be reused for other multi-query tools (e.g., ship status, warehouse inventory):
- Sequential command sending
- Timer-based output completion detection
- Buffer-based parsing
- State machine for tracking progress
