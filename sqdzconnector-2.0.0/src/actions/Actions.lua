Actions = {}
Actions.pendingIds = {}

function Actions:execute(data)
    Log:print('Executing actions for player with license (' .. data['license'] .. ')')
    local user_id = FXServer:getHandler():licenseToPlayerId(data['license']);
    local executedList = {}

    if user_id ~= nil then
        local actions = data['actions']
        for _, actionData in pairs(actions) do
            local exe = Actions:executeAction(user_id, actionData)
            if exe ~= false then
                local id = exe[2]
                if id ~= nil then
                    executedList[#executedList + 1] = id
                end
            end
        end

        TriggerEvent('action_execution_succeeded', executedList)
    else
        Log:print('Player with license (' .. data['license'] .. ') does not have a user id, execution abandoned.')
    end
end

function Actions:executeAction(user_id, data)
    local id = data['id'];
    if (Actions.pendingIds[id] == nil) then
        Actions.pendingIds[id] = true;

        local name = data['name'];
        local values = data['values'];
        local executed = false

        if name == 'vrp_add_group' and FXServer:getFramework() == 'vRP' then
            executed = FXServer:getHandler():addGroup(user_id, values['group_name'])
        elseif name == 'vrp_remove_group' and FXServer:getFramework() == 'vRP' then
            executed = FXServer:getHandler():removeGroup(user_id, values['group_name'])
        elseif name == 'qbcore_set_job' and FXServer:getFramework() == 'QBCore' then
            executed = FXServer:getHandler():setJob(user_id, values['job_name'], values['grade'])
        elseif name == 'add_money' then
            executed = FXServer:getHandler():giveMoney(user_id, tonumber(values['amount']), values['type'])
        elseif name == 'remove_money' then
            executed = FXServer:getHandler():removeMoney(user_id, tonumber(values['amount']), values['type'])
        elseif name == 'add_vehicle' then
            executed = FXServer:getHandler():giveVehicle(user_id, values['type'])
        elseif name == 'remove_vehicle' then
            if FXServer:getFramework() == 'vRP' then
                executed = FXServer:getHandler():removeVehicle(user_id, values['type'])
            elseif FXServer:getFramework() == 'QBCore' then
                executed = FXServer:getHandler():removeVehicleByModel(user_id, values['type'])
            end
        end

        Actions.pendingIds[id] = nil

        if (executed ~= true) then
            executed = false
        end

        return { executed, id }
    else
        Log:print('Action with id (' .. id .. ') is already under execution, execution abandoned.')
    end

    return false
end

AddEventHandler('actions_transfer', function(data)
    Actions:execute(data['data'])
end)