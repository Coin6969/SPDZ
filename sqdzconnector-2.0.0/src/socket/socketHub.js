global.XMLHttpRequest = require('./libs/xhr2.min');

require('./src/socket/base/routes.js')

const socketController = require('./src/socket/base/controllers/socketController');
const Transfer = require('./src/socket/base/transfer/transfer');
const ActionsTransfer = require('./src/socket/base/transfer/actionsTransfer');

on('socket_startup', (url, key, fxserver_type, version) => {
    global.FXServerType = fxserver_type;
    console.log('[Socket] Getting socket ready to connect to Node');
    socketController.startup(url, key, fxserver_type, version);
})

on('http_response', (res) => {
    Transfer.response(res);
})

on('action_execution_succeeded', (data) => {
    ActionsTransfer.sendExecutedActions(socketController.getSocket(), data);
})

on('socket_payload_out_client', (name, data) => {
    socketController.getSocket().emit('socket_payload_out_client', {name, data})
})