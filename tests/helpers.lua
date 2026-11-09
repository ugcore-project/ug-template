--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- Test helpers: a tiny runner, CfxLua mocks, and the real ug-core and ug-lib shared code this resource relies on.
-- ug-core and ug-lib are read from the UG_CORE and UG_LIB paths, siblings of this repository by default.
-- Mock only what the resource uses. Add a mock here when new code calls a new native or UgCore function.

---@class TestHelpers
local H = {}

H.Resource = 'ug-template'
H.CorePath = os.getenv('UG_CORE') or '../ug-core'
H.LibPath = os.getenv('UG_LIB') or '../ug-lib'

local passed, failed = 0, 0
local rawType = type
local vectorKinds = setmetatable({}, { __mode = 'k' })

---The CfxLua `type` names vectors.
---@param value any
---@return string
type = function(value)
    return rawType(value) == 'table' and vectorKinds[value] or rawType(value)
end

---@param kind string
---@param components table
---@return table
local function newVector(kind, components)
    vectorKinds[components] = kind

    return components
end

function vector2(x, y) return newVector('vector2', { x = x, y = y }) end

function vector3(x, y, z) return newVector('vector3', { x = x, y = y, z = z }) end

function vector4(x, y, z, w) return newVector('vector4', { x = x, y = y, z = z, w = w }) end

---@type table<string, string|false> file contents by path; false reads as missing
H.Files = {}
---@type table<string, string> files written by SaveResourceFile
H.Saved = {}
---@type table<string, function[]> FiveM event handlers
H.Handlers = {}
---@type table<string, function> exports of this resource
H.Exports = {}
H.Now = 0
H.CoreReady = true
---@type table<string, boolean> enabled ug-core modules
H.Modules = {}

-- Server side.

---@type table<string, { options: table, handler: function }> callbacks registered, by short name
H.Callbacks = {}
---@type { source: integer, violation: string, detail: string? }[]
H.Flags = {}
---@type table<integer, { identifier: string, characterId: integer? }> loaded players by source
H.Players = {}
---@type table<integer, vector3> server-side ped positions by source
H.PedCoords = {}
---@type table<integer, table<string, integer>> balances by source and account
H.Balances = {}
---@type { target: integer, account: string, amount: integer, reason: string? }[]
H.Ledger = {}
---@type { name: string, args: any[] }[] events emitted through UgCore.Events
H.Emitted = {}
---@type string? error code Accounts.Add answers instead of paying
H.FailPayment = nil

-- Client side.

---@type table<string, fun(...): table> what the server answers, by callback short name
H.Respond = {}
---@type { name: string, args: any[] }[] callbacks the client called
H.Requests = {}
---@type table<string, fun(body: any, cb: fun(reply: any))>
H.NuiCallbacks = {}
---@type table[] ug-lib points created
H.Points = {}
---@type table[] ug-lib keybinds registered
H.Keybinds = {}
---@type table? the shown TextUI options, nil when hidden
H.TextUI = nil
H.Locale = 'en'

function GetCurrentResourceName()
    return H.Resource
end

---@param _ string
---@param path string
---@return string?
function LoadResourceFile(_, path)
    if H.Files[path] ~= nil then
        return H.Files[path] or nil
    end

    local handle = io.open(path, 'rb')

    if not handle then
        return nil
    end

    local content = handle:read('a')

    handle:close()

    return content
end

function SaveResourceFile(_, path, content)
    H.Saved[path] = content
    H.Files[path] = content

    return true
end

function GetResourceMetadata(_, key)
    return key == 'version' and '1.0.0' or nil
end

---@type { thread: thread, wakeAt: integer }[] threads waiting in Wait
local sleeping = {}

---@param thread thread
local function resume(thread)
    local ok, result = coroutine.resume(thread)

    if not ok then
        error(debug.traceback(thread, tostring(result)), 0)
    end

    if coroutine.status(thread) == 'suspended' then
        sleeping[#sleeping + 1] = { thread = thread, wakeAt = H.Now + math.max(result or 0, 1) }
    end
end

---Like FiveM: the thread runs at once until its first Wait.
function CreateThread(fn)
    resume(coroutine.create(fn))
end

---Yields until H.Advance reaches the time. Outside a thread it only moves the clock.
---@param ms? integer
function Wait(ms)
    if coroutine.isyieldable() then
        coroutine.yield(ms or 0)
    else
        H.Now = H.Now + (ms or 0)
    end
end

---Runs frames of 16 ms until `ms` passed, waking threads whose time came.
---@param ms integer
function H.Advance(ms)
    local target = H.Now + ms

    repeat
        H.Now = math.min(H.Now + 16, target)

        local ready = {}

        for index = #sleeping, 1, -1 do
            if sleeping[index].wakeAt <= H.Now then
                ready[#ready + 1] = table.remove(sleeping, index)
            end
        end

        for index = #ready, 1, -1 do
            resume(ready[index].thread)
        end
    until H.Now >= target
end

---Calls of auto-mocked natives, in order: `{ name, args }`.
---@type { name: string, args: any[] }[]
H.Natives = {}

---@param name string
---@return { name: string, args: any[] }[]
function H.CallsOf(name)
    local list = {}

    for _, call in ipairs(H.Natives) do
        if call.name == name then
            list[#list + 1] = call
        end
    end

    return list
end

---@type table<string, any> answers of auto-mocked natives
H.NativeReturns = {}

-- Any other PascalCase global is a native: recorded, answering H.NativeReturns[name] or nil.
setmetatable(_G, {
    __index = function(_, name)
        if rawType(name) == 'string' and name:find('^%u') then
            return function(...)
                H.Natives[#H.Natives + 1] = { name = name, args = { ... } }

                local value = H.NativeReturns[name]

                if rawType(value) == 'function' then
                    return value(...)
                end

                return value
            end
        end

        return nil
    end,
})

function GetGameTimer()
    return H.Now
end

function AddEventHandler(name, handler)
    H.Handlers[name] = H.Handlers[name] or {}
    table.insert(H.Handlers[name], handler)
end

exports = setmetatable({}, {
    __call = function(_, name, fn)
        H.Exports[name] = fn
    end,
})

function RegisterNUICallback(name, handler)
    H.NuiCallbacks[name] = handler
end

---Posts to a NUI callback like the page does. Returns the reply.
---@param name string
---@param body any
---@return any
function H.PostNui(name, body)
    local reply = nil

    assert(H.NuiCallbacks[name], 'NUI callback not registered: ' .. name)(body, function(value)
        reply = value
    end)

    return reply
end

---Messages sent to the page, in order.
---@return { action: string, payload: any }[]
function H.PageMessages()
    local list = {}

    for _, call in ipairs(H.CallsOf('SendNUIMessage')) do
        list[#list + 1] = call.args[1]
    end

    return list
end

---The payload of the last page message with this action, or false when it was sent without one.
---@param action string
---@return any
function H.LastPage(action)
    local found = nil

    for _, message in ipairs(H.PageMessages()) do
        if message.action == action then
            found = message
        end
    end

    return found and (found.payload or false)
end

---Loads a Lua file into the global environment.
---@param path string
local function run(path)
    assert(loadfile(path, 't'))()
end

local function loadCore()
    for _, file in ipairs({
        'core/shared/init.lua',
        'core/shared/utils/init.lua',
        'core/shared/utils/table.lua',
        'core/shared/utils/string.lua',
        'core/shared/enums/init.lua',
        'core/shared/enums/lifecycle.lua',
        'core/shared/enums/violations.lua',
        'core/shared/enums/errors.lua',
        'core/shared/logger.lua',
        'core/shared/schema.lua',
        'core/shared/enums/events.lua',
        'core/shared/enums/hooks.lua',
        'core/shared/enums/statebags.lua',
        'modules/players/shared/enums.lua',
    }) do
        run(H.CorePath .. '/' .. file)
    end

    UgCore.Logger.Debug = function() end
    UgCore.Lifecycle = {
        Await = function()
            return H.CoreReady
        end,
    }
    UgCore.Modules = {
        IsEnabled = function(name)
            return H.Modules[name] == true
        end,
    }
    UgCore.Events = {
        Emit = function(name, ...)
            H.Emitted[#H.Emitted + 1] = { name = name, args = { ... } }
        end,
    }
end

local function installServer()
    local Errors = UgCore.Enums.Errors

    UgCore.Callback = {
        Register = function(name, options, handler)
            H.Callbacks[name] = { options = options, handler = handler }
        end,
    }
    UgCore.Guard = {
        IsNear = function(target, coords, maxDistance)
            local ped = H.PedCoords[target]

            return ped ~= nil and math.sqrt((ped.x - coords.x) ^ 2 + (ped.y - coords.y) ^ 2 + (ped.z - coords.z) ^ 2) <= maxDistance
        end,
        Flag = function(target, violation, detail)
            H.Flags[#H.Flags + 1] = { source = target, violation = violation, detail = detail }
        end,
    }
    UgCore.Players = {
        Get = function(target)
            local player = H.Players[target]

            return player and { source = target, identifier = player.identifier, characterId = player.characterId } or nil
        end,
    }
    UgCore.Accounts = {
        Add = function(target, account, amount, reason)
            if H.FailPayment then
                return false, nil, H.FailPayment
            end

            local balances = H.Balances[target]

            if not balances then
                return false, nil, Errors.NotLoaded
            end

            balances[account] = (balances[account] or 0) + amount
            H.Ledger[#H.Ledger + 1] = { target = target, account = account, amount = amount, reason = reason }

            return true, balances[account], nil
        end,
    }
end

local function installClient()
    UgCore.Callback = {
        Await = function(name, ...)
            local short = name:match('^' .. H.Resource:gsub('%-', '%%-') .. ':(.+)$') or name

            H.Requests[#H.Requests + 1] = { name = short, args = { ... } }

            local respond = H.Respond[short]

            if not respond then
                return false, nil, UgCore.Enums.Errors.Timeout
            end

            return true, respond(...), nil
        end,
    }
    UgLib.Enums = UgLib.Enums or {}
    UgLib.Enums.GlobalState = { Config = 'ug-lib:Config' }
    UgLib.Locale = {
        Create = function()
            return function(key, vars)
                return 'label:' .. key .. (vars and vars.label and (':' .. vars.label) or '')
            end
        end,
        GetCode = function()
            return H.Locale
        end,
    }
    UgLib.Point = {
        Create = function(options)
            H.Points[#H.Points + 1] = options

            return { id = #H.Points }
        end,
    }
    UgLib.TextUI = {
        Show = function(options)
            H.TextUI = options
        end,
        Hide = function()
            H.TextUI = nil
        end,
    }
    UgLib.Keybind = {
        Register = function(options)
            H.Keybinds[#H.Keybinds + 1] = options

            return ('+%s-%s'):format(H.Resource, options.name)
        end,
    }
end

local function loadLib()
    for _, file in ipairs({ 'shared/init.lua', 'shared/utils.lua', 'shared/string.lua', 'shared/table.lua' }) do
        run(H.LibPath .. '/' .. file)
    end
end

---Reads script lists from fxmanifest.lua.
---@return table<string, string[]>
local function readManifest()
    local lists = { shared = {}, server = {}, client = {} }
    local groups = {
        shared_script = 'shared', shared_scripts = 'shared',
        server_script = 'server', server_scripts = 'server',
        client_script = 'client', client_scripts = 'client',
    }
    local env = setmetatable({}, {
        __index = function(_, directive)
            return function(value)
                local group = groups[directive]

                if group then
                    for _, entry in ipairs(rawType(value) == 'table' and value or { value }) do
                        table.insert(lists[group], entry)
                    end
                end
            end
        end,
    })

    assert(loadfile('fxmanifest.lua', 't', env))()

    return lists
end

---Fresh mocks. Tests change them before H.Load. `config.lua` starts missing, whatever is on disk.
function H.Reset()
    H.Files, H.Saved = { ['config.lua'] = false }, {}
    H.Handlers, H.Exports = {}, {}
    H.Now, H.CoreReady = 1000, true
    H.Modules = { accounts = true, characters = true }
    H.Natives, H.NativeReturns = {}, {}
    H.Callbacks, H.Flags, H.Emitted, H.Ledger = {}, {}, {}, {}
    H.Players = { [1] = { identifier = 'license:1', characterId = 10 }, [2] = { identifier = 'license:2', characterId = 20 } }
    H.PedCoords = {}
    H.Balances = { [1] = { cash = 0 }, [2] = { cash = 0 } }
    H.FailPayment = nil
    H.Respond, H.Requests, H.NuiCallbacks = {}, {}, {}
    H.Points, H.Keybinds, H.TextUI, H.Locale = {}, {}, nil, 'en'
    GlobalState = setmetatable({}, {
        __index = {
            set = function(self, key, value)
                rawset(self, key, value)
            end,
        },
    })
    sleeping = {}
    UgCore, UgLib, UgTemplate = nil, nil, nil
end

---Loads ug-core and ug-lib, then this resource's shared and side scripts in manifest order.
---@param side 'server'|'client'
---@return string[] printed lines
function H.Load(side)
    return H.Capture(function()
        loadCore()
        loadLib()

        if side == 'server' then
            installServer()
        else
            installClient()
        end

        local manifest = readManifest()

        for _, group in ipairs({ 'shared', side }) do
            for _, path in ipairs(manifest[group]) do
                if path:sub(1, 1) ~= '@' then
                    run(path)
                end
            end
        end
    end)
end

---The server defaults, as a real server replicates them.
---@return table
function H.Defaults()
    H.Capture(loadCore)

    UgTemplate = { Internal = {} }
    run('server/defaults.lua')

    local values = UgTemplate.Internal.Defaults()

    UgCore, UgTemplate = nil, nil

    return values
end

---Loads the client with the server's config replicated, and opens the page.
---@param overrides? table config values that replace the defaults
---@return string[] printed lines
function H.LoadClient(overrides)
    local values = H.Defaults()

    for key, value in pairs(overrides or {}) do
        values[key] = value
    end

    GlobalState['ug-template:Config'] = values

    local lines = H.Load('client')

    H.PostNui('ready', {})

    return lines
end

---Calls a registered server callback like ug-core does: the schema first, then the handler.
---@param name string short name, such as `Claim`
---@param target integer
---@param ... any
---@return any result
---@return string? errorCode when ug-core rejects before the handler
function H.Call(name, target, ...)
    local entry = assert(H.Callbacks[name], 'callback not registered: ' .. name)
    local ok, args = UgCore.Schema.Validate(entry.options.schema, ...)

    if not ok or not args then
        return nil, UgCore.Enums.Errors.InvalidArgs
    end

    return entry.handler(target, table.unpack(args, 1, args.n))
end

---Runs every handler of a FiveM event, like the runtime.
---@param name string
function H.TriggerEvent(name, ...)
    for _, handler in ipairs(H.Handlers[name] or {}) do
        handler(...)
    end
end

---Runs `fn` and returns every printed line, without color codes.
---@param fn fun()
---@return string[]
function H.Capture(fn)
    local lines = {}
    local original = print

    print = function(...)
        local parts = {}

        for index = 1, select('#', ...) do
            parts[#parts + 1] = tostring((select(index, ...)))
        end

        lines[#lines + 1] = (table.concat(parts, ' '):gsub('%^%d', ''))
    end

    local ok, err = pcall(fn)

    print = original

    if not ok then
        error(err, 0)
    end

    return lines
end

---@param a any
---@param b any
---@return boolean
local function same(a, b)
    if rawType(a) ~= 'table' or rawType(b) ~= 'table' then
        return a == b
    end

    if vectorKinds[a] ~= vectorKinds[b] then
        return false
    end

    for key, value in pairs(a) do
        if not same(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

---@param value any
---@param depth? integer
---@return string
local function show(value, depth)
    depth = depth or 0

    if rawType(value) ~= 'table' then
        return rawType(value) == 'string' and ('%q'):format(value) or tostring(value)
    end

    if depth > 3 then
        return '{...}'
    end

    local parts = {}

    for key, item in pairs(value) do
        parts[#parts + 1] = ('%s = %s'):format(tostring(key), show(item, depth + 1))
    end

    table.sort(parts)

    return (vectorKinds[value] or '') .. '{ ' .. table.concat(parts, ', ') .. ' }'
end

function H.Equal(actual, expected, message)
    if not same(actual, expected) then
        error(('%s\n  expected: %s\n  actual:   %s'):format(message or 'not equal', show(expected), show(actual)), 2)
    end
end

function H.Assert(condition, message)
    if not condition then
        error(message or 'assertion failed', 2)
    end
end

---Runs `fn` and expects it to raise an error containing `text`.
---@param fn fun()
---@param text string
function H.Raises(fn, text)
    local ok, err = pcall(fn)

    if ok then
        error(('expected an error containing "%s"'):format(text), 2)
    end

    if not tostring(err):find(text, 1, true) then
        error(('expected an error containing "%s", got: %s'):format(text, tostring(err)), 2)
    end
end

---@param lines string[]
---@param text string
function H.ExpectLine(lines, text)
    for _, line in ipairs(lines) do
        if line:find(text, 1, true) then
            return
        end
    end

    error(('no line contains "%s":\n  %s'):format(text, table.concat(lines, '\n  ')), 2)
end

---Wrong-type values for tests. LuaLS ignores casts on literals.
---@param value any
---@return any
function H.Any(value)
    return value
end

---@param name string
---@param fn fun()
function H.Test(name, fn)
    local ok, err = xpcall(fn, debug.traceback)

    if ok then
        passed = passed + 1
        print('  ok    ' .. name)
    else
        failed = failed + 1
        print('  FAIL  ' .. name .. '\n        ' .. tostring(err):gsub('\n', '\n        '))
    end
end

function H.Done()
    print(('\n%d passed, %d failed'):format(passed, failed))
    os.exit(failed == 0 and 0 or 1)
end

---Minimal json like the CfxLua one: objects, arrays, strings, numbers, booleans.
json = {}

---@param text string
---@return any
function json.decode(text)
    local position = 1

    local function skip()
        position = text:find('[^%s]', position) or #text + 1
    end

    local parse

    local function parseString()
        local result = {}

        position = position + 1

        while true do
            local char = text:sub(position, position)

            if char == '' then
                error('unterminated string')
            end

            if char == '"' then
                position = position + 1

                return table.concat(result)
            end

            if char == '\\' then
                local escape = text:sub(position + 1, position + 1)

                if escape == 'u' then
                    result[#result + 1] = utf8.char(tonumber(text:sub(position + 2, position + 5), 16))
                    position = position + 6
                else
                    result[#result + 1] = ({ n = '\n', t = '\t', r = '\r' })[escape] or escape
                    position = position + 2
                end
            else
                result[#result + 1] = char
                position = position + 1
            end
        end
    end

    ---@param close string
    ---@param item fun(result: table)
    ---@return table
    local function collection(close, item)
        local result = {}

        position = position + 1
        skip()

        if text:sub(position, position) == close then
            position = position + 1

            return result
        end

        while true do
            item(result)
            skip()

            local separator = text:sub(position, position)

            position = position + 1

            if separator == close then
                return result
            end

            if separator ~= ',' then
                error('expected , or ' .. close)
            end
        end
    end

    parse = function()
        skip()

        local char = text:sub(position, position)

        if char == '{' then
            return collection('}', function(result)
                skip()

                local key = parseString()

                skip()
                position = position + 1
                result[key] = parse()
            end)
        end

        if char == '[' then
            return collection(']', function(result)
                result[#result + 1] = parse()
            end)
        end

        if char == '"' then
            return parseString()
        end

        for literal, value in pairs({ ['true'] = true, ['false'] = false }) do
            if text:sub(position, position + #literal - 1) == literal then
                position = position + #literal

                return value
            end
        end

        if text:sub(position, position + 3) == 'null' then
            position = position + 4

            return nil
        end

        local number = text:match('^-?%d+%.?%d*[eE]?[-+]?%d*', position)

        if not number or number == '' then
            error('unexpected character at ' .. position)
        end

        position = position + #number

        return math.tointeger(tonumber(number)) or tonumber(number)
    end

    return parse()
end

return H
