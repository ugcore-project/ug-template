--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- ug-template config. Copied to config.lua on the first start: edit config.lua, never this file.
-- Updates never overwrite config.lua. A key you remove uses its default.

return {
    -- Key that opens the panel at a point. Players MAY change it in the game's key bindings.
    interactKey = 'E',

    -- How close, in meters, a player MUST stand to a point. The server checks it too.
    distance = 2.0,

    -- Time between two claims of the same character, in milliseconds.
    cooldown = 600000,

    -- ug-core account the reward is paid into.
    account = 'cash',

    -- Points players claim a reward at. At most 64.
    points = {
        { label = 'Legion Square stash', coords = vector3(195.17, -933.77, 30.69), amount = 250 },
        { label = 'Pier stash', coords = vector3(-1604.66, -1048.83, 13.02), amount = 500 },
    },
}
