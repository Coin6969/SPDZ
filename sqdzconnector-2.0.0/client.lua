RegisterNetEvent('sqdzconnector:heal', function()
    SetEntityHealth(GetPlayerPed(-1), GetEntityMaxHealth(GetPlayerPed(-1)))
    ClearPedBloodDamage(GetPlayerPed(-1))
end)

local openButton = 'F7'

RegisterKeyMapping('web', 'Keybind to open website', 'keyboard', openButton)

RegisterCommand('web', function()
    TriggerServerEvent('sqdzconnector:open:website')
end)

RegisterNetEvent('sqdzconnector:open:website:data', function(data)
    SendNUIMessage({
        status = "open",
        data = data,
        closeButton = openButton,
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('close_website', function()
    SetNuiFocus(false, false)
end)