-- Initialize f2t-bulk-commands
-- This script sets up state tracking for bulk buy/sell operations

-- Global state for bulk command operations
F2T_BULK_STATE = {
    active = false,      -- Whether a bulk operation is in progress
    command = nil,       -- "buy" or "sell"
    commodity = nil,     -- Commodity name
    remaining = 0,       -- Number of operations remaining
    total = 0,           -- Total operations requested
    callback = nil,      -- Callback function for programmatic mode

    -- Sell tracking (for margin calculation)
    total_cost = 0,      -- Total cost of cargo being sold
    total_revenue = 0,   -- Total revenue from sales
    lots_sold = 0        -- Number of lots sold (for averaging)
}

f2t_debug_log("[f2t-bulk-commands] Initialized bulk command state")
