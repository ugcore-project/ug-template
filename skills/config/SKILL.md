---
name: config
description: Add or change an owner config option in a UgCore resource. Use when a value should be set by the server owner in config.lua.
---

# Owner config

Owners edit `config.lua`. It is generated from `server/config.default.lua` on the first start and never overwritten, so an
update can only add defaults, never change an owner's values.

## Files to touch, every time

1. `server/config.default.lua`: the default value, with a comment owners understand. It is the only place defaults
   live: `UgTemplate.Internal.Defaults()` reads it in the owner sandbox, so write plain values, never enums.
2. `server/config.lua` `RULES`: one `UgCore.Schema` rule per key. Strings, arrays and maps MUST have `max`.
3. A test in `tests/server.lua` for a bad value when the rule is not trivial.
4. The docs: `README.md` configuration section.

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

## Look and feel: every resource is configurable

Owners shape every screen without forking. A resource with a page MUST offer these keys, like ug-template does:

- `theme = {}`: ug-lib's theme for this resource only, `{ mode?, colors?, radius?, font?, scale? }`. `colors` takes
  ug-lib's tokens plus the resource's own color tokens, if any. Client `Nui.Theme(libTheme, own)` merges it token by
  token on top of ug-lib's theme. It MUST loop `for index = 1, 2` over the two color tables, never
  `ipairs({ base.colors, own.colors })`: ipairs stops at a missing ug-lib table and drops the owner colors.
- `layout`: where and how the screen shows (position, size, `animations`). Listed in `MERGED`, so an owner sets one
  field and keeps the rest.
- `features`: one boolean per optional part, keyed by an enum. Also in `MERGED`. A feature that is off is hidden in the
  page AND refused by Lua when it has a Lua side (a callback, a keybind, a command), since any script can post.
- Maps such as `soundEffects` (`{ [Sound.X] = { name, set } }`) replace the default entirely: a key left out turns
  that entry off.
- Hard-coded colors (`text-rose-400`), sizes, timings, keys and sounds become config or theme tokens.
- The page re-reads every owner value with a reader that clamps each field and falls back to the default
  (`readLayout`, `readFeatures`). Enums the page shares with Lua go in the parity check of `tests/nui.lua`.
- `web/src/dev/Preview.tsx` exposes `window.__showcase.configure(overrides)` to preview an owner config.

## Behavior owners rely on

- Owner values replace defaults key by key, except the tables in `MERGED`, which merge field by field. A key they
  remove uses its default.
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
