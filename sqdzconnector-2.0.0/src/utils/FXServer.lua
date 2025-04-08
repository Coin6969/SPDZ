FXServer = {}

serverFrameworkType = nil;
frameworkTable = nil;
additionalData = {}

function FXServer:getFramework()
    local Proxy = module("vrp", "lib/Proxy")

    if (serverFrameworkType ~= nil) then
        return serverFrameworkType
    end

    if Proxy ~= nil then
        local vRP = Proxy.getInterface("vRP")
        local MySQL = module("vrp_mysql", "MySQL")
        if (type(MySQL.asyncQuery) == 'nil') then
            MySQL.asyncQuery = function(name, data)
                local p = promise.new()
                MySQL.query(name, data,function(result)
                    p:resolve(result)
                end)

                return Citizen.Await(p)
            end
        end
        additionalData['MySQL'] = MySQL;

        serverFrameworkType = 'vRP';
        frameworkTable = vRP;

        self:getHandler():setup()
        return serverFrameworkType;
    end

    local customExportQBCore = Config:get('qbcore.custom_export_core_name', 'qb-core')
    local QBCore = exports[customExportQBCore]

    local val, err = pcall(function()
        QBCore.GetCoreObject()
    end)
    if (err) then
        QBCore = nil;
    else
        QBCore = val;
    end

    if QBCore ~= nil then
        local oxmysql = self:checkForOXMySQL()
        if (oxmysql) then
            serverFrameworkType = 'QBCore';
            frameworkTable = exports[customExportQBCore]:GetCoreObject();
            return serverFrameworkType;
        end
    end

    local customQBCore = Config:get('qbcore.custom_resource_name', nil)
    local customQBCoreObject = Config:get('qbcore.custom_resource_object', 'QBCore')
    if (customQBCore ~= nil and GetResourceState(customQBCore)) then
        local oxmysql = self:checkForOXMySQL()
        if (oxmysql) then
            local d = promise.new()
            TriggerEvent(customQBCoreObject .. ':GetObject', function(obj)
                QBCore = obj
                serverFrameworkType = 'QBCore';
                frameworkTable = QBCore;

                return d:resolve(serverFrameworkType)
            end)

            return Citizen.Await(d)
        end
    end

    return nil;
end

function FXServer:getHandler()
    if (serverFrameworkType == 'vRP') then
        return vRPHandler
    elseif (serverFrameworkType == 'QBCore') then
        return QBCoreHandler
    end
end

function FXServer:getFrameworkAPI()
    return frameworkTable
end

function FXServer:getAdditionalData(key)
    return additionalData[key];
end

function FXServer:checkForOXMySQL()
    local ghmattimysql = Config:get('qbcore.ghmattimysql', false)
    if (ghmattimysql == false and GetResourceState('oxmysql') == 'missing') then
        Log:error("It seems that your server doesn't have 'oxmysql', if you want to use ghmattimysql instead, please set 'qbcore.ghmattimysql' to 'true' in your config.json")
        return nil;
    end
    return true;
end