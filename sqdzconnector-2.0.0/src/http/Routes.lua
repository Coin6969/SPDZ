Routes = {}

function Routes:transfer(req, data)
    local rep = {
        packet_id = req['packet_id'],
        data = ''
    }
    if (data ~= nil and data ~= true) then
        rep['data'] = data
    end

    TriggerEvent('http_response', rep)
end

AddEventHandler('http_request', function(req)
    local data = req['data'];

    if (FXServer:getFramework() == 'vRP') then
        if (data['user_id'] ~= nil) then
            data['user_id'] = tonumber(data['user_id'])
        end
    end

    -- vRP & QBCore - Begin
    if (req['event'] == 'players') then
        return Routes:transfer(req, FXServer:getHandler():getPlayers())
    elseif (req['event'] == 'players.info') then
        return Routes:transfer(req, FXServer:getHandler():getPlayerInfo(data['user_id']))
    elseif (req['event'] == 'players.money') then
        return Routes:transfer(req, FXServer:getHandler():getMoney(data['user_id']))
    elseif (req['event'] == 'players.giveMoney') then
        return Routes:transfer(req, FXServer:getHandler():giveMoney(data['user_id'], tonumber(data['amount']), data['type']))
    elseif (req['event'] == 'players.removeMoney') then
        return Routes:transfer(req, FXServer:getHandler():removeMoney(data['user_id'], tonumber(data['amount']), data['type']))
    elseif (req['event'] == 'players.vehicles') then
        return Routes:transfer(req, FXServer:getHandler():getVehicles(data['user_id']))
    elseif (req['event'] == 'players.giveVehicle') then
        return Routes:transfer(req, FXServer:getHandler():giveVehicle(data['user_id'], data['type']))
    elseif (req['event'] == 'players.message') then
        return Routes:transfer(req, FXServer:getHandler():message(data['user_id'], data['message'], data['color']))
    elseif (req['event'] == 'players.revive') then
        return Routes:transfer(req, FXServer:getHandler():revive(data['user_id']))
    elseif (req['event'] == 'players.kick') then
        return Routes:transfer(req, FXServer:getHandler():kick(data['user_id'], data['reason']))
    elseif (req['event'] == 'bans') then
        return Routes:transfer(req, FXServer:getHandler():getBans(tonumber(data['page'])))
    elseif (req['event'] == 'alert.message') then
        return Routes:transfer(req, FXServer:getHandler():alertMessage(data['message'], data['color']))
    end
    -- vRP & QBCore - End

    --
    -- vRP - Begin
    --
    if (FXServer:getFramework() == 'vRP') then
        if (req['event'] == 'players.removeVehicle') then
            return Routes:transfer(req, FXServer:getHandler():removeVehicle(data['user_id'], data['type']))
        elseif (req['event'] == 'players.groups') then
            return Routes:transfer(req, FXServer:getHandler():getGroups(data['user_id']))
        elseif (req['event'] == 'players.addGroup') then
            return Routes:transfer(req, FXServer:getHandler():addGroup(data['user_id'], data['group']))
        elseif (req['event'] == 'players.removeGroup') then
            return Routes:transfer(req, FXServer:getHandler():removeGroup(data['user_id'], data['group']))
        elseif (req['event'] == 'players.ban') then
            return Routes:transfer(req, FXServer:getHandler():ban(data['user_id'], data['time'], data['reason'], data['banned_by']))
        elseif (req['event'] == 'players.unban') then
            return Routes:transfer(req, FXServer:getHandler():unban(data['user_id']))
        end
        --
        -- vRP - End
        --

        --
        -- QBCore - Begin
        --
    elseif (FXServer:getFramework() == 'QBCore') then
        if (req['event'] == 'players.removeVehicle') then
            return Routes:transfer(req, FXServer:getHandler():removeVehicle(data['user_id'], data['id']))
        elseif (req['event'] == 'players.setJob') then
            return Routes:transfer(req, FXServer:getHandler():setJob(data['user_id'], data['job'], data['grade']))
        elseif (req['event'] == 'players.ban') then
            return Routes:transfer(req, FXServer:getHandler():ban(data['license'], data['name'], data['time'], data['reason'], data['banned_by']))
        elseif (req['event'] == 'players.unban') then
            return Routes:transfer(req, FXServer:getHandler():unban(tonumber(data['id'])))
        elseif (req['event'] == 'players.kick.source') then
            return Routes:transfer(req, FXServer:getHandler():kickSource(tonumber(data['source']), data['reason']))
        end
    end
    --
    -- QBCore - End
    --
end)