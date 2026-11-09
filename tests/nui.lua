--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Contracts between Lua, the page and the locales. They break silently on a live server, so they are tested here.

local H = dofile('tests/helpers.lua')

---@param path string
---@return string
local function read(path)
    return assert(LoadResourceFile('ug-template', path), 'missing ' .. path)
end

---Values of `export const <name> = { Key: "value", ... }` in protocol.ts.
---@param source string
---@param name string
---@return table<string, string>
local function tsEnum(source, name)
    local body = assert(source:match('export const ' .. name .. ' = (%b{})'), 'no enum ' .. name)
    local values = {}

    for key, value in body:gmatch('(%w+):%s*"([^"]+)"') do
        values[key] = value
    end

    return values
end

---Dotted keys of a decoded locale.
---@param group table
---@param prefix? string
---@param keys? table<string, boolean>
---@return table<string, boolean>
local function keysOf(group, prefix, keys)
    keys = keys or {}

    for key, value in pairs(group) do
        local path = (prefix or '') .. key

        if type(value) == 'table' then
            keysOf(value, path .. '.', keys)
        else
            keys[path] = true
        end
    end

    return keys
end

print('nui')

H.Test('page enums match shared/enums.lua and ug-core', function()
    H.Reset()
    H.Load('server')

    local protocol = read('web/src/types/protocol.ts')

    for _, name in ipairs({ 'NuiAction', 'NuiCallback' }) do
        H.Equal(tsEnum(protocol, name), UgTemplate.Enums[name], name)
    end

    H.Equal(tsEnum(protocol, 'ErrorCode'), UgCore.Enums.Errors, 'ErrorCode')
end)

H.Test('every locale has the same keys as English, and every error code has a text', function()
    local english = json.decode(read('locales/en.json'))

    for _, code in ipairs({ 'pt' }) do
        H.Equal(keysOf(json.decode(read(('locales/%s.json'):format(code)))), keysOf(english), code)
    end

    H.Reset()
    H.Load('server')

    for _, value in pairs(UgCore.Enums.Errors) do
        H.Assert(english.page.error[value], 'no text for ' .. value)
    end
end)

H.Test('the page gets English labels when the locale is broken', function()
    H.Reset()
    H.Files['locales/en.json'] = '{"page":{"x":"English"}}'
    H.LoadClient()
    H.Locale = 'pt'
    H.Files['locales/pt.json'] = '{"page":'

    H.Equal(UgTemplate.Internal.Nui.Labels(), { x = 'English' })

    H.Files['locales/pt.json'] = '{"page":{"x":"Português"}}'
    H.Equal(UgTemplate.Internal.Nui.Labels(), { x = 'Português' })
end)

H.Test('messages wait for the page', function()
    H.Reset()
    H.Defaults()
    GlobalState['ug-template:Config'] = H.Defaults()
    H.Load('client')

    UgTemplate.Internal.Nui.Send('result', { ok = true })
    H.Equal(#H.PageMessages(), 0)

    H.PostNui('ready', {})

    local actions = {}

    for _, message in ipairs(H.PageMessages()) do
        actions[#actions + 1] = message.action
    end

    H.Equal(actions, { 'config', 'result' })
end)

H.Done()
