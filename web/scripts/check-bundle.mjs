/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Fails when the built JavaScript and CSS pass the budget, gzipped. Fonts are not counted. Run after `npm run build`.

import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { gzipSync } from "node:zlib";

const BUDGET_BYTES = 400 * 1024;
const assets = path.resolve(import.meta.dirname, "..", "dist", "assets");

let total = 0;

for (const name of readdirSync(assets)) {
  if (!/\.(js|css)$/.test(name)) {
    continue;
  }

  const size = gzipSync(readFileSync(path.join(assets, name))).length;

  total += size;
  console.log(`${name}: ${(size / 1024).toFixed(1)} KB gzipped`);
}

console.log(`Total: ${(total / 1024).toFixed(1)} KB of ${BUDGET_BYTES / 1024} KB`);

if (total === 0) {
  console.error("No JavaScript or CSS in dist/assets. Run npm run build first.");
  process.exit(1);
}

if (total > BUDGET_BYTES) {
  console.error("The bundle is over budget.");
  process.exit(1);
}
