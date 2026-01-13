-- Federation 2 Rank Management
-- Provides utilities for checking character rank and rank comparisons

-- ========================================
-- Rank Definitions
-- ========================================

-- Rank order (advancing progression)
-- Note: Adventurer/Adventuress is the only gender-specific rank
F2T_RANKS = {
    "Groundhog",
    "Commander",
    "Captain",
    "Adventurer",      -- Male characters
    "Adventuress",     -- Female characters (same level as Adventurer)
    "Merchant",
    "Trader",
    "Industrialist",
    "Manufacturer",
    "Financier",
    "Founder",
    "Engineer",
    "Mogul",
    "Technocrat",
    "Gengineer",
    "Magnate",
    "Plutocrat"
}

-- Map rank names to their numeric level (for comparison)
-- Adventurer and Adventuress are both level 4
F2T_RANK_LEVELS = {
    groundhog = 1,
    commander = 2,
    captain = 3,
    adventurer = 4,
    adventuress = 4,      -- Same level as Adventurer
    merchant = 5,
    trader = 6,
    industrialist = 7,
    manufacturer = 8,
    financier = 9,
    founder = 10,
    engineer = 11,
    mogul = 12,
    technocrat = 13,
    gengineer = 14,
    magnate = 15,
    plutocrat = 16
}

-- ========================================
-- Rank Query Functions
-- ========================================

-- Get the character's current rank from GMCP
-- Returns: rank string, or nil if not available
function f2t_get_rank()
    local rank = gmcp.char and gmcp.char.vitals and gmcp.char.vitals.rank

    if not rank or rank == "" then
        f2t_debug_log("[rank] No rank data available from GMCP")
        return nil
    end

    f2t_debug_log("[rank] Current rank: %s", rank)
    return rank
end

-- Get the numeric level for a rank name
-- Returns: level number, or nil if rank not recognized
function f2t_get_rank_level(rank_name)
    if not rank_name then
        return nil
    end

    local rank_lower = string.lower(rank_name)
    local level = F2T_RANK_LEVELS[rank_lower]

    if not level then
        f2t_debug_log("[rank] Unknown rank: %s", rank_name)
        return nil
    end

    return level
end

-- ========================================
-- Rank Comparison Functions
-- ========================================

-- Check if character is at or above a specified rank
-- @param required_rank: Rank name to check against (case-insensitive)
-- Returns: true if at or above rank, false otherwise
function f2t_is_rank_or_above(required_rank)
    local current_rank = f2t_get_rank()

    if not current_rank then
        f2t_debug_log("[rank] Cannot determine current rank, assuming insufficient")
        return false
    end

    local current_level = f2t_get_rank_level(current_rank)
    local required_level = f2t_get_rank_level(required_rank)

    if not current_level or not required_level then
        f2t_debug_log("[rank] Invalid rank comparison: current=%s, required=%s",
            tostring(current_rank), tostring(required_rank))
        return false
    end

    local result = current_level >= required_level
    f2t_debug_log("[rank] Rank check: %s (level %d) >= %s (level %d)? %s",
        current_rank, current_level, required_rank, required_level, tostring(result))

    return result
end

-- Check if character is below a specified rank
-- @param rank_name: Rank name to check against (case-insensitive)
-- Returns: true if below rank, false otherwise
function f2t_is_rank_below(rank_name)
    return not f2t_is_rank_or_above(rank_name)
end

-- Check if character is exactly a specific rank
-- @param rank_name: Rank name to check (case-insensitive)
-- Returns: true if exact match, false otherwise
function f2t_is_rank_exactly(rank_name)
    local current_rank = f2t_get_rank()

    if not current_rank then
        return false
    end

    local current_level = f2t_get_rank_level(current_rank)
    local target_level = f2t_get_rank_level(rank_name)

    if not current_level or not target_level then
        return false
    end

    local result = current_level == target_level
    f2t_debug_log("[rank] Exact rank check: %s == %s? %s",
        current_rank, rank_name, tostring(result))

    return result
end

-- ========================================
-- Rank Requirement Check
-- ========================================

-- Check if character meets rank requirement and display error if not
-- @param required_rank: Minimum rank required
-- @param feature_name: Name of feature requiring this rank (for error message)
-- Returns: true if requirement met, false otherwise
function f2t_check_rank_requirement(required_rank, feature_name)
    if f2t_is_rank_or_above(required_rank) then
        return true
    end

    local current_rank = f2t_get_rank()
    local current_level = f2t_get_rank_level(current_rank)
    local required_level = f2t_get_rank_level(required_rank)

    cecho(string.format("\n<red>[fed2-tools]<reset> %s requires rank <cyan>%s<reset> or higher\n",
        feature_name, required_rank))

    if current_rank then
        cecho(string.format("<dim_grey>Your current rank: <white>%s<reset> (level %d/%d)<reset>\n",
            current_rank, current_level or 0, required_level or 0))
    else
        cecho("\n<dim_grey>Unable to determine your current rank<reset>\n")
    end

    return false
end

f2t_debug_log("[rank] Rank system initialized")
