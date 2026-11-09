--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Owner config: config.lua, copied from config.example.lua on the first start and never overwritten.
-- Owner values replace the defaults key by key. Clients get every value through GlobalState: never put secrets here.

---@class UgTemplate.Internal.Config
local Config = {}
UgTemplate.Internal.Config = Config

local Schema = UgCore.Schema

local RESOURCE = GetCurrentResourceName()
local OWNER_FILE = 'config.lua'
local EXAMPLE_FILE = 'config.example.lua'
local STATE_KEY = 'ug-template:Config'

Config.StateKey = STATE_KEY
Config.MaxPoints = 64

-- One rule per key. Every string, array and map is bounded.
---@type { key: string, rule: UgSchemaRule }[]
local RULES = {
    { key = 'interactKey', rule = Schema.String({ min = 1, max = 16, pattern = '^[%w_]+$' }) },
    { key = 'distance', rule = Schema.Number({ min = 0.5, max = 10 }) },
    { key = 'cooldown', rule = Schema.Integer({ min = 0, max = 86400000 }) },
    { key = 'account', rule = Schema.String({ min = 1, max = 32, pattern = '^%l[%w]*$' }) },
    {
        key = 'points',
        rule = Schema.Array(Schema.Object({
            label = Schema.String({ min = 1, max = 48 }),
            coords = Schema.Vector3({ maxComponent = 10000 }),
            amount = Schema.Integer({ min = 1, max = 1000000 }),
        }), { min = 1, max = Config.MaxPoints }),
    },
}

---Runs owner code in a sandbox with only what a config needs.
---@param content string
---@return boolean ok
---@return table? values
---@return string? message
local function run(content)
    local env = {
        vector2 = vector2, vector3 = vector3, vector4 = vector4,
        vec2 = vec2, vec3 = vec3, vec4 = vec4,
        tonumber = tonumber, tostring = tostring, type = type, pairs = pairs, ipairs = ipairs,
        math = setmetatable({}, { __index = math }),
        string = setmetatable({}, { __index = string }),
        table = setmetatable({}, { __index = table }),
    }

    local chunk, syntaxError = load(content, '@' .. OWNER_FILE, 't', env)

    if not chunk then
        return false, nil, tostring(syntaxError)
    end

    local ok, result = pcall(chunk)

    if not ok then
        return false, nil, tostring(result)
    end

    if type(result) ~= 'table' then
        return false, nil, 'MUST return a table'
    end

    return true, result, nil
end

---Checks merged values. Returns clean copies of every valid key, and every error found.
---@param values table
---@return table clean
---@return string[] errors
function Config.Validate(values)
    local errors, clean, known, names = {}, {}, {}, {}

    for _, entry in ipairs(RULES) do
        known[entry.key] = true
        names[#names + 1] = entry.key

        local ok, checked, detail = Schema.Check(entry.rule, values[entry.key])

        if ok then
            clean[entry.key] = checked
        else
            local text = (detail or 'is invalid'):gsub('^value:? ?', '')

            errors[#errors + 1] = ('%s: %s'):format(entry.key, text)
        end
    end

    for key in pairs(values) do
        if not known[key] then
            local suggestion = type(key) == 'string' and UgLib.String.Suggest(key, names) or nil

            errors[#errors + 1] = ('unknown key "%s".%s'):format(tostring(key), suggestion and (' Did you mean "%s"?'):format(suggestion) or '')
        end
    end

    table.sort(errors)

    return clean, errors
end

---@type table?
local current = nil

---Reads, merges and checks config.lua, generating it from the example when missing. Publishes the values to clients.
---@return boolean ok
---@return string[] errors
function Config.Load()
    local content = LoadResourceFile(RESOURCE, OWNER_FILE)

    if content == nil then
        local example = LoadResourceFile(RESOURCE, EXAMPLE_FILE)

        if example and SaveResourceFile(RESOURCE, OWNER_FILE, example, -1) then
            UgCore.Logger.Info('Generated %s.', OWNER_FILE)
        end

        content = example
    end

    local values = UgTemplate.Internal.Defaults()

    if content then
        local ok, owner, message = run(content)

        if not ok or not owner then
            current = nil

            return false, { ('%s: %s'):format(OWNER_FILE, tostring(message)) }
        end

        for key, value in pairs(owner) do
            values[key] = value
        end
    end

    local clean, errors = Config.Validate(values)

    for index, message in ipairs(errors) do
        errors[index] = ('%s: %s'):format(OWNER_FILE, message)
    end

    current = #errors == 0 and clean or nil

    if current then
        GlobalState:set(STATE_KEY, current, true)
    end

    return current ~= nil, errors
end

---The loaded config. Raises before a successful Load.
---@return table
function Config.Get()
    if not current then
        error('[ug-template] Config.Get before a successful Config.Load', 2)
    end

    return current
end
