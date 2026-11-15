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

/** Where the panel sits. */
export const Position = {
  TopLeft: "top-left",
  TopRight: "top-right",
  BottomLeft: "bottom-left",
  BottomRight: "bottom-right",
} as const;

export type Position = (typeof Position)[keyof typeof Position];

/** Panel parts owners MAY turn off. */
export const Feature = {
  Prompt: "prompt",
  Countdown: "countdown",
} as const;

export type Feature = (typeof Feature)[keyof typeof Feature];

/** The owner's panel, from config.lua `layout`. */
export interface PanelLayout {
  position: Position;
  /** Width in rem. */
  width: number;
  animations: boolean;
}

export type Features = Record<Feature, boolean>;

/** ug-lib's theme with the owner's theme of this resource merged on top, by Lua. */
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
  layout: PanelLayout;
  features: Features;
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
