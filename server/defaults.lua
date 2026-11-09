--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Default config. config.example.lua MUST list the same values: tests/server.lua compares them.

---A fresh copy of the defaults.
---@return table
function UgTemplate.Internal.Defaults()
    return {
        interactKey = 'E',
        distance = 2.0,
        cooldown = 600000,
        account = 'cash',
        points = {
            { label = 'Legion Square stash', coords = vector3(195.17, -933.77, 30.69), amount = 250 },
            { label = 'Pier stash', coords = vector3(-1604.66, -1048.83, 13.02), amount = 500 },
        },
    }
end
