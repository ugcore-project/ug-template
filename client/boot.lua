--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Last client script: waits for the server config and ug-core, then creates the points.

local STATE_KEY = 'ug-template:Config'
local READY_TIMEOUT = 60000

CreateThread(function()
    local deadline = GetGameTimer() + READY_TIMEOUT

    while type(GlobalState[STATE_KEY]) ~= 'table' do
        if GetGameTimer() >= deadline then
            print('^1[ug-template] No config from the server. Check the server console.^7')

            return
        end

        Wait(250)
    end

    if not UgCore.Lifecycle.Await(UgCore.Enums.Lifecycle.Ready, READY_TIMEOUT) then
        print('^1[ug-template] ug-core did not become ready.^7')

        return
    end

    local settings = GlobalState[STATE_KEY] --[[@as table]]

    UgTemplate.Internal.Points.Create(settings)

    print(('[ug-template] Ready: %d point(s).'):format(#settings.points))
end)
