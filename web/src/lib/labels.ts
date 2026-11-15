/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

/** Flattens a locale group to dotted keys, as Lua sends them: `{ camera: { face } }` becomes `camera.face`. */
export function flattenLabels(group: Record<string, unknown>, prefix = ""): Record<string, string> {
  const labels: Record<string, string> = {};

  for (const [key, value] of Object.entries(group)) {
    if (typeof value === "string") {
      labels[prefix + key] = value;
    } else if (value && typeof value === "object") {
      Object.assign(labels, flattenLabels(value as Record<string, unknown>, `${prefix}${key}.`));
    }
  }

  return labels;
}
