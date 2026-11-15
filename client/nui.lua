--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- The page bridge. The page is untrusted: any script in CEF can post to these callbacks, so every body is
-- read through a schema here before a handler sees it, and the page MAY post only so often.

---@class UgTemplate.Internal.Nui
local Nui = {}
UgTemplate.Internal.Nui = Nui

local Enums = UgTemplate.Enums
local Action = Enums.NuiAction
local Callback = Enums.NuiCallback
local Schema = UgCore.Schema

local RESOURCE = GetCurrentResourceName()
-- Callbacks per second the page MAY send. Raise it for pages with sliders or drag, and throttle in the page too.
local EVENTS_PER_SECOND = 10
local FALLBACK_LOCALE = 'en'

local ready = false
---@type table[] messages sent before the page was ready
local queue = {}
local budget = {
    second = -1,
    count = 0,
}
---@type table<UgTemplateNuiCallback, fun(value: any)>
local handlers = {}

---Sends a message, or queues it until the page is ready.
---@param action UgTemplateNuiAction
---@param payload? table
function Nui.Send(action, payload)
    local message = {
        action = action,
        payload = payload,
    }

    if ready then
        SendNUIMessage(message)
    else
        queue[#queue + 1] = message
    end
end

---The `page` group of locales/<code>.json, or of English when that file is missing or broken.
---@return table
function Nui.Labels()
    for _, code in ipairs({ UgLib.Locale.GetCode(), FALLBACK_LOCALE }) do
        local content = LoadResourceFile(RESOURCE, ('locales/%s.json'):format(code))

        if content then
            local ok, decoded = pcall(json.decode, content)

            if ok and type(decoded) == 'table' and type(decoded.page) == 'table' then
                return decoded.page
            end
        end
    end

    return {}
end

---ug-lib's theme with the owner's ug-template theme on top, so every UgCore screen matches unless the owner says
---otherwise. Colors merge token by token; the other fields take the owner value when set.
---@param base table? ug-lib's theme
---@param own table? this resource's theme
---@return table
function Nui.Theme(base, own)
    base = type(base) == 'table' and base or {}
    own = type(own) == 'table' and own or {}

    local colors = {}

    -- Not ipairs over both: it stops at a missing ug-lib table and drops the owner colors.
    for index = 1, 2 do
        local source = index == 1 and base.colors or own.colors

        if type(source) == 'table' then
            for token, color in pairs(source) do
                colors[token] = color
            end
        end
    end

    return {
        mode = own.mode or base.mode,
        colors = colors,
        radius = own.radius or base.radius,
        font = own.font or base.font,
        scale = own.scale or base.scale,
    }
end

---What the page gets first: the theme, the labels, and the owner's layout and features.
---@return table
local function config()
    local libConfig = GlobalState[UgLib.Enums.GlobalState.Config]
    local owner = GlobalState['ug-template:Config']

    owner = type(owner) == 'table' and owner or {}

    return {
        theme = Nui.Theme(type(libConfig) == 'table' and libConfig.theme or nil, owner.theme),
        labels = Nui.Labels(),
        locale = UgLib.Locale.GetCode(),
        layout = owner.layout,
        features = owner.features,
    }
end

---Sets who receives a page callback. The handler gets the validated value.
---@param callback UgTemplateNuiCallback
---@param handler fun(value: any)
function Nui.On(callback, handler)
    handlers[callback] = handler
end

---@return boolean
local function withinBudget()
    local second = GetGameTimer() // 1000

    if budget.second ~= second then
        budget.second, budget.count = second, 0
    end

    budget.count = budget.count + 1

    return budget.count <= EVENTS_PER_SECOND
end

---A reader that checks one field of the body with a rule.
---@param field string
---@param rule UgSchemaRule
---@return fun(body: any): any
local function fieldOf(field, rule)
    return function(body)
        if type(body) ~= 'table' then
            return nil
        end

        local ok, value = Schema.Check(rule, body[field])

        return ok and value or nil
    end
end

-- One reader per callback. A reader returns the checked value, or nil to reject the body.
---@type table<UgTemplateNuiCallback, fun(body: any): any>
local READERS = {
    [Callback.Claim] = fieldOf('point', Schema.Integer({
        min = 1,
        max = 64,
    })),
    [Callback.Close] = function()
        return true
    end,
}

for name, read in pairs(READERS) do
    RegisterNUICallback(name, function(body, cb)
        local value = nil

        if withinBudget() then
            value = read(body)
        end

        if value ~= nil and handlers[name] then
            handlers[name](value)
        end

        cb({
            ok = value ~= nil,
        })
    end)
end

-- The page posts ready once it listens. It reloads after a crash: config is sent again each time.
RegisterNUICallback(Callback.Ready, function(_, cb)
    ready = true
    SendNUIMessage({
        action = Action.Config,
        payload = config(),
    })

    for _, message in ipairs(queue) do
        SendNUIMessage(message)
    end

    queue = {}
    cb({
        ok = true,
    })
end)
