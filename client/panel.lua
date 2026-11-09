--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- The claim panel: opens the page at a point, asks the server, shows its answer. The server decides everything.

---@class UgTemplate.Internal.Panel
local Panel = {}
UgTemplate.Internal.Panel = Panel

local Nui = UgTemplate.Internal.Nui
local Enums = UgTemplate.Enums
local Action = Enums.NuiAction
local Errors = UgCore.Enums.Errors

local RESOURCE = GetCurrentResourceName()

---@type integer? point index while the panel is open
local openIndex = nil
local busy = false

---@param name UgTemplateCallback
---@param ... any
---@return UgTemplateClaimResult
local function ask(name, ...)
    local ok, value, errorCode = UgCore.Callback.Await(('%s:%s'):format(RESOURCE, name), ...)

    if not ok or type(value) ~= 'table' then
        return { ok = false, error = errorCode or Errors.InternalError }
    end

    return value
end

---@return boolean
function Panel.IsOpen()
    return openIndex ~= nil
end

---Opens the panel for a point. Runs in its own thread: the status comes from the server.
---@param index integer
function Panel.Open(index)
    if openIndex or busy then
        return
    end

    local point = GlobalState['ug-template:Config'].points[index]

    if not point then
        return
    end

    busy = true

    CreateThread(function()
        local status = ask(Enums.Callbacks.Status, index)

        busy = false

        if not status.ok then
            return
        end

        openIndex = index
        Nui.Send(Action.Open, { point = index, label = point.label, amount = status.amount, waitMs = status.waitMs })
        SetNuiFocus(true, true)
    end)
end

function Panel.Close()
    if not openIndex then
        return
    end

    openIndex = nil
    SetNuiFocus(false, false)
    Nui.Send(Action.Close)
end

---Claims the open point. The page names the point, so a forged body for another point is ignored.
---@param index integer
function Panel.Claim(index)
    if index ~= openIndex or busy then
        return
    end

    busy = true

    CreateThread(function()
        local result = ask(Enums.Callbacks.Claim, index)

        busy = false
        Nui.Send(Action.Result, { ok = result.ok == true, error = result.error, amount = result.amount, waitMs = result.waitMs })
    end)
end

Nui.On(Enums.NuiCallback.Claim, Panel.Claim)
Nui.On(Enums.NuiCallback.Close, Panel.Close)

AddEventHandler('onResourceStop', function(resource)
    if resource == RESOURCE and openIndex then
        SetNuiFocus(false, false)
    end
end)
