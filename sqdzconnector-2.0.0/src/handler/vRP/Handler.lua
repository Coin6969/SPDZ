vRPHandler = {}

function vRPHandler:setup()
    -- vehicles
    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_get_vehicles_columns", "SHOW COLUMNS FROM `" .. Config:get('tables.vrp.vrp_user_vehicles', 'vrp_user_vehicles'):gsub("%s+", "") .. "`;")

    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_get_vehicles", "SELECT * FROM " .. Config:get('tables.vrp.vrp_user_vehicles', 'vrp_user_vehicles'):gsub("%s+", "") .. " WHERE user_id = @user_id")
    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_add_vehicle_with_plate", "INSERT IGNORE INTO " .. Config:get('tables.vrp.vrp_user_vehicles', 'vrp_user_vehicles'):gsub("%s+", "") .. "(user_id,vehicle,vehicle_plate) VALUES(@user_id,@vehicle,@plate)")
    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_add_vehicle_without_plate", "INSERT IGNORE INTO " .. Config:get('tables.vrp.vrp_user_vehicles', 'vrp_user_vehicles'):gsub("%s+", "") .. "(user_id,vehicle) VALUES(@user_id,@vehicle)")
    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_remove_vehicle", "DELETE FROM " .. Config:get('tables.vrp.vrp_user_vehicles', 'vrp_user_vehicles'):gsub("%s+", "") .. " WHERE user_id = @user_id AND vehicle = @vehicle")

    -- bans
    FXServer:getAdditionalData('MySQL').createCommand("vRP/sqdz_connector_get_bans", "SELECT * FROM `" .. Config:get('tables.vrp.vrp_users', 'vrp_users'):gsub("%s+", "") .. "` WHERE banned = 1")
end

function vRPHandler:startListener()
    GlobalHandler:startListener()
end

function vRPHandler:getPlayers()
    local users = FXServer:getFrameworkAPI().getUsers()
    local usersList = {}

    for userid, source in pairs(users) do
        local player = {
            id = userid,
            name = GetPlayerName(source),
        }
        for _, v in pairs(GetPlayerIdentifiers(source)) do
            if string.sub(v, 1, string.len("license:")) == "license:" then
                player['license'] = v:gsub("license:", "");
                break ;
            end
        end
        usersList[#usersList + 1] = player
    end
    return usersList
end

function vRPHandler:getPlayerInfo(user_id)
    local playerSource = FXServer:getFrameworkAPI().getUserSource({ tonumber(user_id) })

    if (playerSource ~= nil) then
        local player = {
            name = GetPlayerName(playerSource),
            identity = self:getUserIdentity(user_id),
            money = self:getMoney(user_id),
            groups = self:getGroups(user_id),
            vehicles = self:getVehicles(user_id),
        };

        for k, v in pairs(GetPlayerIdentifiers(playerSource)) do
            if string.sub(v, 1, string.len("license:")) == "license:" then
                player['license'] = v:gsub("license:", "");
                break ;
            end
        end

        return player
    end

    return nil;
end

function vRPHandler:getUserIdentity(user_id)
    local player = FXServer:getFrameworkAPI().getUserSource({ tonumber(user_id) })

    if (player ~= nil) then
        local d = promise.new()
        FXServer:getFrameworkAPI().getUserIdentity({ user_id, function(identity)
            d:resolve(identity)
        end })

        return Citizen.Await(d)
    end

    return nil;
end
---
--- Money Begin
---

function vRPHandler:getMoney(user_id)
    local player = FXServer:getFrameworkAPI().getUserSource({ tonumber(user_id) })

    if (player ~= nil) then
        return {
            cash = FXServer:getFrameworkAPI().getMoney({ user_id }),
            bank = FXServer:getFrameworkAPI().getBankMoney({ user_id })
        }
    end

    return nil
end

function vRPHandler:giveMoney(user_id, amount, type)
    if (type == 'cash' or type == 'bank') then
        if (type == 'cash') then
            FXServer:getFrameworkAPI().giveMoney({ user_id, amount })
        else
            FXServer:getFrameworkAPI().giveBankMoney({ user_id, amount })
        end

        Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        return true
    end
end

function vRPHandler:removeMoney(user_id, amount, type)
    if (type == 'cash' or type == 'bank') then
        local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
        if (player ~= nil) then
            local money = self:getMoney(user_id)
            local toRemove = amount
            if (type == 'cash') then
                if (toRemove >= money['cash']) then
                    toRemove = money['cash']
                end
            else
                if (toRemove >= money['bank']) then
                    toRemove = money['bank']
                end
            end

            if (type == 'cash') then
                FXServer:getFrameworkAPI().setMoney({ user_id, money['cash'] - toRemove })
            else
                FXServer:getFrameworkAPI().setBankMoney({ user_id, money['bank'] - toRemove })
            end

            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
            return true
        end
    end
end

---
--- Money End
---


---
--- Vehicles Begin
---

function vRPHandler:getVehicles(user_id)
    local vehiclesData = FXServer:getAdditionalData('MySQL').asyncQuery("vRP/sqdz_connector_get_vehicles", { user_id = user_id })
    local vehicles = {}

    for k, v in pairs(vehiclesData) do
        local data = {
            user_id = v['user_id'],
            model = v['vehicle']
        }

        if (v['vehicle_plate'] ~= nil) then
            data['plate'] = v['vehicle_plate']
        end
        table.insert(vehicles, data)
    end

    return vehicles
end

function vRPHandler:giveVehicle(user_id, model)
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        local isVehiclePlateAvailable = isVehiclePlateAvailable()
        if (isVehiclePlateAvailable == true) then
            FXServer:getFrameworkAPI().getUserIdentity({ user_id, function(identity)
                FXServer:getAdditionalData('MySQL').execute("vRP/sqdz_connector_add_vehicle_with_plate", { user_id = user_id, vehicle = model, plate = "P " .. identity.registration })
                Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
            end })
            return true
        else
            FXServer:getAdditionalData('MySQL').execute("vRP/sqdz_connector_add_vehicle_without_plate", { user_id = user_id, vehicle = model })
            Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
            return true
        end
    end
end

function vRPHandler:removeVehicle(user_id, model)
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        FXServer:getAdditionalData('MySQL').execute("vRP/sqdz_connector_remove_vehicle", { user_id = user_id, vehicle = model })
        Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        return true
    end
end

function isVehiclePlateAvailable()
    if vRPHandler.is_vehicle_plate_available == nil then
        local available = false
        local rows = FXServer:getAdditionalData('MySQL').asyncQuery("vRP/sqdz_connector_get_vehicles_columns", {})
        for k, v in pairs(rows) do
            if v['Field'] == 'vehicle_plate' then
                available = true
                break
            end
        end
        vRPHandler.is_vehicle_plate_available = available
        return available
    else
        return vRPHandler.is_vehicle_plate_available
    end
end

---
--- Vehicles End
---

---
--- Groups Begin
---

function vRPHandler:getGroups(user_id)
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        local groupsData = FXServer:getFrameworkAPI().getUserGroups({ user_id });
        local groups = {}

        for k, v in pairs(groupsData) do
            if (v == true) then
                table.insert(groups, k)
            end
        end

        return groups
    end
end

function vRPHandler:addGroup(user_id, group)
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        FXServer:getFrameworkAPI().addUserGroup({ user_id, group })
        Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        return true
    end
end

function vRPHandler:removeGroup(user_id, group)
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        FXServer:getFrameworkAPI().removeUserGroup({ user_id, group })
        Socket:broadcast('update_player_info', { user_id = user_id, data = FXServer:getHandler():getPlayerInfo(user_id) })
        return true
    end
end

---
--- Groups End
---

function vRPHandler:message(user_id, message, color)
    local playerSource = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (playerSource ~= nil) then
        GlobalHandler:sendMessage(playerSource, message, color)
    end
    return true
end

function vRPHandler:revive(user_id)
    local playerSource = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (playerSource ~= nil) then
        GlobalHandler:revive(playerSource)
        return true
    end
end

function vRPHandler:kick(user_id, reason)
    if reason == nil then
        reason = 'No reason'
    end

    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        FXServer:getFrameworkAPI().kick({ player, reason })
        return true
    end
end

function vRPHandler:getBans(page)
    local bansData = FXServer:getAdditionalData('MySQL').asyncQuery("vRP/sqdz_connector_get_bans", {})
    local bans = {}

    for _, v in pairs(bansData) do
        table.insert(bans, {
            user_id = v['id'],
            expire = v['bantime'],
            bannedby = v['banadmin'],
            reason = v['banreason']
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

    return response
end

function vRPHandler:ban(user_id, time, reason, bannedBy)
    if reason == nil then
        reason = 'No reason'
    end

    local banTime = os.time()

    if tonumber(time) then
        banTime = banTime + tonumber(time)
    else
        banTime = 'perm'
    end

    FXServer:getFrameworkAPI().setBanned({ user_id, true, banTime, reason, bannedBy })
    local player = FXServer:getFrameworkAPI().getUserSource({ user_id })
    if (player ~= nil) then
        self:kick(user_id, reason)
    end
    Socket:broadcast('update_bans', {})
    return true
end

function vRPHandler:unban(user_id)
    FXServer:getFrameworkAPI().setBanned({ user_id, false })
    Socket:broadcast('update_bans', {})
    return true
end

function vRPHandler:alertMessage(message, color)
    GlobalHandler:sendMessage(-1, message, color)
    return true
end

function vRPHandler:licenseToPlayerId(license)
    local users = FXServer:getFrameworkAPI().getUsers()
    local id = nil

    for userid, src in pairs(users) do
        for _, v in pairs(GetPlayerIdentifiers(src)) do
            if string.sub(v, 1, string.len("license:")) == "license:" then
                if license == v:gsub("license:", "") then
                    id = userid;
                    break
                end
            end
        end
    end

    return id
end