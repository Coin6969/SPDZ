
class ActionsTransfer {
    static transfer(data) {
        emit('actions_transfer', {
            data
        })
    }

    static sendExecutedActions(socket, actions) {
        socket.emit('action_execution_succeeded', {
            list: actions
        });
    }
}
module.exports = ActionsTransfer;