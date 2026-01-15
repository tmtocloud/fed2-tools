-- Check GitHub for latest release version
-- Uses async getHTTP with event handlers (requires Mudlet 4.10+)

F2T_VERSION_CHECK_STATE = {
    checking = false,
    handler_id = nil,
    error_handler_id = nil
}

-- Check if version string is a prerelease (contains hyphen suffix like -abc123)
function f2t_version_is_prerelease(version)
    if not version then return false end
    return version:match("^%d+%.%d+%.%d+%-") ~= nil
end

function f2t_check_latest_version()
    -- Show current version immediately
    local current = F2T_VERSION
    if not current then
        cecho("\n<green>[fed2-tools]<reset> Version: <yellow>development<reset>\n")
        return
    end

    -- Check if this is a prerelease version
    if f2t_version_is_prerelease(current) then
        cecho(string.format("\n<green>[fed2-tools]<reset> Prerelease v%s\n", current))
        cecho("<dim_grey>  (Cannot check for updates on prerelease versions)<reset>\n")
        return
    end

    cecho(string.format("\n<green>[fed2-tools]<reset> Version: %s\n", current))

    -- Check if getHTTP available (Mudlet 4.10+)
    if not getHTTP then
        cecho("<dim_grey>  (Update check requires Mudlet 4.10+)<reset>\n")
        return
    end

    -- Avoid duplicate checks
    if F2T_VERSION_CHECK_STATE.checking then
        return
    end

    F2T_VERSION_CHECK_STATE.checking = true
    cecho("<dim_grey>  Checking for updates...<reset>\n")

    -- Register success handler
    F2T_VERSION_CHECK_STATE.handler_id = registerAnonymousEventHandler(
        "sysGetHttpDone",
        function(_, url, body)
            if url:find("api.github.com/repos/ping65510/fed2%-tools") then
                f2t_version_check_handle_response(body)
                f2t_version_check_cleanup()
            end
        end
    )

    -- Register error handler
    F2T_VERSION_CHECK_STATE.error_handler_id = registerAnonymousEventHandler(
        "sysGetHttpError",
        function(_, err, url)
            if url and url:find("api.github.com/repos/ping65510/fed2%-tools") then
                f2t_debug_log("[version] HTTP error: %s", tostring(err))
                cecho("<dim_grey>  (Could not check for updates)<reset>\n")
                f2t_version_check_cleanup()
            end
        end
    )

    -- Set timeout
    tempTimer(10, function()
        if F2T_VERSION_CHECK_STATE.checking then
            cecho("<dim_grey>  (Update check timed out)<reset>\n")
            f2t_version_check_cleanup()
        end
    end)

    -- Make request
    getHTTP("https://api.github.com/repos/ping65510/fed2-tools/releases/latest")
end

function f2t_version_check_handle_response(body)
    local success, data = pcall(yajl.to_value, body)
    if not success or not data then
        f2t_debug_log("[version] Failed to parse response")
        return
    end

    local latest_tag = data.tag_name
    if not latest_tag then
        f2t_debug_log("[version] No tag_name in response")
        return
    end

    -- Strip 'v' prefix if present
    local latest_version = latest_tag:match("^v?(.+)$")
    local current = F2T_VERSION

    if f2t_version_is_newer(latest_version, current) then
        cecho(string.format(
            "<yellow>  Update available: %s -> %s<reset>\n",
            current, latest_version
        ))
        cecho("<dim_grey>  https://github.com/ping65510/fed2-tools/releases<reset>\n")
    else
        cecho("<green>  You have the latest version<reset>\n")
    end
end

function f2t_version_check_cleanup()
    if F2T_VERSION_CHECK_STATE.handler_id then
        killAnonymousEventHandler(F2T_VERSION_CHECK_STATE.handler_id)
        F2T_VERSION_CHECK_STATE.handler_id = nil
    end
    if F2T_VERSION_CHECK_STATE.error_handler_id then
        killAnonymousEventHandler(F2T_VERSION_CHECK_STATE.error_handler_id)
        F2T_VERSION_CHECK_STATE.error_handler_id = nil
    end
    F2T_VERSION_CHECK_STATE.checking = false
end

-- Compare semver versions: returns true if v1 > v2
function f2t_version_is_newer(v1, v2)
    if not v1 or not v2 then return false end

    local function parse(v)
        local major, minor, patch = v:match("^(%d+)%.?(%d*)%.?(%d*)")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end

    local maj1, min1, pat1 = parse(v1)
    local maj2, min2, pat2 = parse(v2)

    if maj1 ~= maj2 then return maj1 > maj2 end
    if min1 ~= min2 then return min1 > min2 end
    return pat1 > pat2
end
