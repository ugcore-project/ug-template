--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Last server script: waits for ug-core, loads config, then registers callbacks.

local Config = UgTemplate.Internal.Config
local Claims = UgTemplate.Internal.Claims
local Logger = UgCore.Logger

local RESOURCE = GetCurrentResourceName()
local READY_TIMEOUT = 60000

CreateThread(function()
    if not UgCore.Lifecycle.Await(UgCore.Enums.Lifecycle.Ready, READY_TIMEOUT) then
        Logger.Error('ug-core did not become ready. ug-template stays off.')

        return
    end

    local ok, errors = Config.Load()

    if not ok then
        for _, message in ipairs(errors) do
            Logger.Error(message)
        end

        Logger.Error('Config invalid: %d error(s). ug-template stays off.', #errors)

        return
    end

    if not UgCore.Modules.IsEnabled('accounts') then
        Logger.Error('ug-template needs the accounts module. Enable it in ug-core config/modules.lua.')

        return
    end

    Claims.Register()

    print(('[ug-template] v%s ready. %d point(s).'):format(GetResourceMetadata(RESOURCE, 'version', 0) or '?', #Config.Get().points))
end)
