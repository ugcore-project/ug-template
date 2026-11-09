--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

---@diagnostic disable: undefined-global

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ug-template'
author 'UgCore Framework & Contributors'
version '1.0.0'
description 'Starting point for UgCore resources: config, secure callbacks, a NUI page and tests'
repository 'https://github.com/ugcore-project/ug-template'

ugcore_version '1.0.0'
uglib_version '1.0.0'

dependencies {
    '/onesync',
    'ug-core',
    'ug-lib',
}

shared_scripts {
    '@ug-core/import.lua',
    '@ug-lib/import.lua',
    'shared/init.lua',
    'shared/enums.lua',
}

server_scripts {
    'server/defaults.lua',
    'server/config.lua',
    'server/claims.lua',
    'server/boot.lua',
}

client_scripts {
    'client/nui.lua',
    'client/panel.lua',
    'client/points.lua',
    'client/boot.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/assets/*',
}
