TebexStoreCommand = {}

function TebexStoreCommand:register()
    RegisterCommand("sqdzconnector", function(_, args)
        if (#args == 4) then
            if (args[1] == 'tebex' and args[2] == 'execute') then
                local actionId = args[3]
                local cfxId = args[4]

                Log:print("Executing action (" .. actionId .. ") to player (" .. cfxId .. ")")
                PerformHttpRequest(Config:get('api_url') .. '/store/tebex/actions', function(status)
                    if (status == 200) then
                        Log:print("Action (" .. actionId .. ") has been successfully executed to player (" .. cfxId .. ")")
                    else
                        Log:print("There was an error while executing action (" .. actionId .. ") to player (" .. cfxId .. ")")
                    end
                end, 'POST', json.encode({ action_id = actionId, player_cfx_id = cfxId }), { ['Authorization'] = 'FXServer ' .. Config:get('token'), ['Content-Type'] = 'application/json' })
            end
        end
    end, true)
end