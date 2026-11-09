/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Page state. Every Lua message is read through a checker: wrong shapes are dropped, never rendered as they came.

import { create } from "zustand";
import { flattenLabels } from "@/lib/labels";
import { applyTheme } from "@/lib/theme";
import { sendClaim, sendClose } from "@/lib/nui";
import { ErrorCode, NuiAction, type ClaimResult, type NuiMessage, type OpenPayload, type PageConfig, type ThemeConfig } from "@/types/protocol";

/** English labels until Lua sends the configured language. Same keys as `page` in locales/en.json. */
export const DEFAULT_LABELS: Record<string, string> = {
  reward: "Reward",
  claim: "Claim",
  claimed: "Claimed {amount}.",
  close: "Close",
  ready: "Ready to claim",
  wait: "Come back in {time}",
  "error.internal_error": "Something went wrong. Try again.",
};

interface PanelState {
  config: PageConfig;
  open: OpenPayload | null;
  /** When the wait ends, in `Date.now()` ms. */
  readyAt: number;
  result: ClaimResult | null;
  busy: boolean;
}

const initial: PanelState = {
  config: { labels: DEFAULT_LABELS, locale: "en" },
  open: null,
  readyAt: 0,
  result: null,
  busy: false,
};

export const usePanel = create<PanelState>(() => initial);

const ERRORS = Object.values(ErrorCode) as string[];
const MAX_TEXT = 64;

const isObject = (value: unknown): value is Record<string, unknown> => typeof value === "object" && value !== null && !Array.isArray(value);
const isNumber = (value: unknown): value is number => typeof value === "number" && Number.isFinite(value);
const text = (value: unknown): string | undefined => (typeof value === "string" && value.length > 0 ? value.slice(0, MAX_TEXT) : undefined);
const whole = (value: unknown, max: number): number | undefined => (isNumber(value) ? Math.min(Math.max(Math.round(value), 0), max) : undefined);

function readConfig(value: unknown): PageConfig | null {
  if (!isObject(value)) {
    return null;
  }

  const labels = isObject(value.labels) ? flattenLabels(value.labels) : {};
  const config: PageConfig = { labels: { ...DEFAULT_LABELS, ...labels }, locale: text(value.locale) ?? "en" };

  if (isObject(value.theme)) {
    config.theme = value.theme as unknown as ThemeConfig;
  }

  return config;
}

function readOpen(value: unknown): OpenPayload | null {
  if (!isObject(value)) {
    return null;
  }

  const point = whole(value.point, 64);
  const label = text(value.label);
  const amount = whole(value.amount, 1_000_000);

  if (!point || !label || amount === undefined) {
    return null;
  }

  return { point, label, amount, waitMs: whole(value.waitMs, 86_400_000) ?? 0 };
}

function readResult(value: unknown): ClaimResult | null {
  if (!isObject(value)) {
    return null;
  }

  const result: ClaimResult = { ok: value.ok === true };
  const amount = whole(value.amount, 1_000_000);
  const waitMs = whole(value.waitMs, 86_400_000);

  if (typeof value.error === "string" && ERRORS.includes(value.error)) {
    result.error = value.error as ErrorCode;
  } else if (!result.ok) {
    result.error = ErrorCode.InternalError;
  }

  if (amount !== undefined) result.amount = amount;
  if (waitMs !== undefined) result.waitMs = waitMs;

  return result;
}

export function handleMessage(message: NuiMessage): void {
  switch (message.action) {
    case NuiAction.Config: {
      const config = readConfig(message.payload);

      if (config) {
        applyTheme(config.theme);
        usePanel.setState({ config });
      }

      break;
    }
    case NuiAction.Open: {
      const open = readOpen(message.payload);

      if (open) {
        usePanel.setState({ open, readyAt: Date.now() + open.waitMs, result: null, busy: false });
      }

      break;
    }
    case NuiAction.Result: {
      const result = readResult(message.payload);

      if (result) {
        usePanel.setState((state) => ({
          result,
          busy: false,
          readyAt: result.waitMs !== undefined ? Date.now() + result.waitMs : state.readyAt,
        }));
      }

      break;
    }
    case NuiAction.Close:
      usePanel.setState({ open: null, result: null, busy: false });
      break;
    default:
      break;
  }
}

/** Listens for Lua messages. Returns the uninstaller. */
export function installMessages(): () => void {
  const listener = (event: MessageEvent<NuiMessage>) => {
    if (isObject(event.data) && typeof event.data.action === "string") {
      handleMessage(event.data);
    }
  };

  window.addEventListener("message", listener);

  return () => window.removeEventListener("message", listener);
}

/** Asks Lua to claim the open point. Lua answers with a result message. */
export function claim(): void {
  const { open, busy } = usePanel.getState();

  if (!open || busy) {
    return;
  }

  usePanel.setState({ busy: true, result: null });
  void sendClaim(open.point).then((accepted) => {
    if (!accepted) {
      usePanel.setState({ busy: false, result: { ok: false, error: ErrorCode.InternalError } });
    }
  });
}

/** Closes at once. Lua drops focus and confirms with a close message. */
export function close(): void {
  usePanel.setState({ open: null, result: null, busy: false });
  void sendClose();
}

/** Back to the first state, for tests. */
export function resetPanel(): void {
  usePanel.setState(initial, true);
}
