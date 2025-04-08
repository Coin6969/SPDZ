Log = {}

welcomeScreen = "   _____           __         ______                            __\n  / ___/____ _____/ /___     / ____/___  ____  ____  ___  _____/ /_____  _____\n  \\__ \\/ __ `/ __  /_  /    / /   / __ \\/ __ \\/ __ \\/ _ \\/ ___/ __/ __ \\/ ___/\n ___/ / /_/ / /_/ / / /_   / /___/ /_/ / / / / / / /  __/ /__/ /_/ /_/ / /    \n/____/\\__, /\\__,_/ /___/   \\____/\\____/_/ /_/_/ /_/\\___/\\___/\\__/\\____/_/     \n        /_/";
colors = {
    black = 30,
    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    white = 37,
    reset = 0,
}

function Log:printWelcome(version)
    border = "_______________________________________________________________________________"
    print(border .. '\n' .. welcomeScreen .. Log:color('cyan') .. '  v' .. version .. Log:color('reset') .. '  -  https://sqdz.me/' .. '\n' .. border)
    print('Sqdz Connector is starting.. Please wait.')
end

function Log:print(message)
    print(message)
end

function Log:success(message)
    print(Log:color('green') .. message .. Log:color('reset'))
end

function Log:error(message)
    print(Log:color('red') .. message .. Log:color('reset'))
end

function Log:color(color)
    return '\27[' .. colors[color] .. 'm'
end