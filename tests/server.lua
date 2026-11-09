--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

local H = dofile('tests/helpers.lua')

local Errors, Violations

---@param content string? config.lua content, nil for a first start
---@return string[] lines
local function boot(content)
    H.Reset()

    if content then
        H.Files['config.lua'] = content
    end

    local lines = H.Load('server')

    Errors, Violations = UgCore.Enums.Errors, UgCore.Enums.Violations

    return lines
end

---Puts player 1 at the first default point.
local function atFirstPoint()
    H.PedCoords[1] = vector3(195.0, -933.0, 30.69)
end

print('server')

H.Test('first start copies the example, publishes the defaults and registers callbacks', function()
    local lines = boot(nil)

    H.ExpectLine(lines, '[ug-template] v1.0.0 ready. 2 point(s).')
    H.Equal(H.Saved['config.lua'], LoadResourceFile('ug-template', 'config.example.lua'))
    H.Equal(GlobalState['ug-template:Config'], H.Defaults())
    H.Assert(H.Callbacks.Claim and H.Callbacks.Status, 'both callbacks')
    H.Equal(H.Callbacks.Claim.options.requireAlive, true)
end)

H.Test('the example returns the defaults', function()
    local env = { vector3 = vector3 }
    local example = assert(load(assert(LoadResourceFile('ug-template', 'config.example.lua')), 'example', 't', env))()

    H.Equal(example, H.Defaults())
end)

H.Test('every bad value is reported and nothing starts', function()
    local lines = boot([[
        return {
            distance = 50,
            acount = 'bank',
            points = { { label = 'x', coords = vector3(0, 0, 0), amount = -5 } },
        }
    ]])

    H.ExpectLine(lines, 'distance')
    H.ExpectLine(lines, 'unknown key "acount". Did you mean "account"?')
    H.ExpectLine(lines, 'points')
    H.ExpectLine(lines, 'Config invalid: 3 error(s).')
    H.Equal(GlobalState['ug-template:Config'], nil)
    H.Equal(H.Callbacks.Claim, nil)
end)

H.Test('syntax errors are reported and the sandbox has no os', function()
    H.ExpectLine(boot('return {'), 'config.lua:')
    H.ExpectLine(boot('return os.exit()'), 'config.lua:')
    H.ExpectLine(boot('return 5'), 'MUST return a table')
end)

H.Test('without the accounts module it says so and stays off', function()
    H.Reset()
    H.Modules.accounts = nil

    H.ExpectLine(H.Load('server'), 'needs the accounts module')
    H.Equal(H.Callbacks.Claim, nil)
end)

H.Test('a claim pays once, writes the ledger and emits an event', function()
    boot(nil)
    atFirstPoint()

    H.Equal(H.Call('Claim', 1, 1), { ok = true, amount = 250, waitMs = 600000 })
    H.Equal(H.Balances[1].cash, 250)
    H.Equal(H.Ledger[1], { target = 1, account = 'cash', amount = 250, reason = 'ug-template claim' })
    H.Equal(H.Emitted[1], { name = 'ug-template:Claimed', args = { 1, 1, 250 } })

    local again = H.Call('Claim', 1, 1)

    H.Equal(again.error, Errors.RateLimited)
    H.Equal(H.Balances[1].cash, 250, 'paid once')

    H.Advance(600000)
    H.Equal(H.Call('Claim', 1, 1).ok, true, 'after the cooldown')
end)

H.Test('the cooldown follows the character, not the player', function()
    boot(nil)
    atFirstPoint()
    H.Call('Claim', 1, 1)

    H.Players[1].characterId = 11
    H.Equal(H.Call('Claim', 1, 1).ok, true, 'another character')

    H.Players[1].characterId = 10
    H.Equal(H.Call('Claim', 1, 1).error, Errors.RateLimited)
    H.Equal(H.Exports.GetWait(1) > 0, true)
end)

H.Test('far players are flagged and get a generic code', function()
    boot(nil)
    H.PedCoords[1] = vector3(0.0, 0.0, 0.0)

    H.Equal(H.Call('Claim', 1, 1), { ok = false, error = Errors.NoPermission })
    H.Equal(H.Flags[1].violation, Violations.OutOfRange)
    H.Equal(H.Balances[1].cash, 0)
end)

H.Test('forged indexes never reach the handler or are flagged', function()
    boot(nil)
    atFirstPoint()

    local _, rejected = H.Call('Claim', 1, H.Any('1'))

    H.Equal(rejected, Errors.InvalidArgs, 'the schema rejects strings')
    H.Equal(select(2, H.Call('Claim', 1, 65)), Errors.InvalidArgs, 'and indexes above the maximum')
    H.Equal(H.Call('Claim', 1, 3).error, Errors.InvalidArgs, 'a point this config does not have')
    H.Equal(H.Flags[1].violation, Violations.InvalidPayload)
end)

H.Test('a failed payment gives the cooldown back', function()
    boot(nil)
    atFirstPoint()
    H.FailPayment = Errors.InternalError

    H.Equal(H.Call('Claim', 1, 1), { ok = false, error = Errors.InternalError })

    H.FailPayment = nil
    H.Equal(H.Call('Claim', 1, 1).ok, true)
end)

H.Test('status tells the amount and the wait', function()
    boot(nil)
    atFirstPoint()

    H.Equal(H.Call('Status', 1, 2), { ok = true, amount = 500, waitMs = 0 })
    H.Call('Claim', 1, 1)
    H.Equal(H.Call('Status', 1, 2).waitMs, 600000)
    H.Equal(H.Call('Status', 1, 9).error, Errors.NotFound)
end)

H.Done()
