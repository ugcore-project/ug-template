/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Mirrors `UgTemplate.Enums` in shared/enums.lua. tests/nui.lua checks both sides match.

/** Messages Lua sends: `{ action, payload }`. */
export const NuiAction = {
  Config: "config",
  Open: "open",
  Result: "result",
  Close: "close",
} as const;

export type NuiAction = (typeof NuiAction)[keyof typeof NuiAction];

/** Callbacks the page posts. Lua checks every body. */
export const NuiCallback = {
  Ready: "ready",
  Claim: "claim",
  Close: "close",
} as const;

export type NuiCallback = (typeof NuiCallback)[keyof typeof NuiCallback];

/** ug-core error codes, `UgCore.Enums.Errors`. */
export const ErrorCode = {
  InvalidArgs: "invalid_args",
  NotFound: "not_found",
  NotLoaded: "not_loaded",
  RateLimited: "rate_limited",
  NoPermission: "no_permission",
  InsufficientFunds: "insufficient_funds",
  InsufficientItems: "insufficient_items",
  CannotCarry: "cannot_carry",
  Timeout: "timeout",
  InternalError: "internal_error",
} as const;

export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];

/** ug-lib's theme, from `GlobalState['ug-lib:Config'].theme`. */
export interface ThemeConfig {
  mode: string;
  colors: Record<string, string>;
  radius: string;
  font: string;
  scale: number;
}

export interface PageConfig {
  theme?: ThemeConfig;
  labels: Record<string, string>;
  locale: string;
}

export interface OpenPayload {
  point: number;
  label: string;
  amount: number;
  /** Time left before the next claim, in ms. 0 means ready. */
  waitMs: number;
}

export interface ClaimResult {
  ok: boolean;
  error?: ErrorCode;
  amount?: number;
  waitMs?: number;
}

export interface NuiMessage {
  action: NuiAction;
  payload?: unknown;
}
