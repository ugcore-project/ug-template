/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Dev builds only (`npm run dev`): a stand-in for the game, and buttons that send what Lua would.

import english from "../../../locales/en.json?raw";
import { handleMessage } from "@/store/panelStore";
import { ErrorCode, NuiAction, type NuiMessage } from "@/types/protocol";

const send = (message: NuiMessage) => handleMessage(message);

const page = (JSON.parse(english) as { page: Record<string, unknown> }).page;

send({ action: NuiAction.Config, payload: { labels: page, locale: "en" } });

const ACTIONS: { label: string; message: NuiMessage }[] = [
  { label: "Open (ready)", message: { action: NuiAction.Open, payload: { point: 1, label: "Legion Square stash", amount: 250, waitMs: 0 } } },
  { label: "Open (waiting)", message: { action: NuiAction.Open, payload: { point: 2, label: "Pier stash", amount: 500, waitMs: 95_000 } } },
  { label: "Result: paid", message: { action: NuiAction.Result, payload: { ok: true, amount: 250, waitMs: 600_000 } } },
  { label: "Result: too far", message: { action: NuiAction.Result, payload: { ok: false, error: ErrorCode.NoPermission } } },
  { label: "Close", message: { action: NuiAction.Close } },
];

export default function Preview() {
  return (
    <>
      {/* The game would be behind the page. */}
      <div className="fixed inset-0 -z-10 bg-gradient-to-br from-slate-700 via-slate-800 to-slate-950" />
      <div className="fixed left-4 top-4 flex flex-col gap-2">
        {ACTIONS.map((action) => (
          <button
            key={action.label}
            type="button"
            className="rounded-md bg-black/60 px-3 py-1.5 text-left text-xs text-white hover:bg-black/80"
            onClick={() => send(action.message)}
          >
            {action.label}
          </button>
        ))}
      </div>
    </>
  );
}
