/*

    ug-template - https://github.com/ugcore-project
    Copyright (C) 2026 UgCore Framework & Contributors
    Licensed under the GNU General Public License. See LICENSE for details.

*/

// Captures every scene of src/dev/scenes.ts to .github/assets/<id>.webp for the README. Run with `npm run capture`,
// which builds the showcase first. `npm run capture -- claim-flow` captures only the scenes named.
// Uses CAPTURE_BROWSER (a Chromium-based browser's path) when set, else the installed Chrome or Edge, else a Chromium
// from `npx playwright-core install chromium`.

import { createReadStream, existsSync, mkdirSync, statSync } from "node:fs";
import { createServer } from "node:http";
import path from "node:path";
import { chromium } from "playwright-core";
import sharp from "sharp";

const ROOT = path.resolve(import.meta.dirname, "..");
const DIST = path.join(ROOT, "showcase-dist");
const OUT = path.resolve(ROOT, "../.github/assets");
const WIDTH = 1600;
const HEIGHT = 900;
// Pixels per CSS pixel: text stays sharp on high-density screens.
const SCALE = 2;
// CSS pixels kept around a scene's crop element.
const CROP_MARGIN = 32;
// Shortest time between two frames of an animated capture: 30 frames per second at most.
const FRAME_MS = 33;
// Animated captures of the whole screen are scaled down: a README shows them at about 800 px anyway.
const ANIMATED_WIDTH = 960;
// A cropped animation wider than this is scaled down: past it, the file grows faster than a README shows.
const ANIMATED_MAX_WIDTH = 1000;
// Framer Motion transitions finish before a still is taken.
const SETTLE_MS = 700;
// How long the end of an animated capture holds before it loops.
const LAST_FRAME_MS = 1500;
const TYPES = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json",
  ".png": "image/png", ".jpg": "image/jpeg", ".webp": "image/webp", ".svg": "image/svg+xml", ".woff2": "font/woff2" };

if (!existsSync(path.join(DIST, "index.html"))) {
  console.error("showcase-dist is missing. Run `npm run capture`, which builds it first.");
  process.exit(1);
}

/** Serves showcase-dist on a free local port. */
function serve() {
  const server = createServer((request, response) => {
    const url = new URL(request.url ?? "/", "http://localhost");
    const file = path.join(DIST, decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname));

    if (!file.startsWith(DIST) || !existsSync(file) || !statSync(file).isFile()) {
      response.writeHead(404).end();

      return;
    }

    response.writeHead(200, { "Content-Type": TYPES[path.extname(file)] ?? "application/octet-stream" });
    createReadStream(file).pipe(response);
  });

  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

async function launch() {
  const executablePath = process.env.CAPTURE_BROWSER;

  if (executablePath) {
    return chromium.launch({ executablePath });
  }

  for (const channel of ["chrome", "msedge", undefined]) {
    try {
      return await chromium.launch(channel ? { channel } : {});
    } catch {
      // Next one.
    }
  }

  console.error("No browser found. Install Chrome or Edge, run `npx playwright-core install chromium`, or set "
    + "CAPTURE_BROWSER to the path of a Chromium-based browser.");
  process.exit(1);
}

/** Opens the showcase clean and waits until fonts and the scene API are ready. */
async function open(browser, base) {
  const page = await browser.newPage({ viewport: { width: WIDTH, height: HEIGHT }, deviceScaleFactor: SCALE });

  await page.goto(`${base}/?clean`);
  await page.waitForFunction(() => window.__showcase !== undefined);
  await page.evaluate(() => document.fonts.ready);

  return page;
}

/** The area around a crop, with a margin, inside the screen. Null keeps the whole screen. */
function padded(area) {
  if (!area) {
    return null;
  }

  const x = Math.max(0, Math.floor(area.x - CROP_MARGIN));
  const y = Math.max(0, Math.floor(area.y - CROP_MARGIN));

  return {
    x,
    y,
    width: Math.min(WIDTH, Math.ceil(area.x + area.width + CROP_MARGIN)) - x,
    height: Math.min(HEIGHT, Math.ceil(area.y + area.height + CROP_MARGIN)) - y,
  };
}

async function still(page, scene) {
  await page.evaluate((id) => window.__showcase.play(id), scene.id);
  await page.waitForTimeout(SETTLE_MS);

  // Measured after the transitions: an element that scales in is smaller while it opens.
  const box = scene.crop ? await page.locator(scene.crop).first().boundingBox() : null;
  const clip = padded(box);
  const png = await page.screenshot({ type: "png", ...(clip ? { clip } : {}) });

  await sharp(png).webp({ quality: 92 }).toFile(path.join(OUT, `${scene.id}.webp`));
}

/** Records the scene with the Chromium screencast: a frame each time the page paints, with its timestamp. */
async function animated(page, scene) {
  const session = await page.context().newCDPSession(page);
  const frames = [];

  session.on("Page.screencastFrame", (frame) => {
    frames.push({ data: Buffer.from(frame.data, "base64"), at: frame.metadata.timestamp * 1000 });
    void session.send("Page.screencastFrameAck", { sessionId: frame.sessionId }).catch(() => {});
  });

  // A cropped capture keeps every pixel; a whole screen is scaled down to stay small.
  const maxWidth = scene.crop ? WIDTH * SCALE : ANIMATED_WIDTH;
  const maxHeight = Math.round((maxWidth * HEIGHT) / WIDTH);

  await session.send("Page.startScreencast", { format: "png", maxWidth, maxHeight, everyNthFrame: 1 });
  await page.waitForTimeout(200);

  const area = await page.evaluate((id) => window.__showcase.play(id), scene.id);

  await page.waitForTimeout(SETTLE_MS);
  await session.send("Page.stopScreencast");

  // Frames closer than FRAME_MS are dropped: the time they held goes to the frame before.
  const timeline = [];

  for (const frame of frames) {
    const last = timeline[timeline.length - 1];

    if (!last || frame.at - last.at >= FRAME_MS) {
      timeline.push(frame);
    }
  }

  if (timeline.length === 0) {
    throw new Error(`${scene.id}: no frames recorded`);
  }

  const delays = timeline.map((frame, index) => {
    const next = timeline[index + 1];

    return next ? Math.round(next.at - frame.at) : LAST_FRAME_MS;
  });
  const first = await sharp(timeline[0].data).metadata();
  const ratio = first.width / WIDTH;
  const clip = padded(area);
  const region = clip && {
    left: Math.round(clip.x * ratio),
    top: Math.round(clip.y * ratio),
    width: Math.min(first.width - Math.round(clip.x * ratio), Math.round(clip.width * ratio)),
    height: Math.min(first.height - Math.round(clip.y * ratio), Math.round(clip.height * ratio)),
  };
  const images = await Promise.all(
    timeline.map(async (frame) => {
      const image = sharp(frame.data).resize(first.width, first.height);
      // Sharp applies one resize per pipeline, so the crop is encoded before the second one.
      const cropped = await (region ? image.extract(region) : image).png().toBuffer();

      return sharp(cropped).resize({ width: ANIMATED_MAX_WIDTH, withoutEnlargement: true }).png().toBuffer();
    }),
  );

  await sharp(images, { join: { animated: true } })
    .webp({ quality: 90, effort: 6, loop: 0, delay: delays })
    .toFile(path.join(OUT, `${scene.id}.webp`));
}

const wanted = process.argv.slice(2);
const server = await serve();
const base = `http://127.0.0.1:${server.address().port}`;
const browser = await launch();

mkdirSync(OUT, { recursive: true });

try {
  const page = await open(browser, base);
  const scenes = await page.evaluate(() => window.__showcase.scenes);

  await page.close();

  const unknown = wanted.filter((id) => !scenes.some((scene) => scene.id === id));

  if (unknown.length > 0) {
    throw new Error(`unknown scene(s): ${unknown.join(", ")}`);
  }

  for (const scene of scenes) {
    if (wanted.length > 0 && !wanted.includes(scene.id)) {
      continue;
    }

    const sceneOpen = await open(browser, base);

    await (scene.animated ? animated(sceneOpen, scene) : still(sceneOpen, scene));
    await sceneOpen.close();

    const kb = (statSync(path.join(OUT, `${scene.id}.webp`)).size / 1024).toFixed(0);

    console.log(`${scene.animated ? "animated" : "still   "}  .github/assets/${scene.id}.webp  ${kb} KB`);
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
} finally {
  await browser.close();
  server.close();
}
