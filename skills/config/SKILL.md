---
name: config
description: Add or change an owner config option in a UgCore resource. Use when a value should be set by the server owner in config.lua.
---

# Owner config

Owners edit `config.lua`. It is generated from `config.example.lua` on the first start and never overwritten, so an
update can only add defaults, never change an owner's values.

## Files to touch, every time

1. `server/defaults.lua`: the default value.
2. `config.example.lua`: the same value, with a comment owners understand. `tests/server.lua` fails when it differs
   from the defaults.
3. `server/config.lua` `RULES`: one `UgCore.Schema` rule per key. Strings, arrays and maps MUST have `max`.
4. A test in `tests/server.lua` for a bad value when the rule is not trivial.
5. The docs: `README.md` configuration section.

```lua
-- server/config.lua
{ key = 'blipColor', rule = Schema.Integer({ min = 0, max = 85 }) },
{ key = 'jobs', rule = Schema.Array(Schema.String({ min = 1, max = 32, pattern = '^[%w_]+$' }), { max = 16 }) },
{
    key = 'shop',
    rule = Schema.Object({
        label = Schema.String({ min = 1, max = 48 }),
        coords = Schema.Vector3({ maxComponent = 10000 }),
        price = Schema.Integer({ min = 0, max = 1000000 }),
        enabled = Schema.Optional(Schema.Boolean()),
    }),
},
```

Rules: `String(opts)`, `Number`, `Integer`, `Boolean`, `Vector2/3/4`, `Enum(values)`, `Array(item, { max })`,
`Map(key, value, { max })`, `Object(fields)` (strict, unknown keys fail), `Optional(rule)`. A rule MAY take
`validate = function(value) return ok, message end` for checks across fields.

For checks between keys, add them after the loop in `Config.Validate` (ug-hud checks that a fuel source has the keys
it needs).

## Behavior owners rely on

- Owner values replace defaults key by key. A key they remove uses its default.
- `config.lua` runs in a sandbox with `vector2/3/4`, `vec2/3/4`, `math`, `string`, `table`, `tonumber`, `tostring`,
  `type`, `pairs`, `ipairs`. No `os`, no `io`, no `require`.
- Every error is collected and printed, one line each, then `Config invalid: N error(s).` and the resource stays off.
- Unknown keys get a suggestion: `unknown key "acount". Did you mean "account"?`.
- `Config.Get()` returns the validated values on the server.
- Every value replicates to clients in `GlobalState['<resource>:Config']`. Never put secrets there. A server-only
  secret (a webhook) needs its own server-only file or a convar read with `GetConvar`, never this config.

## Convars

For values owners set per server in `server.cfg`, read a convar on the server: `GetConvar('ug-template:Debug', 'false')`.
Name convars `<resource>:<Key>`. Convars are strings: parse and validate them like config.

## Docs

- https://ugcore.urging.ch/developers/schemas
- https://ugcore.urging.ch/api/schema
- https://ugcore.urging.ch/reference/config-files
- https://ugcore.urging.ch/reference/convars
