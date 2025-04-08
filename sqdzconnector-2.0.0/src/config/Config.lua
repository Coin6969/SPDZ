Config = {}

function Config:load()
    Log:print("Loading config.json ...")
    local configFile = LoadResourceFile(GetCurrentResourceName(), "./config.json");
    local configDecoded = json.decode(configFile)
    if (configDecoded ~= nil and configDecoded.token ~= nil and configDecoded.node_url ~= nil and configDecoded.api_url ~= nil) then
        Config.data = configDecoded
        Log:print("Config has been loaded successfully!")
        return true
    else
        Log:error("Config hasn't been loaded successfully! Please make sure to copy correct data from your control panel and paste them in config.json")
        Log:error("Script is not starting...")
        return false
    end
end

function Config:get(name, default)
    local value = Config.data
    for n in name.gmatch(name, '([^\\.]+)') do
        if (value ~= nil) then
            value = value[n]
        end
    end

    if value == Config.data then
        value = nil
    end

    if (value ~= nil) then
        return value
    else
        return default
    end
end