/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Rules oxlint does not cover: no HTML from strings anywhere in the page, and `fetch` in lib/nui.ts only.

import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { expect, it } from "vitest";

const SOURCE = path.resolve(import.meta.dirname);

function sources(directory: string): string[] {
  return readdirSync(directory).flatMap((entry) => {
    const full = path.join(directory, entry);

    if (statSync(full).isDirectory()) {
      return sources(full);
    }

    return /\.tsx?$/.test(entry) && !/\.test\.tsx?$/.test(entry) ? [full] : [];
  });
}

const files = sources(SOURCE).map((file) => ({ file: path.relative(SOURCE, file), text: readFileSync(file, "utf8") }));

it("never builds HTML from strings", () => {
  for (const { file, text } of files) {
    expect(text, file).not.toMatch(/innerHTML|outerHTML|insertAdjacentHTML|dangerouslySetInnerHTML|document\.write/);
  }
});

it("calls fetch from lib/nui.ts only", () => {
  for (const { file, text } of files) {
    if (file !== path.join("lib", "nui.ts")) {
      expect(text, file).not.toMatch(/\bfetch\(/);
    }
  }
});
