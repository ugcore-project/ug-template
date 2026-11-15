/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Showcase scenes: what the page shows for the README. The preview plays them, and `npm run capture` saves each one
// to .github/assets/<id>.webp, animated when `animated` is set. Add a scene for every screen worth showing.

import { ErrorCode, NuiAction, type NuiMessage } from "@/types/protocol";

/** One step: a message as Lua would send it, or a click on an element, then a pause. */
export interface SceneStep {
  send?: NuiMessage;
  /** CSS selector of the element to click. */
  click?: string;
  /** Milliseconds before the next step. */
  wait?: number;
}

export interface Scene {
  /** File name of the capture: lowercase, digits and dashes. */
  id: string;
  title: string;
  steps: SceneStep[];
  /** Captured as an animated image of the whole run, instead of a still of the end. */
  animated?: boolean;
  /** CSS selector of the element the capture is cropped to, with a margin. The whole screen when unset. */
  crop?: string;
}

/** A screen area in CSS pixels. */
export interface Area {
  x: number;
  y: number;
  width: number;
  height: number;
}

const PANEL = "[data-panel]";

const OPEN_READY: NuiMessage = {
  action: NuiAction.Open,
  payload: { point: 1, label: "Legion Square stash", amount: 250, waitMs: 0 },
};

export const SCENES: Scene[] = [
  {
    id: "claim-ready",
    title: "Ready to claim",
    crop: PANEL,
    steps: [{ send: OPEN_READY }],
  },
  {
    id: "claim-cooldown",
    title: "On cooldown",
    crop: PANEL,
    steps: [{ send: { action: NuiAction.Open, payload: { point: 2, label: "Pier stash", amount: 500, waitMs: 95_000 } } }],
  },
  {
    id: "claim-too-far",
    title: "Refused by the server",
    crop: PANEL,
    steps: [{ send: OPEN_READY }, { send: { action: NuiAction.Result, payload: { ok: false, error: ErrorCode.NoPermission } } }],
  },
  {
    id: "claim-flow",
    title: "Claiming",
    animated: true,
    crop: PANEL,
    steps: [
      { send: OPEN_READY, wait: 1200 },
      { click: "[data-claim]", wait: 500 },
      { send: { action: NuiAction.Result, payload: { ok: true, amount: 250, waitMs: 600_000 } }, wait: 2000 },
      { send: { action: NuiAction.Close }, wait: 600 },
    ],
  },
];

/**
 * Plays a scene through `send`. Resolves after the last step's pause, with the area the crop element covered after
 * any step, or null without a crop or when it never showed.
 */
export async function playScene(scene: Scene, send: (message: NuiMessage) => void): Promise<Area | null> {
  let area: Area | null = null;

  for (const step of scene.steps) {
    if (step.send) {
      send(step.send);
    }

    if (step.click) {
      document.querySelector<HTMLElement>(step.click)?.click();
    }

    await new Promise((resolve) => setTimeout(resolve, step.wait ?? 0));

    const box = scene.crop ? document.querySelector(scene.crop)?.getBoundingClientRect() : undefined;

    if (box && box.width > 0) {
      const left = Math.min(area?.x ?? box.left, box.left);
      const top = Math.min(area?.y ?? box.top, box.top);
      const right = Math.max(area ? area.x + area.width : box.right, box.right);
      const bottom = Math.max(area ? area.y + area.height : box.bottom, box.bottom);

      area = { x: left, y: top, width: right - left, height: bottom - top };
    }
  }

  return area;
}
