const routes = new (require('./controllers/routesController'))();
const Transfer = require('./transfer/transfer');

routes.get('/players', async function (packetId) {
    return await Transfer.transfer(packetId, 'players');
});
routes.get('/players/info', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.info', data, {user_id: 'required'});
});

routes.get('/players/money', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.money', data, {user_id: 'required'});
});
routes.post('/players/giveMoney', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.giveMoney', data, {
        user_id: 'required',
        amount: 'required|integer',
        type: 'required'
    });
});
routes.post('/players/removeMoney', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.removeMoney', data, {
        user_id: 'required',
        amount: 'required|integer',
        type: 'required'
    });
});

routes.get('/players/vehicles', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.vehicles', data, {user_id: 'required'});
});
routes.post('/players/giveVehicle', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.giveVehicle', data, {user_id: 'required', type: 'required'});
});
routes.post('/players/removeVehicle', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.removeVehicle', data, validateServerType({
        vRP: {
            user_id: 'required',
            type: 'required'
        }, QBCore: {user_id: 'required', id: 'required|integer'}
    }));
});

/*
 * vRP ONLY
 */
routes.get('/players/groups', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.groups', data, {user_id: 'required'});
});
routes.post('/players/addGroup', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.addGroup', data, {user_id: 'required', group: 'required'});
});
routes.post('/players/removeGroup', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.removeGroup', data, {user_id: 'required', group: 'required'});
});
/*
 * vRP ONLY
 */

/*
 * QBCore ONLY
 */
routes.post('/players/setJob', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.setJob', data, {
        user_id: 'required',
        job: 'required',
        grade: 'present'
    });
});
routes.post('/players/kick/source', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.kick.source', data, {
        source: 'required|integer',
        reason: 'required|max:512'
    });
});
/*
 * QBCore ONLY
 */

routes.post('/players/message', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.message', data, {
        user_id: 'required',
        message: 'required|max:512',
        color: 'required|array|min:3|max:3'
    });
});

routes.post('/players/revive', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.revive', data, {user_id: 'required'});
});

routes.post('/players/kick', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.kick', data, {user_id: 'required', reason: 'present|max:512'});
});

routes.post('/players/ban', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.ban', data, validateServerType({
        vRP: {
            user_id: 'required',
            time: 'required',
            reason: 'present|max:512',
            banned_by: 'required'
        },
        QBCore: {
            license: 'required',
            name: 'required',
            time: 'required',
            reason: 'present|max:512',
            banned_by: 'required'
        }
    }));
});
routes.post('/players/unban', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'players.unban', data, validateServerType({
        vRP: {user_id: 'required'},
        QBCore: {id: 'required|integer'}
    }));
});

routes.get('/bans', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'bans', data, {page: 'required|integer'});
});

routes.post('/alert/message', async function (packetId, data) {
    return await Transfer.transfer(packetId, 'alert.message', data, {
        message: 'required|max:512',
        color: 'required|array|min:3|max:3'
    });
});


function validateServerType(rules) {
    return FXServerType != null ? rules[FXServerType] != null ? rules[FXServerType] : {} : {};
}