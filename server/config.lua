--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Owner config: config.lua, copied from server/config.default.lua on the first start and never overwritten.
-- Owner values replace the defaults key by key, except the tables in MERGED, which merge field by field.
-- Clients get every value through GlobalState: never put secrets here.

---@class UgTemplate.Internal.Config
local Config = {}
UgTemplate.Internal.Config = Config

local Schema = UgCore.Schema
local Enums = UgTemplate.Enums

local RESOURCE = GetCurrentResourceName()
local OWNER_FILE = 'config.lua'
-- To verify live: the sound names in server/config.default.lua.
local DEFAULT_FILE = 'server/config.default.lua'
local STATE_KEY = 'ug-template:Config'

Config.StateKey = STATE_KEY
Config.MaxPoints = 64

---@param enum table<string, string>
---@return string[]
local function valuesOf(enum)
    local values = {}

    for _, value in pairs(enum) do
        values[#values + 1] = value
    end

    table.sort(values)

    return values
end

local HSL = Schema.String({
    min = 5,
    max = 24,
    pattern = '^%d+%.?%d* %d+%.?%d*%% %d+%.?%d*%%$',
})
local GAME_NAME = Schema.String({
    min = 1,
    max = 64,
    pattern = '^[%w_%-]+$',
})
local SOUNDS = valuesOf(Enums.Sound)

-- ug-lib's theme tokens. A resource with colors of its own appends its tokens here and in web/src/lib/theme.ts.
local THEME_TOKENS = {
    'background', 'foreground', 'card', 'cardForeground', 'popover', 'popoverForeground',
    'primary', 'primaryForeground', 'secondary', 'secondaryForeground', 'muted', 'mutedForeground',
    'accent', 'accentForeground', 'destructive', 'destructiveForeground', 'success', 'successForeground',
    'warning', 'warningForeground', 'border', 'input', 'ring',
}

---@param value string
---@return boolean ok
---@return string? message
local function size(value)
    if value:find('^%d*%.?%d+rem$') or value:find('^%d*%.?%d+px$') then
        return true, nil
    end

    return false, 'MUST be a size in rem or px'
end

---@return UgSchemaRule
local function featuresRule()
    local fields = {}

    for _, feature in ipairs(valuesOf(Enums.Feature)) do
        fields[feature] = Schema.Boolean()
    end

    return Schema.Object(fields)
end

-- Tables that merge field by field onto the defaults: an owner sets one field and keeps the rest.
-- Every other key replaces its default, so a map like soundEffects drops the entries the owner left out.
local MERGED = {
    layout = true,
    features = true,
}

-- One rule per key. Every string, array and map is bounded.
---@type { key: string, rule: UgSchemaRule }[]
local RULES = {
    {
        key = 'interactKey',
        rule = Schema.String({
            min = 1,
            max = 16,
            pattern = '^[%w_]+$',
        }),
    },
    {
        key = 'distance',
        rule = Schema.Number({
            min = 0.5,
            max = 10,
        }),
    },
    {
        key = 'cooldown',
        rule = Schema.Integer({
            min = 0,
            max = 86400000,
        }),
    },
    {
        key = 'account',
        rule = Schema.String({
            min = 1,
            max = 32,
            pattern = '^%l[%w]*$',
        }),
    },
    {
        key = 'points',
        rule = Schema.Array(Schema.Object({
            label = Schema.String({
                min = 1,
                max = 48,
            }),
            coords = Schema.Vector3({
                maxComponent = 10000,
            }),
            amount = Schema.Integer({
                min = 1,
                max = 1000000,
            }),
        }), {
            min = 1,
            max = Config.MaxPoints,
        }),
    },
    {
        key = 'theme',
        rule = Schema.Object({
            mode = Schema.Optional(Schema.Enum({ 'dark', 'light' })),
            colors = Schema.Optional(Schema.Map(Schema.Enum(THEME_TOKENS), HSL, {
                max = #THEME_TOKENS,
            })),
            radius = Schema.Optional(Schema.String({
                min = 3,
                max = 16,
                validate = size,
            })),
            font = Schema.Optional(Schema.Enum({ 'Inter' })),
            scale = Schema.Optional(Schema.Number({
                min = 0.75,
                max = 1.5,
            })),
        }),
    },
    {
        key = 'layout',
        rule = Schema.Object({
            position = Schema.Enum(valuesOf(Enums.Position)),
            width = Schema.Number({
                min = 14,
                max = 40,
            }),
            animations = Schema.Boolean(),
        }),
    },
    {
        key = 'features',
        rule = featuresRule(),
    },
    {
        key = 'soundEffects',
        rule = Schema.Map(Schema.Enum(SOUNDS), Schema.Object({
            name = GAME_NAME,
            set = GAME_NAME,
        }), {
            max = #SOUNDS,
        }),
    },
}

---Runs owner code in a sandbox with only what a config needs.
---@param content string
---@param name? string file name in errors, config.lua by default
---@return boolean ok
---@return table? values
---@return string? message
local function run(content, name)
    local env = {
        vector2 = vector2, vector3 = vector3, vector4 = vector4,
        vec2 = vec2, vec3 = vec3, vec4 = vec4,
        tonumber = tonumber, tostring = tostring, type = type, pairs = pairs, ipairs = ipairs,
        math = setmetatable({}, {
            __index = math,
        }),
        string = setmetatable({}, {
            __index = string,
        }),
        table = setmetatable({}, {
            __index = table,
        }),
    }

    local chunk, syntaxError = load(content, '@' .. (name or OWNER_FILE), 't', env)

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

---A fresh copy of the defaults, read from server/config.default.lua: the only place they live.
---@return table
function UgTemplate.Internal.Defaults()
    local ok, values, message = run(LoadResourceFile(RESOURCE, DEFAULT_FILE) or '', DEFAULT_FILE)

    if not ok or not values then
        error(('[ug-template] %s: %s'):format(DEFAULT_FILE, tostring(message)), 2)
    end

    return values
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
        local example = LoadResourceFile(RESOURCE, DEFAULT_FILE)

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
            if MERGED[key] and type(value) == 'table' and type(values[key]) == 'table' then
                for field, fieldValue in pairs(value) do
                    values[key][field] = fieldValue
                end
            else
                values[key] = value
            end
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
