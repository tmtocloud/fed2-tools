-- Puts all commodities in the Commodities window, sorted alphabetically by name
function ui_commodities()
    -- Load commodity data from JSON
    local filePath = getMudletHomeDir() .. "/fed2-tools/shared/commodities.json"
    local file = io.open(filePath, "r")
    
    if not file then
        f2t_debug_log("[ui] ERROR: Could not open commodities.json")
        return
    end
    
    local jsonString = file:read("*all")
    file:close()
    
    local data = yajl.to_value(jsonString)
    if not data or not data.groups then
        f2t_debug_log("[ui] ERROR: Invalid commodities.json format")
        return
    end
    
    -- Extract all commodities into a flat list
    local commodities = {}
    for _, group in ipairs(data.groups) do
        for _, commodity in ipairs(group.commodities) do
            table.insert(commodities, {
                name      = commodity.name,
                shortName = commodity.shortName,
                basePrice = commodity.basePrice
            })
        end
    end
    
    -- Sort alphabetically by name
    table.sort(commodities, function(a, b)
        return a.name < b.name
    end)
    
    return commodities
end

function ui_output_commodities()
    if not ui_commodities_window then
        f2t_debug_log("[ui] commodities_window not available")
        return
    end
    
    clearWindow("ui_commodities_window")

    local commodityData = ui_commodities()

    -- Display in window
    for _, commodity in ipairs(commodityData) do
        local displayName = commodity.name
        if commodity.shortName then
            displayName = string.format("%s (%s)", commodity.name, commodity.shortName)
        end
        ui_commodities_window:echo(finalList,string.format("%s (%d)\n", displayName, commodity.basePrice))
    end

    f2t_debug_log("[ui] Displayed %d commodities", #formattedCommods)
end