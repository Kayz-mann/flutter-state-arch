// Multi-device screenshot + smoke-check harness for the Flutter web build.
//
// For each device profile it:
//   1. loads the served app and waits for Flutter to render (proves it started),
//   2. screenshots the loaded state,
//   3. enables Flutter's accessibility semantics tree (Flutter web paints to a
//      canvas, so buttons only become clickable DOM nodes once semantics are on),
//   4. drives the buttons (Increment x2 -> Add 100 -> Decrement),
//   5. screenshots the result, and
//   6. asserts the screen actually changed and that no page errors occurred.
//
// Any failing device makes the whole run exit non-zero — that is how CI knows
// the app is not broken on a given device/OS profile. Screenshots and a
// summary.json land in ARTIFACTS_DIR for upload as pipeline artifacts.

import { chromium, devices } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

const APP_URL = process.env.APP_URL || 'http://localhost:8000';
const ARTIFACTS_DIR = process.env.ARTIFACTS_DIR || path.resolve('artifacts');

// Device profiles. Each runs on Chromium with the descriptor's viewport, DPR,
// user-agent and touch settings (the "various device OS" matrix). Real Android
// OS coverage is provided separately by the emulator CI job.
const DEVICE_NAMES = [
  'Desktop Chrome',
  'iPhone 13',
  'Pixel 5',
  'iPad (gen 7)',
  'Galaxy S9+',
];

const slugify = (s) => s.replace(/[^a-z0-9]+/gi, '-').toLowerCase();

function pixelsChanged(aPath, bPath) {
  const a = PNG.sync.read(fs.readFileSync(aPath));
  const b = PNG.sync.read(fs.readFileSync(bPath));
  if (a.width !== b.width || a.height !== b.height) return Infinity;
  return pixelmatch(a.data, b.data, null, a.width, a.height, { threshold: 0.1 });
}

// Flutter web only builds its DOM semantics tree on demand, and its "Enable
// accessibility" trigger is a 1x1px element parked off-screen (so Playwright
// refuses to click it normally). Dispatching a click via JS turns the tree on,
// after which buttons and the counter value become real DOM nodes.
async function enableSemantics(page) {
  await page.evaluate(() => {
    const el = document.querySelector('flt-semantics-placeholder');
    el?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    el?.click?.();
  });
  await page.waitForSelector('flt-semantics[role="button"]', {
    state: 'attached',
    timeout: 15000,
  });
}

async function clickButton(page, name) {
  await page
    .getByRole('button', { name, exact: true })
    .first()
    .click({ timeout: 10000 });
  await page.waitForTimeout(300);
}

// Reads the counter from the semantics tree: it is the non-button node whose
// text is purely an integer (the painted "0" / "101" Text widget).
async function readCounter(page) {
  return page.evaluate(() => {
    const nodes = [...document.querySelectorAll('flt-semantics')];
    for (const n of nodes) {
      if (n.getAttribute('role') === 'button') continue;
      const t = (n.textContent || '').trim();
      if (/^-?\d+$/.test(t)) return Number(t);
    }
    return null;
  });
}

async function runDevice(browser, deviceName) {
  const descriptor = devices[deviceName];
  if (!descriptor) {
    return { deviceName, ok: false, errors: [`unknown device "${deviceName}"`] };
  }

  const slug = slugify(deviceName);
  const context = await browser.newContext({ ...descriptor });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push(`console: ${m.text()}`);
  });

  const loaded = path.join(ARTIFACTS_DIR, `${slug}-01-loaded.png`);
  const after = path.join(ARTIFACTS_DIR, `${slug}-02-after.png`);

  try {
    await page.goto(APP_URL, { waitUntil: 'load', timeout: 30000 });
    // App started: Flutter mounts <flutter-view>/<flt-glass-pane>.
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(1500); // let the first frame settle
    await page.screenshot({ path: loaded });

    await enableSemantics(page);
    const startCounter = await readCounter(page); // expected 0
    await clickButton(page, 'Increment'); // +1
    await clickButton(page, 'Increment'); // +1
    await clickButton(page, 'Add 100'); // +100
    await clickButton(page, 'Decrement'); // -1
    await page.waitForTimeout(700);
    await page.screenshot({ path: after });

    const endCounter = await readCounter(page);
    const changed = pixelsChanged(loaded, after);
    // The app is "working" on this device when the counter walked 0 -> 101 AND
    // the screen visibly changed AND no page errors were thrown.
    const ok =
      errors.length === 0 &&
      startCounter === 0 &&
      endCounter === 101 &&
      changed > 50;
    return {
      deviceName,
      slug,
      ok,
      startCounter,
      endCounter,
      expectedCounter: 101,
      changedPixels: changed,
      errors,
    };
  } catch (err) {
    errors.push(String(err));
    // Capture whatever state we reached to aid debugging.
    await page.screenshot({ path: after }).catch(() => {});
    return { deviceName, slug, ok: false, errors };
  } finally {
    await context.close();
  }
}

async function main() {
  fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
  console.log(`Capturing against ${APP_URL} -> ${ARTIFACTS_DIR}`);

  const browser = await chromium.launch();
  const results = [];
  for (const name of DEVICE_NAMES) {
    process.stdout.write(`- ${name} ... `);
    const r = await runDevice(browser, name);
    results.push(r);
    console.log(
      r.ok
        ? `ok (counter ${r.startCounter} -> ${r.endCounter}, ${r.changedPixels}px changed)`
        : `FAILED (counter ${r.startCounter} -> ${r.endCounter}): ${r.errors.join('; ') || 'assertion failed'}`,
    );
  }
  await browser.close();

  fs.writeFileSync(
    path.join(ARTIFACTS_DIR, 'summary.json'),
    JSON.stringify({ appUrl: APP_URL, results }, null, 2),
  );

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} device profiles passed.`);
  if (failed.length) {
    console.error(`Broken on: ${failed.map((r) => r.deviceName).join(', ')}`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
