-- resources/[thegreatwar]/thegreatwar-ui/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TheGreatWar'
description 'The Great War - UI System'
version '1.0.0'

shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_pages {
    'html/champion-hud.html',
    'html/voting-interface.html',
    'html/session-timer.html',
    'html/killstreak-notify.html',
    'html/zone-indicators.html'
}

files {
    'html/*.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/*.png',
    'html/assets/*.jpg'
}