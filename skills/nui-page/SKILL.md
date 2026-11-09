---
name: nui-page
description: Build or change the NUI page of a UgCore resource (React, Vite, Tailwind 3, zustand, framer-motion). Use when adding a screen, a Lua-to-page message, a page-to-Lua callback, or UI components.
---

# NUI page

The page is drawn over the game in CEF (Chromium). It shows things and sends intent. It never decides anything.

## References

Read these before building something big. They are UgCore's most complete pages:

- **ug-appearance** (`ug-appearance/web`): full-screen editor.
  - `src/lib/nui.ts`: a throttled live queue for sliders, drag and camera, at most one post per 50 ms, newest value
    wins, deltas add up, `flushLive()` before save.
  - `src/components/ui/`: `Button`, `Surface`, `Text`, `Select` (a styled dropdown, since native selects draw OS
    colors in CEF), `Dialog` (a confirm that owns Escape while open), `Controls` (`Slider`, `Swatches`, `Stepper`,
    `Section`).
  - `src/store/editorStore.ts`: undo and redo history, dirty state, a bill computed by Lua.
  - `client/nui.lua`: a `READERS` table with one schema per callback, 30 per second budget, label keys checked by tests.
- **ug-target** (`ug-target/web`): an always-on overlay.
  - `src/components/Reticle.tsx`: spring animations with framer-motion.
  - `src/store/targetStore.ts`: option payloads read through checkers, timed results.
  - `client/nui.lua`: focus only while locked, hover at 30 per second.
- **ug-hud** (`ug-hud/web`): widgets with a drag-and-drop editor, saved settings parsed from untrusted JSON.

This template's page is the minimum of those: `web/src/lib/nui.ts`, `store/panelStore.ts`, `components/Panel.tsx`,
`components/ui/{Button,Surface,Text}.tsx`, `lib/theme.ts`.

## The protocol

Two enums, mirrored on both sides. `tests/nui.lua` fails when they differ.

| Lua `shared/enums.lua` | Page `web/src/types/protocol.ts` | Direction |
| --- | --- | --- |
| `UgTemplate.Enums.NuiAction` | `NuiAction` | Lua sends `{ action, payload }` with `SendNUIMessage` |
| `UgTemplate.Enums.NuiCallback` | `NuiCallback` | Page POSTs `https://<resource>/<callback>` |

Handshake: the page posts `ready` once it listens. `client/nui.lua` queues every message until then, and sends
`config` (ug-lib theme, labels, locale) first.

## Add a Lua-to-page message

1. Add the action to `NuiAction` in both enum files.
2. Lua: `Nui.Send(Action.X, payload)`. Payloads are plain tables. Lua sends empty tables as `[]`.
3. Page: add a reader in the store that checks the shape and bounds every value, and a `case` in `handleMessage`.
   Drop malformed payloads. Never render a value as it came.
4. Test: `App.test.tsx` sends the message through `handleMessage` and checks the DOM. Send a broken one too.

## Add a page-to-Lua callback

1. Add the callback to `NuiCallback` in both enum files.
2. Page: add a `sendX` in `web/src/lib/nui.ts`. Only this file calls `fetch` (`security.test.ts`).
   Send intent: ids, indexes, choices. Never amounts or results.
3. Lua: add a reader to `READERS` in `client/nui.lua` that checks the body with `UgCore.Schema`, and a handler with
   `Nui.On(Callback.X, handler)`. The handler MUST check the value against the current state (the open panel, the
   selected entity). Any script in CEF can post any body.
4. Anything that changes server state goes through a server callback (see `skills/server-actions`).
5. Raise `EVENTS_PER_SECOND` for live input, and throttle in the page like ug-appearance's live queue.
6. Test: `tests/client.lua` posts good and forged bodies with `H.PostNui` and checks what reached the server.

## Focus

- `SetNuiFocus(true, true)` when a screen opens, `SetNuiFocus(false, false)` when it closes, and on `onResourceStop`.
- Escape closes: listen on `window` in the page, post `close`. A dialog that is open MUST stop the event first
  (capture phase, see ug-appearance `Dialog.tsx`).
- Never leave focus on after an error. Every path that opens MUST have a path that closes.

## Look and feel

- Theme: `applyTheme(config.theme)` sets the owner's ug-lib colors, radius, font and scale. Use the Tailwind tokens
  (`bg-card`, `text-primary`, `text-muted-foreground`, `border-border`) so every UgCore screen matches.
- Tailwind stays on v3: FiveM's CEF does not reliably support v4's color functions.
- No `backdrop-blur` over the game: the game is not behind the CEF surface, so it renders black. A blurred backdrop
  over your own page content is fine.
- Animations with framer-motion springs. Respect reduced motion (`index.css` shortens everything).
- The page stays transparent. Only panels paint.
- Icons from `lucide-react`. Fonts self-hosted (`@fontsource-variable/inter`): the page loads nothing from the network.
- Player text from labels (`config.labels`, from `locales/<code>.json` `page`). Add every key to every locale.

## Rules the checks enforce

- `security.test.ts`: no `innerHTML`, `dangerouslySetInnerHTML`, `document.write`; `fetch` only in `lib/nui.ts`.
- `.oxlintrc.json`: no eval, no `new Function`, hooks rules.
- `vite.config.ts`: production CSP, fixed asset names with a cache-busting query.
- `scripts/check-bundle.mjs`: 400 KB gzipped JS and CSS.
- TypeScript strict with `exactOptionalPropertyTypes` and `noUncheckedIndexedAccess`.

## Develop

```bash
cd web
npm ci
npm run dev    # browser preview: src/dev/Preview.tsx sends what Lua would
```

`isEnvBrowser()` is true outside FiveM: posts go to `browserLog` instead of `fetch`. The preview is removed from
production builds.

## Docs

- https://ugcore.urging.ch/ug-lib/with-ugcore
- https://ugcore.urging.ch/ug-lib/customization
- https://ugcore.urging.ch/ug-lib/security
- https://ugcore.urging.ch/ug-appearance/security
- https://ugcore.urging.ch/ug-target/security
