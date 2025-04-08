AutoLogin = {}
AutoLogin.waiting = {}
AutoLogin.disabled = nil

RegisterNetEvent('sqdzconnector:open:website', function()
    if (AutoLogin.waiting[source] == nil and (AutoLogin.disabled == nil or AutoLogin.disabled + 300 < os.time())) then
        AutoLogin.waiting[source] = true;
        AutoLogin.disabled = nil;

        local src = source
        local license = AutoLogin:getSourceLicense(src)

        PerformHttpRequest(Config:get('api_url') .. '/autologin/generate/token', function(status, res, headers)
            local data = json.decode(res);
            if (res ~= nil and data ~= nil and data.data ~= nil and data.data.url ~= nil) then
                CreateThread(function()
                    TriggerClientEvent('sqdzconnector:open:website:data', src, { url = data.data.url, token = data.data.token })
                    AutoLogin.waiting[src] = nil;
                end)
            else
                AutoLogin.disabled = os.time()
                AutoLogin.waiting[src] = nil;
            end
        end, 'POST', json.encode({ license = license }), { ['Authorization'] = 'FXServer ' .. Config:get('token'), ['Content-Type'] = 'application/json' })
    end
end)

function AutoLogin:getSourceLicense(source)
    local license = nil
    for k, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            license = v:gsub("license:", "");
            break ;
        end
    end
    return license
end