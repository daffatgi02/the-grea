-- resources/[thegreatwar]/thegreatwar-core/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'YourName'
description 'The Great War - Match-Based Warfare System for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
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
    'html/css/style.css',
    'html/js/main.js',
    'html/leaderboard.html',
    'config.json'
}

dependencies {
    'qb-core',
    'qb-hud',
    'qb-menu',
    'qb-inventory',
    'qb-weapons',
    'qb-target',
    'qb-radio',
    'oxmysql'
}