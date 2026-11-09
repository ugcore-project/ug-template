---
name: server-actions
description: Add a secure server callback or net event in a UgCore resource. Use for anything a client asks the server to do or read - buying, paying, giving items, reading player data, server-to-client events.
---

# Server actions

Reference implementation: `server/claims.lua` (callbacks) and `client/panel.lua` (calling them).

## Pick the transport

| Need | Use |
| --- | --- |
| Client asks, waits for an answer | Server `UgCore.Callback.Register`, client `UgCore.Callback.Await` |
| Client tells, no answer | Server `UgCore.Network.Register`, client `UgCore.Network.TriggerServer` |
| Server tells one client or all | Server `UgCore.Network.TriggerClient(source, fullName, ...)` / `TriggerClients(fullName, ...)`, client `UgCore.Network.Register(name, handler)` |
| Server asks a client | Server `UgCore.Callback.Await(source, fullName, { schema, timeout? }, ...)`, client `UgCore.Callback.Register(name, handler)`. The answer is untrusted input. |

Never `RegisterNetEvent`, `RegisterServerEvent`, `TriggerServerEvent` or `TriggerClientEvent` directly.

## Server callback

```lua
local Schema = UgCore.Schema

UgCore.Callback.Register(UgTemplate.Enums.Callbacks.Buy, {
    -- Arguments, in order. Every string, array and map has a max.
    schema = Schema.Define({
        Schema.String({ min = 1, max = 32, pattern = '^[%w_]+$' }),
        Schema.Integer({ min = 1, max = 100 }),
    }),
    -- Per player: at most `max` calls, refilled over `per` ms.
    rate = { max = 3, per = 5000 },
    -- The player has a loaded character.
    requirePlayer = true,
    -- Downed and dead players are refused.
    requireAlive = true,
    -- Optional ACE the player MUST have.
    -- permission = 'ug-template.admin',
}, function(source, item, count)
    -- 1. Look up everything from server data, never from the client.
    -- 2. Check position with UgCore.Guard.IsNear(source, coords, distance + margin).
    -- 3. Check cooldowns and limits, then claim them before anything that yields.
    -- 4. Do the work through ug-core (Accounts, Jobs, ...).
    -- 5. Return one value. A table with `ok` and `error` is the convention.
    return { ok = true }
end)
```

ug-core runs, in order: concurrency cap, rate limits, `requirePlayer`, `requireAlive`, `permission`, schema, then your
handler inside `pcall`. A rejected request never reaches the handler. Every refusal flags the player in Guard,
except `requireAlive`: downed players MAY press keys. A handler error replies
`internal_error` and logs the detail on the server only.

Register after `UgCore.Lifecycle.Await(UgCore.Enums.Lifecycle.Ready)` (see `server/boot.lua`). Names are short:
ug-core adds `<resource>:`. Put names in `UgTemplate.Enums.Callbacks`.

## Client call

```lua
-- Await blocks: call it in a thread, never in a key handler or NUI callback directly.
CreateThread(function()
    local ok, value, errorCode = UgCore.Callback.Await('ug-template:Buy', 'water', 2)

    if not ok then
        -- errorCode is a UgCore.Enums.Errors value: rate_limited, no_permission, invalid_args, timeout, ...
        return
    end
end)
```

`ok` is false when ug-core refused the request or it timed out (10 s). A business failure is your own `value.error`.

## Handler checklist

- [ ] Inputs: only what the player chose (which item, which point). Never amounts, prices, results, positions, ids.
- [ ] A value the schema allows but the config does not (an index past the list): `Guard.Flag(..., InvalidPayload)`.
- [ ] Position: `UgCore.Guard.IsNear` with config distance plus a margin of 1 to 2 m. On failure flag `OutOfRange`.
- [ ] Ownership: who the player is comes from `source`. The character from `UgCore.Players.Get(source).characterId`.
- [ ] Cooldowns and locks set before any `await` (database, `Accounts.Add`), undone on failure.
- [ ] Money: `UgCore.Accounts.Add/Remove(source, account, amount, reason)` return `ok, balance, errorCode`.
- [ ] Generic error to the client (`Errors.NoPermission`), details to the log or the flag.
- [ ] Emit your event after success: `UgCore.Events.Emit('ug-template:Bought', source, item, count)`.
- [ ] Tests: success, each refusal, a forged argument, a failed payment (see `tests/server.lua`).

## Net event

```lua
UgCore.Network.Register('Ping', {
    schema = Schema.Define({ Schema.Optional(Schema.Boolean()) }),
    rate = { max = 1, per = 1000 },
}, function(source, flag) end)
```

Same options and checks as callbacks, no reply. Optional arguments MUST be trailing.

## Exports

Exports are the API for other resources. Keep them few and server-side when they change state.

```lua
exports('GetWait', Claims.GetWait)
```

An export called by another resource runs with `GetInvokingResource()` set to that resource. Validate its arguments
too: another resource is not more trusted than its author.

## Docs

- https://ugcore.urging.ch/developers/callbacks
- https://ugcore.urging.ch/developers/net-events
- https://ugcore.urging.ch/developers/schemas
- https://ugcore.urging.ch/api/callback
- https://ugcore.urging.ch/api/network
- https://ugcore.urging.ch/api/guard
- https://ugcore.urging.ch/concepts/security
- https://ugcore.urging.ch/ug-target/server-actions
