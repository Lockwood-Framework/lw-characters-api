fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'lw-characters-api'
description 'Lockwood RP — Character identity, CRUD, slot management, and tombstone tracking'
version     '1.0.0'
author 'Morgrhim'

dependencies {
    'lw-db',
    'lw-shared',
    'lw-core',
}

server_scripts {
    'server/config.lua',
    'server/slots.lua',       -- GetSlotInfo, IsNameAvailable available to files below
    'server/characters.lua',  -- can call IsNameAvailable from slots.lua
    'server/tombstone.lua',
    'server/main.lua',        -- loads last, can call anything defined above
}