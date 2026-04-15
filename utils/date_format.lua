local DateFormat = {}

-- formats unix timestamp -> readable string
function DateFormat.format(timestamp)
    if type(timestamp) ~= "number" then
        return "INVALID_DATE"
    end

    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- optional: short version for UI menus
function DateFormat.short(timestamp)
    if type(timestamp) ~= "number" then
        return "??"
    end

    return os.date("%d/%m %H:%M", timestamp)
end

return DateFormat