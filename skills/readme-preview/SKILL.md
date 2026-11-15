---
name: readme-preview
description: Keep the README's features and images current - showcase scenes in web/src/dev/scenes.ts, captured to .github/assets with npm run capture. Use when adding or changing a screen, a feature an owner would notice, or the README.
---

# README preview

The README is what owners see before they install. It shows two things: the features, written by hand, and images
of the page, captured from the browser preview. Never take README images by hand: they go stale.

## Features

`## What you get` (or `## Features`) in the README. One bullet per feature an owner would notice, grouped, bold
lead-in, one or two short lines:

```md
- 🔒 **Secure server actions.** Callbacks with schema, rate limit and distance checks. Cheats flagged.
```

Update it in the same change as the feature.

## Scenes

A scene is a state of the page worth showing, in `web/src/dev/scenes.ts`:

```ts
{
  id: "claim-flow",            // file name: .github/assets/claim-flow.webp
  title: "Claiming",           // preview button and README caption
  animated: true,              // the whole run as an animated image; unset for a still of the end
  crop: "[data-panel]",        // crop to this element with a margin; unset for the whole 1600x900 screen
  steps: [
    { send: OPEN_READY, wait: 1200 },            // a message as Lua would send it
    { click: "[data-claim]", wait: 500 },        // a click, through a data- attribute
    { send: { action: NuiAction.Close }, wait: 600 },
  ],
}
```

- Use the same payloads Lua sends, with believable data: real place names, round amounts, no "test" or "foo".
- Add a `data-` attribute for any element a step clicks or a scene crops to. Never select by class.
- Animate what moves: flows, transitions, anything a still cannot explain. Keep runs under 6 seconds.
- Stills for the rest: one per distinct state (empty, filled, error).

`npm run dev` shows a button per scene. `?scene=<id>` plays one on load, `?clean` hides the buttons.

## Capture

```bash
cd web
npm run capture                 # every scene
npm run capture -- claim-flow   # only the scenes named
```

It builds the showcase (`vite build --mode showcase`, to the git-ignored `web/showcase-dist`), plays each scene in a
headless browser and writes `.github/assets/<id>.webp`: stills at 2x, animations at 30 frames per second at most.

The browser is `CAPTURE_BROWSER` (a path to Chrome, Edge or Chromium) when set, else the installed Chrome or Edge,
else a Chromium from `npx playwright-core install chromium`.

The backdrop is a gradient until `web/src/dev/backdrop.jpg` (or `.png`, `.webp`) exists: an in-game screenshot
without HUD, 1920x1080 or larger. Recapture every scene after adding or changing it.

## README

Show the main animation under the title, then the stills in a table:

```md
<img src=".github/assets/claim-flow.webp" alt="Claiming a point" width="384" />

| Ready to claim | On cooldown |
| :---: | :---: |
| <img src=".github/assets/claim-ready.webp" alt="Panel ready to claim" width="260" /> | ... |
```

Use `<img>` with a `width` (half the file width for stills, which are 2x) and an `alt` that says what happens.

## Checks

`lua5.4 .github/scripts/check-repository.lua` fails when a scene has no capture or the README shows an image that
does not exist. Commit the captures with the change that needs them. `.github/` never ships in the release archive.
