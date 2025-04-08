QBCoreHandler = {}

function QBCoreHandler:startListener()
    GlobalHandler:startListener()

    RegisterNetEvent('qb-multicharacter:server:loadUserData', function()
        if (source == nil) then
            Citizen.SetTimeout(1000, function()
                Socket:broadcast('update_players', { players = FXServer:getHandler():getPlayers() })
            end)
        end
    end)
end

function QBCoreHandler:getPlayers()
    local users = {}
    local _, err = pcall(function()
        users = FXServer:getFrameworkAPI().Functions.GetQBPlayers()
    end)
    if (err) then
        users = FXServer:getFrameworkAPI().Players
    end

    local usersList = {}

    for src, player in pairs(users) do
        local player = {
            id = player.PlayerData.citizenid,
            name = GetPlayerName(src),
            license = FXServer:getFrameworkAPI().Functions.GetIdentifier(src, 'license'):gsub("license:", ""),
        }
        usersList[#usersList + 1] = player
    end

    self:getPlayersWithoutCitizenId()

    return { usersList, self:getPlayersWithoutCitizenId() }
end

function QBCoreHandler:getPlayersWithoutCitizenId()
    local usersList = {}
    for _, src in ipairs(GetPlayers()) do
        if (FXServer:getFrameworkAPI().Functions.GetPlayer(tonumber(src)) == nil) then
            local player = {
                name = GetPlayerName(src),
                source = src,
            }

            for _, v in pairs(GetPlayerIdentifiers(src)) do
                if string.sub(v, 1, string.len("license:")) == "license:" then
                    player['license'] = v:gsub("license:", "");
                    break ;
                end
            end
            usersList[#usersList + 1] = player
        end
    end
    return usersList
end

function QBCoreHandler:getPlayerInfo(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)

    if (player ~= nil) then
        local player = {
            name = GetPlayerName(player.PlayerData.source),
            identity = self:getPlayerIdentity(user_id),
            money = self:getMoney(user_id),
            job = self:getJob(user_id),
            vehicles = self:getVehicles(user_id),
            license = FXServer:getFrameworkAPI().Functions.GetIdentifier(player.PlayerData.source, 'license'):gsub("license:", "")
        };

        return player
    end

    return nil;
end

function QBCoreHandler:getPlayerIdentity(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)

    if (player ~= nil) then
        local charInfo = player.PlayerData.charinfo;
        local response = {
            citizenid = player.PlayerData.citizenid,
            firstname = charInfo.firstname,
            lastname = charInfo.lastname,
            nationality = charInfo.nationality,
            gender = (charInfo.gender == 0 and 'Male' or 'Female'),
        };

        return response;
    end
end

---
--- Money Begin
---

function QBCoreHandler:getMoney(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        local money = player.PlayerData.money
        return {
            cash = money['cash'],
            bank = money['bank']
        }
    end

    return nil
end

function QBCoreHandler:giveMoney(user_id, amount, type)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (type == 'cash' or type == 'bank') then
        if (player ~= nil) then
            player.Functions.AddMoney(type, amount)
            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        end
    end
    return true
end

function QBCoreHandler:removeMoney(user_id, amount, type)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (type == 'cash' or type == 'bank') then
        if (player ~= nil) then
            player.Functions.RemoveMoney(type, amount)
            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        end
    end
    return true
end

---
--- Money End
---


---
--- Vehicle Begin
---

local function GeneratePlate()
    local plate = FXServer:getFrameworkAPI().Shared.RandomInt(1) ..
            FXServer:getFrameworkAPI().Shared.RandomStr(2) ..
            FXServer:getFrameworkAPI().Shared.RandomInt(3) ..
            FXServer:getFrameworkAPI().Shared.RandomStr(2)

    local result = QBCoreHandler:sqlQuery('SELECT plate FROM ' .. Config:get('tables.qbcore.player_vehicles', 'player_vehicles'):gsub("%s+", "") .. ' WHERE plate = ?', { plate })
    if #result > 0 then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

function QBCoreHandler:getVehicles(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        local vehiclesData = QBCoreHandler:sqlQuery('SELECT * FROM ' .. Config:get('tables.qbcore.player_vehicles', 'player_vehicles'):gsub("%s+", "") .. ' WHERE citizenid = ?', {
            player.PlayerData.citizenid,
        })
        local vehicles = {}

        for key, value in pairs(vehiclesData) do
            local data = {
                id = value['id'],
                model = value['vehicle'],
                plate = value['plate']
            }

            table.insert(vehicles, data)
        end

        return vehicles
    end
end

function QBCoreHandler:giveVehicle(user_id, model)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        if (FXServer:getFrameworkAPI().Shared.Vehicles[model] ~= nil) then
            local hash = GetHashKey(model);

            CreateThread(function()
                QBCoreHandler:sqlQuery('INSERT INTO ' .. Config:get('tables.qbcore.player_vehicles', 'player_vehicles'):gsub("%s+", "") .. ' (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                    player.PlayerData.license,
                    player.PlayerData.citizenid,
                    model,
                    hash,
                    '{}',
                    GeneratePlate(),
                    0
                })

                Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
            end)
        end
        return true
    end
end

function QBCoreHandler:removeVehicle(user_id, id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        CreateThread(function()
            QBCoreHandler:sqlQuery('DELETE FROM ' .. Config:get('tables.qbcore.player_vehicles', 'player_vehicles'):gsub("%s+", "") .. ' WHERE id = ? AND citizenid = ?', {
                id,
                player.PlayerData.citizenid,
            })
            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        end)
        return true
    end
end

function QBCoreHandler:removeVehicleByModel(user_id, model)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        CreateThread(function()
            QBCoreHandler:sqlQuery('DELETE FROM ' .. Config:get('tables.qbcore.player_vehicles', 'player_vehicles'):gsub("%s+", "") .. ' WHERE vehicle = ? AND citizenid = ?', {
                model,
                player.PlayerData.citizenid,
            })
            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        end)
        return true
    end
end

---
--- Vehicle End
---


---
--- Job Begin
---

function QBCoreHandler:getJob(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        local job = player.PlayerData.job
        local name = job['name']
        if (job['grade'] ~= nil) then
            name = name .. ' - ' .. job['grade']['name']
        end

        return name
    end
end

function QBCoreHandler:setJob(user_id, job, grade)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        player.Functions.SetJob(job, grade)
        Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        return true
    end
end

---
--- Job End
---
---
function QBCoreHandler:message(user_id, message, color)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        GlobalHandler:sendMessage(player.PlayerData.source, message, color)
    end
    return true
end

function QBCoreHandler:revive(user_id)
    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        GlobalHandler:revive(player.PlayerData.source)
        return true
    end
end

function QBCoreHandler:kickSource(src, reason)
    if reason == nil then
        reason = 'No reason'
    end

    DropPlayer(src, reason)
end

function QBCoreHandler:kick(user_id, reason)
    if reason == nil then
        reason = 'No reason'
    end

    local player = FXServer:getFrameworkAPI().Functions.GetPlayerByCitizenId(user_id)
    if (player ~= nil) then
        FXServer:getFrameworkAPI().Functions.Kick(player.PlayerData.source, reason, false, false)
        return true
    end
end

function QBCoreHandler:getBans(page)
    local bansData = QBCoreHandler:sqlQuery('SELECT * FROM ' .. Config:get('tables.qbcore.bans', 'bans'):gsub("%s+", ""))
    local bans = {}

    for k, v in pairs(bansData) do
        table.insert(bans, {
            id = v['id'],
            license = v['license']:gsub("license:", ""),
            name = v['name'],
            expire = v['expire'],
            bannedby = v['bannedby'],
            reason = v['reason']
        })
    end
    bans = Chunks:reverseTable(bans)

    local chunks = Chunks:tableChunks(bans, 10)
    local pageChunk = Chunks:getChunkOrNil(chunks, page)
    local response = {
        data = pageChunk,
        pagination = {
            total = #bans,
            lastPage = #chunks,
        }
    }

    return response;
end

function QBCoreHandler:ban(license, name, time, reason, bannedby)
    local banTime = 2147483647
    if tonumber(time) then
        banTime = os.time() + tonumber(time)
        if banTime > 2147483647 then
            banTime = 2147483647
        end
    end
    if reason == nil then
        reason = 'No reason'
    end

    CreateThread(function()
        QBCoreHandler:sqlQuery('INSERT INTO ' .. Config:get('tables.qbcore.bans', 'bans'):gsub("%s+", "") .. ' (name, license, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?)', {
            name,
            'license:' .. license,
            reason,
            banTime,
            bannedby
        })
        Socket:broadcast('update_bans', {})
    end)

    local src = FXServer:getFrameworkAPI().Functions.GetSource('license:' .. license)
    if (src ~= 0) then
        FXServer:getFrameworkAPI().Functions.Kick(src, reason, false, false)
    end
    return true
end

function QBCoreHandler:unban(id)
    CreateThread(function()
        QBCoreHandler:sqlQuery('DELETE FROM ' .. Config:get('tables.qbcore.bans', 'bans'):gsub("%s+", "") .. ' WHERE id = ?', {
            id
        })
        Socket:broadcast('update_bans', {})
    end)
    return true
end

function QBCoreHandler:alertMessage(message, color)
    GlobalHandler:sendMessage(-1, message, color)
    return true
end

function QBCoreHandler:licenseToPlayerId(license)
    local users = {}
    local _, err = pcall(function()
        users = FXServer:getFrameworkAPI().Functions.GetQBPlayers()
    end)
    if (err) then
        users = FXServer:getFrameworkAPI().Players
    end
    local id = nil

    for src, player in pairs(users) do
        local pLicense = FXServer:getFrameworkAPI().Functions.GetIdentifier(src, 'license'):gsub("license:", "")
        if (pLicense == license) then
            id = player.PlayerData.citizenid
            break
        end
    end

    return id
end

function QBCoreHandler:sqlQuery(query, params)
    local ghmattimysql = Config:get('qbcore.ghmattimysql', false)

    if (ghmattimysql) then
        local d = promise.new()
        QBCoreHandler:ghmattiMysqlExecuteSql(true, query, params, function(data)
            return d:resolve(data)
        end)
        return Citizen.Await(d)
    else
        local d = promise.new()
        OXMySQL.query(query, params, function(data)
            return d:resolve(data)
        end)
        return Citizen.Await(d)
    end
end

--
-- This function is taken from QBCore (old version)
-- All sources goes to QBCore
--
function QBCoreHandler:ghmattiMysqlExecuteSql(wait, query, params, cb)
    local rtndata = {}
    local waiting = true
    exports['ghmattimysql']:execute(query, params, function(data)
        if cb ~= nil and wait == false then
            cb(data)
        end
        rtndata = data
        waiting = false
    end)
    if wait then
        while waiting do
            Citizen.Wait(5)
        end
        if cb ~= nil and wait == true then
            cb(rtndata)
        end
    end
    return rtndata
end