-- resources/[thegreatwar]/thegreatwar-core/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TheGreatWar'
description 'The Great War - Complete Phase 1 Implementation'
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
    'server/resource_manager.lua',
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

ui_pages {
    'html/index.html',
    'html/champion-hud.html',
    'html/voting-interface.html',
    'html/session-timer.html',
    'html/killstreak-notify.html'
}

files {
    'html/*.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/*.png',
    'html/assets/*.jpg',
    'config.json',
    'resource_config.json'
}

dependencies {
    'qb-core',
    'qb-menu',
    'qb-input',
    'qb-target',
    'qb-radio',
    'pma-voice',
    'oxmysql',
    'thegreatwar-ui',
    'thegreatwar-combat',
    'thegreatwar-loot'
}

-- Load order
before 'qb-multicharacter'
before 'qb-spawn'
before 'qb-hud'
before 'qb-inventory'
before 'qb-weapons'

after 'qb-core'
after 'oxmysql'