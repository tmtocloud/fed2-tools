-- Factory Output Parser
-- Parses captured factory display output into structured data

function f2t_factory_parse_buffer()
    local buffer = f2t_factory.capture_buffer
    local factory = {
        number = f2t_factory.current_number,
        commodity = "",
        location = "",
        status = "",
        working_capital = 0,
        income = 0,
        expenditure = 0,
        profit = 0,
        efficiency = 0,
        efficiency_max = 100,
        wages = 0,
        workers_required = 0,
        workers_hired = 0,
        storage_available = 0,
        storage_max = 0,
        inputs_met = true,
        batch_completion = 0
    }

    for _, line in ipairs(buffer) do

        -- Parse commodity name from facility header line
        -- Format: <company_name>: <commodity> Production Facility #<N>
        -- Example: "Summit Partners: Artifacts Production Facility #1"
        -- Example: "Entropic Field Research Inc.: Artifacts Production Facility #1"
        -- Company name can contain any characters - match up to colon, then capture commodity
        f2t_debug_log("[factory-status] Checking Commodity line: %s", line)
        local commodity = line:match(".-:%s+(%w+)%s+Production Facility")
        if commodity then
            f2t_debug_log("[factory-status] Parsing Commodity line: commodity='%s'", tostring(commodity))
            factory.commodity = commodity
        end

        -- Location and Status
        f2t_debug_log("[factory-status] Checking Location/Status line: %s", line)
        local loc, stat = line:match("Location:%s*(.-)%s+Status:%s*(.+)")
        if loc then
            f2t_debug_log("[factory-status] Parsing Location/Status line: loc='%s' stat='%s'", tostring(loc), tostring(stat))
            factory.location = loc
            factory.status = stat
        end

        -- Working Capital (may have Top Up Level on same line)
        f2t_debug_log("[factory-status] Checking Working Capital line: %s", line)
        local wc = line:match("Working Capital:%s*([0-9,]+)ig")
        if wc then
            factory.working_capital = tonumber((wc:gsub(",", "")))
        end

        -- Income and Expenditure (on same line)
        f2t_debug_log("[factory-status] Checking Income/Expenditure line: %s", line)
        local inc, exp = line:match("Income:%s*([0-9,]+)ig%s+Expenditure:%s*([0-9,]+)ig")
        if inc and exp then
            f2t_debug_log("[factory-status] Parsing Income/Expenditure line: inc='%s' exp='%s'", tostring(inc), tostring(exp))
            factory.income = tonumber((inc:gsub(",", "")))
            factory.expenditure = tonumber((exp:gsub(",", "")))
        end

        -- Efficiency
        f2t_debug_log("[factory-status] Checking Efficiency line: %s", line)
        local eff, eff_max = line:match("Efficiency:%s*(%d+)/(%d+)")
        if eff then
            f2t_debug_log("[factory-status] Parsing Efficiency line: eff='%s' eff_max='%s'", tostring(eff), tostring(eff_max))
            factory.efficiency = tonumber(eff)
            factory.efficiency_max = tonumber(eff_max)
        end

        -- Storage
        f2t_debug_log("[factory-status] Checking Storage line: %s", line)
        local storage_available, storage_max = line:match("Storage:%s*(%d+)/(%d+)%s+tons")
        if storage_available then
            f2t_debug_log("[factory-status] Parsing Storage line: available='%s' max='%s'", tostring(storage_available), tostring(storage_max))
            factory.storage_available = tonumber(storage_available)
            factory.storage_max = tonumber(storage_max)
        end

        -- Workers
        f2t_debug_log("[factory-status] Checking Workers line: %s", line)
        local req, hired, wages = line:match("Required:%s*(%d+)%s+Hired:%s*(%d+)%s+Wages:%s*(%d+)ig")
        if req then
            f2t_debug_log("[factory-status] Parsing Workers line: req='%s' hired='%s' wages='%s'", tostring(req), tostring(hired), tostring(wages))
            factory.workers_required = tonumber(req)
            factory.workers_hired = tonumber(hired)
            factory.wages = tonumber(wages)
        end

        -- Input check (if any input line shows Available < Required, inputs not met)
        f2t_debug_log("[factory-status] Checking Input line: %s", line)
        local input_req, input_avail = line:match("Required:%s*(%d+)%s+Available:%s*(%d+)")
        if input_req and tonumber(input_avail) < tonumber(input_req) then
            f2t_debug_log("[factory-status] Input line shows insufficient inputs: req='%s' avail='%s'", tostring(input_req), tostring(input_avail))
            factory.inputs_met = false
        end

        -- Batch completion
        f2t_debug_log("[factory-status] Checking Batch Completion line: %s", line)
        local batch = line:match("Next batch is (%d+)%%")
        if batch then
            f2t_debug_log("[factory-status] Parsing Batch Completion line: batch='%s'", tostring(batch))
            factory.batch_completion = tonumber(batch)
        end
    end

    f2t_debug_log("[factory-status] Parsed factory #%d - %s", factory.number, factory.location)

    return factory
end

-- Process captured factory data
function f2t_factory_process_capture()
    local factory = f2t_factory_parse_buffer()
    factory.profit = factory.income - factory.expenditure
    table.insert(f2t_factory.factories, factory)

    f2t_debug_log("[factory-status] Stored factory #%d, total factories: %d", factory.number, #f2t_factory.factories)

    -- Query next factory
    f2t_factory_query_next()
end
