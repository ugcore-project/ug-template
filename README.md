<div align="center">

# ⬢ ug-template

**The starting point for UgCore resources. Config, secure callbacks, a NUI page, tests, CI and AI agent guides, ready to rename.**

[![Documentation](https://img.shields.io/badge/Docs-ugcore.urging.ch-7C5CFF?logo=readthedocs&logoColor=white)](https://ugcore.urging.ch)
[![CI](https://img.shields.io/github/actions/workflow/status/ugcore-project/ug-template/ci.yml?branch=dev&label=CI)](https://github.com/ugcore-project/ug-template/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/ugcore-project/ug-template?color=brightgreen)](LICENSE)
[![Discord](https://img.shields.io/discord/1518308384900649021?label=Discord&logo=discord&logoColor=white&color=5865F2)](https://discord.gg/pCJUcyVw5X)

[**Documentation**](https://ugcore.urging.ch) · [**Quickstart**](https://ugcore.urging.ch/quickstart) · [**Security**](https://ugcore.urging.ch/concepts/security) · [**API**](https://ugcore.urging.ch/api/overview)

</div>

---

Press **Use this template** on GitHub, rename it, and replace the example with your feature. Everything around it is
already done the UgCore way: owner config with validation, server callbacks with schemas and rate limits, Guard checks,
a themed React page with a hardened bridge, Lua and web tests, CI, and releases.

## What you get

- 🧱 **Structure.** `shared/`, `server/`, `client/`, `locales/`, `web/`, `tests/`, one global, enums for every value.
- ⚙️ **Owner config.** `config.lua` generated from `config.example.lua`, sandboxed, validated with `UgCore.Schema`,
  every error listed with a suggestion for typos, replicated to clients.
- 🔒 **Secure server actions.** Callbacks with schema, rate limit, `requirePlayer`, `requireAlive`, distance checks
  through `UgCore.Guard.IsNear`, cheats flagged, generic errors to clients, payments through `UgCore.Accounts`.
- 🖥️ **NUI page.** React 19, Vite, Tailwind 3, zustand, framer-motion. ug-lib's theme applied, so it matches every
  UgCore screen. Ready handshake, schema-checked callbacks, rate budget, strict CSP, a browser preview.
- 🧪 **Tests.** Lua 5.4 suites with native mocks against the real ug-core schema and enums; vitest for the page;
  contract tests that keep Lua and TypeScript enums and every locale in sync.
- 🚀 **CI and releases.** LuaLS strict check, tests, manifest and license checks, PR title check, release archive on tag.
- 🤖 **AI ready.** `AGENTS.md` and `skills/` give coding agents the UgCore rules and step-by-step guides.

## The example

Claim points. Walk to a point, press `E`, and the panel shows the reward and the cooldown. **Claim** asks the server,
which checks that the player is loaded, alive, close enough and off cooldown, pays into their account with a ledger
row, and emits `ug-template:Claimed`. Forged requests are flagged in Guard.

It touches every pattern once. Delete it when you start your feature: see
[skills/new-resource](skills/new-resource/SKILL.md).

## Requirements

- OneSync.
- [ug-core](https://github.com/ugcore-project/ug-core) 1.0.0 or newer, with the `accounts` module for the example.
- [ug-lib](https://github.com/ugcore-project/ug-lib) 1.0.0 or newer.

## Installation

Download a release, extract it to your resources folder and start it after ug-core and ug-lib:

```cfg
ensure oxmysql
ensure ug-core
ensure ug-lib
ensure ug-template
```

On the first start, `config.example.lua` is copied to `config.lua`. Updates never overwrite it. The console prints
`[ug-template] v1.0.0 ready. 2 point(s).` and each client prints `[ug-template] Ready: 2 point(s).` in F8.

## Configuration

| Key | Default | Purpose |
| --- | --- | --- |
| `interactKey` | `'E'` | Key that opens the panel. Players MAY rebind it. |
| `distance` | `2.0` | Meters from a point. The server checks it too. |
| `cooldown` | `600000` | Milliseconds between claims of one character. |
| `account` | `'cash'` | ug-core account the reward goes to. |
| `points` | two points | `{ label, coords = vector3(...), amount }`, at most 64. |

## Exports

```lua
-- Server: milliseconds before the player may claim again, nil when not loaded.
local wait = exports['ug-template']:GetWait(source)
```

Listen for claims in another server resource:

```lua
UgCore.Events.On('ug-template:Claimed', function(source, pointIndex, amount) end)
```

## Project structure

```text
ug-template/
├── fxmanifest.lua
├── config.example.lua   copied to config.lua on the first start
├── shared/              the global and enums
├── server/              defaults, config, the claims feature, boot
├── client/              NUI bridge, panel, points, boot
├── locales/             en, pt
├── web/                 React page, built to web/dist
├── tests/               Lua 5.4 tests with native mocks, never shipped
├── skills/              task guides for AI agents, never shipped
├── AGENTS.md            rules for AI agents and humans
└── CLAUDE.md            points Claude Code to AGENTS.md
```

## Development

Clone ug-core and ug-lib next to this repository: the tests and the type check read them from `../ug-core` and
`../ug-lib`, or from the `UG_CORE` and `UG_LIB` paths.

```bash
# 1. LuaLS strict check, zero problems, with ug-core, ug-lib and the CfxLua natives as libraries
lua-language-server --check . --checklevel=Information --configpath=.luarc.json

# 2. Lua tests
for suite in tests/*.lua; do [ "$suite" = tests/helpers.lua ] || lua5.4 "$suite" || exit 1; done

# 3. Manifest and license headers
lua5.4 .github/scripts/check-repository.lua
```

The page needs Node.js 20.19 or newer:

```bash
cd web
npm ci
npm run lint && npm run typecheck && npm test
npm run build && npm run budget   # web/dist, at most 400 KB gzipped
npm run dev                       # browser preview with buttons that send what Lua would
```

For editor support, install the [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) and
[CfxLua](https://marketplace.visualstudio.com/items?itemName=overextended.cfxlua-vscode) VS Code extensions, and add
`../ug-core` and `../ug-lib` to `Lua.workspace.library` in your user settings.

### Working with AI agents

[AGENTS.md](AGENTS.md) holds the conventions and security rules every agent MUST follow. Claude Code reads it through
`CLAUDE.md`; Codex, Cursor and others read `AGENTS.md` directly. Task guides:

| Skill | For |
| --- | --- |
| [new-resource](skills/new-resource/SKILL.md) | Renaming the template, removing the example |
| [server-actions](skills/server-actions/SKILL.md) | Callbacks and net events |
| [nui-page](skills/nui-page/SKILL.md) | The page, its messages and callbacks |
| [config](skills/config/SKILL.md) | Owner config options |
| [database](skills/database/SKILL.md) | MySQL through oxmysql |
| [testing](skills/testing/SKILL.md) | Lua and web tests |
| [ug-core-api](skills/ug-core-api/SKILL.md) | What ug-core and ug-lib offer |

### Releases

Bump `version` in `fxmanifest.lua`, then push a matching `vX.Y.Z` tag. CI builds the page and publishes
`ug-template-vX.Y.Z.zip` with only what a server runs. Commit subjects become the release notes: write them for owners.

## Contributing

Branch off `dev` and open a pull request to `dev`. Commits and PR titles follow
[Conventional Commits](https://www.conventionalcommits.org): lowercase imperative subject, no trailing period, 72
characters at most. Scopes: `core`, `api`, `nui`, `web`, `config`, `locale`, `ci`, `deps`.

Read the [contributing guide](https://github.com/ugcore-project/.github/blob/main/CONTRIBUTING.md) and the
[Code of Conduct](https://github.com/ugcore-project/.github/blob/main/CODE_OF_CONDUCT.md).

## Security

Never report a vulnerability in a public issue. [Report it privately](https://github.com/ugcore-project/ug-template/security/advisories/new)
and read the [Security Policy](https://github.com/ugcore-project/.github/blob/main/SECURITY.md).

## License

ug-template is free software, licensed under the [GNU General Public License v3.0](LICENSE).

Copyright (C) 2026 UgCore Framework & Contributors.
