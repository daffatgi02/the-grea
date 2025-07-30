-- resources/[thegreatwar]/thegreatwar-loot/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TheGreatWar'
description 'The Great War - Loot System'
version '1.0.0'

shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}