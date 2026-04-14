local Settings = {
    language = "EN",
    volume = 1
}

function Settings.set(data)
    for k,v in pairs(data) do
        Settings[k] = v
    end
end

return Settings