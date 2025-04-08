GlobalHandler = {}

function GlobalHandler:startListener()
    RegisterNetEvent('chatMessage', function(src, author, text)
        if (string.len(text) > 256) then
            text = string.sub(text, 1, 256) .. '[...' .. string.len(text)-256 .. ']';
        end
        local message = {author = author, text = text};

        for _, v in pairs(GetPlayerIdentifiers(src)) do
            if string.sub(v, 1, string.len("license:")) == "license:" then
                message['authorLicense'] = v:gsub("license:", "");
                break ;
            end
        end
        Socket:broadcast('chat', message)
    end)

    AddEventHandler('playerConnecting', function (playerName)
        Socket:broadcast('player_connecting', {name = playerName})
    end)

    AddEventHandler('playerJoining', function ()
        Socket:broadcast('player_joined', {name = GetPlayerName(source)})
        Citizen.SetTimeout(1000, function()
            Socket:broadcast('update_players', {players = FXServer:getHandler():getPlayers()})
        end)
    end)
    AddEventHandler('playerDropped', function ()
        Socket:broadcast('player_left', {name = GetPlayerName(source)})
        Citizen.SetTimeout(1000, function()
            Socket:broadcast('update_players', {players = FXServer:getHandler():getPlayers()})
        end)
    end)
end

function GlobalHandler:licenseToPlayerSource(license)
    local source = nil;
    for _, src in ipairs(GetPlayers()) do
            for _, v in pairs(GetPlayerIdentifiers(src)) do
                if string.sub(v, 1, string.len("license:")) == "license:" then
                    if license == v:gsub("license:", "") then
                        source = src;
                        break
                    end
                end
            end
    end

    return source
end

function GlobalHandler:sendMessage(source, message, color)
    TriggerClientEvent('chat:addMessage', source, {
        color = { color[1], color[2], color[3] },
        template = '<div style="color: rgba(' .. color[1] .. ', ' .. color[2] .. ', ' .. color[3] .. ');">{0}</div>',
        args = {message}
    })
end

function GlobalHandler:revive(source)
    TriggerClientEvent('sqdzconnector:heal', source)
end