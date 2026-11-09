/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import { readFileSync } from "node:fs";
import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MotionGlobalConfig } from "framer-motion";
import { beforeEach, describe, expect, it, vi } from "vitest";
import App from "@/App";
import { duration, fill } from "@/lib/format";
import { handleMessage, resetPanel } from "@/store/panelStore";
import { NuiAction } from "@/types/protocol";

MotionGlobalConfig.skipAnimations = true;

const nui = vi.hoisted(() => ({
  isEnvBrowser: () => false,
  sendReady: vi.fn(async () => true),
  sendClaim: vi.fn(async (_point: number) => true),
  sendClose: vi.fn(async () => true),
}));

vi.mock("@/lib/nui", () => nui);

const english = JSON.parse(readFileSync("../locales/en.json", "utf8")) as { page: Record<string, unknown> };

const send = (action: string, payload?: unknown) => act(() => handleMessage({ action: action as NuiAction, payload }));
const panel = () => document.querySelector("[data-panel]");

function openAt(waitMs: number) {
  render(<App />);
  send(NuiAction.Config, { labels: english.page, locale: "en" });
  send(NuiAction.Open, { point: 2, label: "Pier stash", amount: 500, waitMs });
}

beforeEach(() => {
  vi.clearAllMocks();
  act(() => resetPanel());
});

describe("panel", () => {
  it("says ready once, and shows nothing until Lua opens it", () => {
    render(<App />);

    expect(nui.sendReady).toHaveBeenCalledTimes(1);
    expect(panel()).toBeNull();
  });

  it("claims the open point and shows the server's answer", () => {
    openAt(0);

    fireEvent.click(screen.getByRole("button", { name: "Claim" }));

    expect(nui.sendClaim).toHaveBeenCalledWith(2);
    expect(screen.getByRole("button", { name: "Claim" }).hasAttribute("disabled")).toBe(true);

    send(NuiAction.Result, { ok: true, amount: 500, waitMs: 60_000 });

    expect(document.querySelector("[data-result]")?.getAttribute("data-result")).toBe("ok");
    expect(screen.getByText(/Come back in/)).toBeTruthy();
  });

  it("shows error codes as text and never what Lua did not send", () => {
    openAt(0);
    send(NuiAction.Result, { ok: false, error: "no_permission" });

    expect(screen.getByText("You can't do that here.")).toBeTruthy();

    send(NuiAction.Result, { ok: false, error: "<img src=x>" });

    expect(document.querySelector("[data-result]")?.getAttribute("data-result")).toBe("internal_error");
  });

  it("drops broken messages", () => {
    render(<App />);
    send(NuiAction.Open, { point: "1", label: "x", amount: 5 });
    send(NuiAction.Open, null);

    expect(panel()).toBeNull();
  });

  it("waits out the cooldown and closes with Escape", async () => {
    openAt(65_000);

    expect(screen.getByRole("button", { name: "Claim" }).hasAttribute("disabled")).toBe(true);
    expect(screen.getByText("Come back in 1:05")).toBeTruthy();

    fireEvent.keyDown(window, { key: "Escape" });

    expect(nui.sendClose).toHaveBeenCalledTimes(1);
    await waitFor(() => expect(panel()).toBeNull());
  });
});

describe("helpers", () => {
  it("fills placeholders and formats waits", () => {
    expect(fill("In {time} for {who}", { time: "1:00" })).toBe("In 1:00 for {who}");
    expect(duration(0)).toBe("0:00");
    expect(duration(61_000)).toBe("1:01");
    expect(duration(3_723_000)).toBe("1:02:03");
  });
});
