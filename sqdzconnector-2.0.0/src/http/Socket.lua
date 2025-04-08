Socket = {}

function Socket:broadcast(name, data)
    TriggerEvent('socket_payload_out_client', name, data)
end