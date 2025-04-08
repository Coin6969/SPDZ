const Validator = require('../../../../libs/validator.min')

class Transfer {
    static requests = {};

    static async transfer(packetId, event, data = {}, validation = {}) {
        const v = new Validator(data, validation);
        if (v.passes()) {
            let promise = new Promise((resolve) => {
                Transfer.requests[packetId] = resolve;
            });

            emit('http_request', {
                'packet_id': packetId,
                event,
                data
            })
            return promise;
        } else {
            console.error('Data validation failed. This is not expected! (' + JSON.stringify(v.errors()) + ')')
        }
    }

    static response(res) {
        Transfer.requests[res['packet_id']](res['data']);
        delete Transfer.requests[res['packet_id']];
    }
}
module.exports = Transfer;