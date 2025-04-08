SqdzConnector = {}

function SqdzConnector:startup()
    Log:printWelcome(GetResourceMetadata('sqdzconnector', 'version'))

    local configStatus = Config:load()
    if (configStatus ~= true) then
        return
    end

    local framework = FXServer:getFramework()
    if (framework == nil) then
        Log:error('No framework has been found in this FXServer, currently supported frameworks are: vRP, QBCore')
        return
    end
    Log:print('The framework of this server has been found successfully. (' .. Log:color('green') .. framework .. Log:color('reset') .. ')')
    FXServer:getHandler():startListener()
    Log:print('Events has been listened successfully.')

    Log:print('Registering commands...')
    TebexStoreCommand:register()

    TriggerEvent('socket_startup', Config:get('node_url'), Config:get('token'), framework, GetResourceMetadata('sqdzconnector', 'version'))
end