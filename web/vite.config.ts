/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

import path from "node:path";
import { defineConfig, type Plugin } from "vite";
import react from "@vitejs/plugin-react";

// Production pages load nothing from the network: scripts and styles from the resource, callbacks to ug-template,
// images from the resource, other resources (nui://) or https. Only added on build: the dev server needs websockets.
const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
  "font-src 'self' data:",
  "img-src 'self' nui: https:",
  "connect-src 'self' https://ug-template",
  "object-src 'none'",
  "base-uri 'none'",
  "form-action 'none'",
].join("; ");

// Output names are fixed, so CEF caches them by URL. A build query string makes each build a new URL.
function productionHtml(): Plugin {
  const version = Date.now().toString(36);

  return {
    name: "ug-template-production-html",
    apply: "build",
    transformIndexHtml(html) {
      return html
        .replace(/((?:src|href)="\.\/assets\/[^"]+)"/g, `$1?v=${version}"`)
        .replace("<head>", `<head>\n    <meta http-equiv="Content-Security-Policy" content="${CONTENT_SECURITY_POLICY}" />`);
    },
  };
}

// NUI serves the build from a resource origin, so every asset path stays relative.
export default defineConfig({
  base: "./",
  plugins: [react(), productionHtml()],
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname, "./src"),
    },
  },
  build: {
    outDir: "dist",
    emptyOutDir: true,
    // One bundle with fixed names, listed in the manifest as web/dist/assets/*.
    rollupOptions: {
      output: {
        entryFileNames: "assets/[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: "assets/[name].[ext]",
      },
    },
  },
});
