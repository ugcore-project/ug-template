/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Dev and showcase builds only: a stand-in for the game, and buttons that play the scenes of scenes.ts.
// `?scene=<id>` plays one on load, `?clean` hides the buttons. `npm run capture` drives it through window.__showcase.

import english from "../../../locales/en.json?raw";
import { playScene, SCENES, type Area } from "@/dev/scenes";
import { handleMessage } from "@/store/panelStore";
import { NuiAction, type NuiMessage } from "@/types/protocol";

const send = (message: NuiMessage) => handleMessage(message);

const page = (JSON.parse(english) as { page: Record<string, unknown> }).page;

const BASE_CONFIG = { labels: page, locale: "en" };

send({ action: NuiAction.Config, payload: BASE_CONFIG });

// An in-game screenshot without HUD, saved as src/dev/backdrop.jpg (or .png, .webp), replaces the gradient.
const BACKDROPS = import.meta.glob<string>("./backdrop.{jpg,png,webp}", { eager: true, query: "?url", import: "default" });
const backdrop = Object.values(BACKDROPS)[0];

const params = new URLSearchParams(window.location.search);
const clean = params.has("clean");

declare global {
  interface Window {
    __showcase?: {
      scenes: { id: string; animated: boolean; crop: string | null }[];
      /** Plays a scene. Resolves with the area to crop to, null for the whole screen, undefined for an unknown id. */
      play: (id: string) => Promise<Area | null | undefined>;
      /** Previews an owner config: `__showcase.configure({ layout: { position: "top-left" } })`. */
      configure: (overrides: Record<string, unknown>) => void;
    };
  }
}

window.__showcase = {
  scenes: SCENES.map((scene) => ({ id: scene.id, animated: scene.animated === true, crop: scene.crop ?? null })),
  play: async (id) => {
    const scene = SCENES.find((entry) => entry.id === id);

    return scene ? playScene(scene, send) : undefined;
  },
  configure: (overrides) => send({ action: NuiAction.Config, payload: { ...BASE_CONFIG, ...overrides } }),
};

const initial = params.get("scene");

if (initial) {
  void window.__showcase.play(initial);
}

export default function Preview() {
  return (
    <>
      {/* The game would be behind the page. */}
      {backdrop ? (
        <img src={backdrop} alt="" className="fixed inset-0 -z-10 size-full object-cover" />
      ) : (
        <div className="fixed inset-0 -z-10 bg-gradient-to-br from-slate-700 via-slate-800 to-slate-950" />
      )}
      {!clean && (
        <div className="fixed left-4 top-4 flex flex-col gap-2">
          {SCENES.map((scene) => (
            <button
              key={scene.id}
              type="button"
              className="rounded-md bg-black/60 px-3 py-1.5 text-left text-xs text-white hover:bg-black/80"
              onClick={() => void playScene(scene, send)}
            >
              {scene.title}
            </button>
          ))}
          <button
            type="button"
            className="rounded-md bg-black/60 px-3 py-1.5 text-left text-xs text-white hover:bg-black/80"
            onClick={() => send({ action: NuiAction.Close })}
          >
            Close
          </button>
        </div>
      )}
    </>
  );
}
