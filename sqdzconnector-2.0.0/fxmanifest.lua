fx_version 'cerulean'
games { 'gta5' }
ui_page 'html/index.html'

version '2.0.0'

client_scripts {
    'client.lua'
}

server_script {
    'src/utils/OXMySQL.lua',
    'src/utils/vRPProxy.lua',
    'src/utils/FXServer.lua',
    'src/utils/Log.lua',
    'src/utils/Chunks.lua',

    'src/commands/TebexStoreCommand.lua',

    -- Handler Scripts Begin --
    'src/handler/Global/Handler.lua',
    'src/handler/vRP/Handler.lua',
    'src/handler/QBCore/Handler.lua',
    -- Handler Scripts End --

    'src/actions/Actions.lua',
    'src/autologin/AutoLogin.lua',
    'src/http/Socket.lua',
    'src/http/Routes.lua',
    'src/SqdzConnector.lua',
    'src/config/Config.lua',

    'server.lua',

    'src/socket/base/controllers/socketController',
    'src/socket/socketHub.js',
}

files {
    'html/libs/vue.min.js',
    'html/index.html',
    'html/style.css',
}