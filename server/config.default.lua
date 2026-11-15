--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- ug-template config. Copied to config.lua in the resource folder on the first start: edit that file, never this one.
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
        {
            label = 'Legion Square stash',
            coords = vector3(195.17, -933.77, 30.69),
            amount = 250,
        },
        {
            label = 'Pier stash',
            coords = vector3(-1604.66, -1048.83, 13.02),
            amount = 500,
        },
    },

    -- Colors, radius, font and scale of the panel, over ug-lib's theme: { mode?, colors?, radius?, font?, scale? }.
    -- colors takes ug-lib's tokens as HSL triplets: theme = { colors = { primary = '200 80% 55%' } }.
    theme = {},

    -- The panel. Keys you leave out keep their default.
    -- position: 'top-left', 'top-right', 'bottom-left' or 'bottom-right'. width: in rem.
    -- animations = false shows and hides the panel at once.
    layout = {
        position = 'bottom-right',
        width = 20,
        animations = true,
    },

    -- prompt: the key prompt near a point. countdown: the time left before the next claim.
    features = {
        prompt = true,
        countdown = true,
    },

    -- Game sounds: claim (paid), error (refused). { name, set }. A sound left out is silent.
    soundEffects = {
        claim = {
            name = 'PURCHASE',
            set = 'HUD_LIQUOR_STORE_SOUNDSET',
        },
        error = {
            name = 'ERROR',
            set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        },
    },
}
