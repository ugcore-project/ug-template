--[[

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

]] --

-- The example feature: a player at a point claims a reward, once per cooldown. Replace it with your own.
-- The client only says which point. Distance, cooldown, amount and account are decided here.

---@class UgTemplate.Internal.Claims
local Claims = {}
UgTemplate.Internal.Claims = Claims

local Config = UgTemplate.Internal.Config
local Enums = UgTemplate.Enums
local Errors = UgCore.Enums.Errors
local Violations = UgCore.Enums.Violations

-- Extra meters for lag between the client check and the server check.
local DISTANCE_MARGIN = 1.5

---@class UgTemplateClaimResult
---@field ok boolean
---@field error? UgErrorCode
---@field amount? integer
---@field waitMs? integer time left before the next claim

---Next claim time by character, in GetGameTimer ms. Lost on restart: use the database to keep it.
---@type table<string, integer>
local nextAt = {}

---Who the cooldown belongs to: the character, or the player without the characters module.
---@param source integer
---@return string?
local function ownerOf(source)
    local player = UgCore.Players.Get(source)

    if not player then
        return nil
    end

    return player.characterId and ('character:' .. player.characterId) or player.identifier
end

---@param owner string
---@return integer
local function waitFor(owner)
    return math.max((nextAt[owner] or 0) - GetGameTimer(), 0)
end

---Time left before `source` MAY claim again, in ms.
---@param source integer
---@return integer? waitMs nil when the player is not loaded
function Claims.GetWait(source)
    local owner = ownerOf(source)

    return owner and waitFor(owner) or nil
end

---Callback: what the panel shows before claiming.
---@param source integer
---@param index integer point index, validated by the schema
---@return UgTemplateClaimResult
function Claims.Status(source, index)
    local point = Config.Get().points[index]
    local owner = ownerOf(source)

    if not point or not owner then
        return { ok = false, error = Errors.NotFound }
    end

    return { ok = true, amount = point.amount, waitMs = waitFor(owner) }
end

---Callback: pays the point's reward when every check passes.
---@param source integer
---@param index integer point index, validated by the schema
---@return UgTemplateClaimResult
function Claims.Claim(source, index)
    local config = Config.Get()
    local point = config.points[index]

    -- The schema bounds the index to the largest config, not to this one: a higher index is a forged request.
    if not point then
        UgCore.Guard.Flag(source, Violations.InvalidPayload, ('ug-template claim of point %d'):format(index))

        return { ok = false, error = Errors.InvalidArgs }
    end

    if not UgCore.Guard.IsNear(source, point.coords, config.distance + DISTANCE_MARGIN) then
        UgCore.Guard.Flag(source, Violations.OutOfRange, ('ug-template claim at point %d'):format(index))

        -- Generic code: the client never learns which check failed.
        return { ok = false, error = Errors.NoPermission }
    end

    local owner = ownerOf(source)

    if not owner then
        return { ok = false, error = Errors.NotLoaded }
    end

    local wait = waitFor(owner)

    if wait > 0 then
        return { ok = false, error = Errors.RateLimited, waitMs = wait }
    end

    -- Set before paying: Accounts.Add waits on the database, and a second request MUST NOT pass meanwhile.
    nextAt[owner] = GetGameTimer() + config.cooldown

    local paid, _, errorCode = UgCore.Accounts.Add(source, config.account, point.amount, 'ug-template claim')

    if not paid then
        nextAt[owner] = nil

        return { ok = false, error = errorCode or Errors.InternalError }
    end

    UgCore.Events.Emit(Enums.Events.Claimed, source, index, point.amount)

    return { ok = true, amount = point.amount, waitMs = config.cooldown }
end

---Registers the callbacks. Every callback has a schema and a rate limit.
function Claims.Register()
    local schema = UgCore.Schema.Define({ UgCore.Schema.Integer({ min = 1, max = Config.MaxPoints }) })

    UgCore.Callback.Register(Enums.Callbacks.Status, {
        schema = schema,
        rate = { max = 5, per = 5000 },
        requirePlayer = true,
    }, Claims.Status)

    UgCore.Callback.Register(Enums.Callbacks.Claim, {
        schema = schema,
        rate = { max = 2, per = 5000 },
        requirePlayer = true,
        requireAlive = true,
    }, Claims.Claim)
end

-- Other resources: exports['ug-template']:GetWait(source)
exports('GetWait', Claims.GetWait)
