-- resources/[thegreatwar]/thegreatwar-core/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'YourName'
description 'The Great War - Match-Based Warfare System for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js'
}

dependencies {
    'qb-core',
    'qb-hud',
    'qb-menu',
    'qb-inventory',
    'qb-weapons',
    'qb-target',
    'oxmysql'
}