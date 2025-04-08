class RoutesController {
    static getList = [];
    static postList = [];

    get(url, cb) {
        RoutesController.getList[url] = cb;
    }

    post(url, cb) {
        RoutesController.postList[url] = cb;
    }

    async getCallbackResponse(cbList, url, packetId, data) {
        let response;
        if (cbList[url] != null) {
            let res = await cbList[url](packetId, data);
            if (res != null) {
                response = {status: 200, data: res};
            } else {
                response = {status: 400, data: res};
            }
        }
        return response;
    }

    async execute(socket, packetId, data) {
        if (data.method != null && data.url != null) {
            let response = {status: 404};
            if (data.method === 'get') {
                let callbackResponse = await this.getCallbackResponse(RoutesController.getList, data.url, packetId, data.data);
                if (callbackResponse) {
                    response = callbackResponse;
                }
            } else if (data.method === 'post') {
                let callbackResponse = await this.getCallbackResponse(RoutesController.postList, data.url, packetId, data.data);
                if (callbackResponse) {
                    response = callbackResponse;
                }
            }

            this.reply(socket, packetId, response)
        } else {
            return false;
        }
    }

    async reply(socket, packetId, data) {
        socket.emit('packet_out_reply', {
            packetId: packetId,
            ...data
        });
    }
}

module.exports = RoutesController;