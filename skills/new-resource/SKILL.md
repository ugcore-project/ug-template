---
name: new-resource
description: Turn ug-template into a new UgCore resource. Use when starting a resource from this template, renaming it, or removing the example claim feature.
---

# New resource from ug-template

Goal: a resource named `ug-<name>` (or your own prefix) with every pattern kept and the example gone.

## 1. Pick the names

| Thing | Template | Example for `ug-garage` |
| --- | --- | --- |
| Resource, folder, repo | `ug-template` | `ug-garage` |
| Global | `UgTemplate` | `UgGarage` |
| Enum type prefix | `UgTemplate` (`UgTemplateNuiAction`) | `UgGarage` |
| Web package | `ug-template-web` | `ug-garage-web` |

The resource name MUST match the folder name: callbacks, events, NUI URLs and GlobalState keys are built from it.

## 2. Rename everywhere

Replace in every file, including `web/`, `tests/`, `.github/`, `README.md`, `AGENTS.md` and the skills:

- `ug-template` with the resource name.
- `UgTemplate` with the global.

Then check nothing is left:

```bash
grep -rn "ug-template\|UgTemplate" --exclude-dir=node_modules --exclude-dir=dist .
```

Places that are easy to miss:

- License header in every `.lua` and `web/src/**/*.ts(x)` file, and `HEADER_LINES` in `.github/scripts/check-repository.lua`.
- `.luarc.json` `diagnostics.globals`.
- `web/vite.config.ts`: the CSP `connect-src https://<resource>` and the plugin name.
- `web/src/lib/nui.ts`: the fallback resource name.
- `web/package.json` and `web/package-lock.json` `name`.
- `tests/helpers.lua`: `H.Resource`, and `UgTemplate = nil` in `H.Reset`.
- `GlobalState['ug-template:Config']` in `server/config.lua`, `client/boot.lua`, `client/panel.lua` and the tests.
- `fxmanifest.lua` `name`, `description`, `repository`.
- `.github/workflows/release.yml` archive name.

## 3. Remove the example

The claim feature is `server/claims.lua`, `client/panel.lua`, `client/points.lua`, `web/src/components/Panel.tsx`,
its tests and its config keys. Delete or rewrite them. Keep:

- `server/config.lua`, `server/boot.lua`, `client/nui.lua`, `client/boot.lua`: the plumbing.
- `shared/enums.lua`: empty the example values, keep the four enum groups.
- `tests/helpers.lua`: drop mocks you no longer use, add the ones you need.
- `web/src/lib/*`, `web/src/components/ui/*`, `web/src/store` pattern, `security.test.ts`.

No page? Delete `web/`, `ui_page`, the `web/dist` entries in `files {}`, the `web` job in `ci.yml`, the page build in
`release.yml`, `client/nui.lua` and `tests/nui.lua` enum checks.

No server state? Keep `server/config.lua` and `server/boot.lua` anyway: config still loads there.

## 4. Update the docs

- `README.md`: what it does, requirements, install, config, exports.
- `AGENTS.md`: the "What this is" section and the layout. Keep the rules.
- `.github/workflows/pr-title.yml`: scopes for your areas.

## 5. Verify

Run every check in AGENTS.md "Verification". Then start it on a server: the console prints
`[<resource>] v1.0.0 ready.` and F8 prints `[<resource>] Ready`.

## Docs

- https://ugcore.urging.ch/quickstart
- https://ugcore.urging.ch/developers/importing
- https://ugcore.urging.ch/developers/versioning
- https://ugcore.urging.ch/contributing/conventions
