-- resources/[thegreatwar]/thegreatwar-core/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TheGreatWar'
description 'The Great War - Match-Based Warfare System for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/functions.lua'
}

client_scripts {
    'client/main.lua',
    'client/zones.lua',
    'client/respawn.lua',
    'client/durability.lua',
    'client/voice.lua',
    'client/character_override.lua',
    'client/force_join.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/startup.lua',
    'server/main.lua',
    'server/combat.lua',
    'server/statistics.lua',
    'server/roles.lua',
    'server/economy.lua',
    'server/crews.lua',
    'server/zones.lua',
    'server/anticheat.lua',
    'server/durability.lua',
    'server/disable_rp.lua',
    'server/override_qb.lua'
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
    'qb-menu',
    'qb-input',
    'qb-target',
    'qb-radio',
    'pma-voice',
    'oxmysql'
}

-- Override other resources to load gamemode first
before 'qb-multicharacter'
before 'qb-spawn'
before 'qb-hud'
before 'qb-inventory'
before 'qb-weapons'

-- Load after core essentials
after 'qb-core'
after 'oxmysql'