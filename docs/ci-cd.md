# CI/CD & screenshot pipeline

This project ships a GitHub Actions pipeline that tests the app, runs it inside
a Docker image, captures it starting in the container, and screenshots it across
several device/OS profiles — uploading the screenshots as downloadable
artifacts. This document explains how it works and why it is built this way.

## Pipeline overview

`.github/workflows/ci.yml` runs on push / PR to `main` (and `workflow_dispatch`):

| Job                | What it does                                                                 | Artifact                          |
| ------------------ | --------------------------------------------------------------------------- | --------------------------------- |
| `analyze-test`     | `flutter analyze` + `flutter test --coverage`                               | `coverage`                        |
| `web-screenshots`  | Builds + runs the app in Docker, captures startup, screenshots device matrix | `web-screenshots` (PNGs + log)    |
| `android-screenshot` | Launches the app on real Android API 30 & 34 emulators, screenshots each   | `android-screenshots-api{30,34}`  |

## How the app runs inside Docker

[`Dockerfile`](../Dockerfile) is multi-stage:

1. **build** — `ghcr.io/cirruslabs/flutter:3.38.7` runs `flutter build web
   --release`.
2. **serve** — `nginx:alpine` serves the static bundle on `:8080`.

A `HEALTHCHECK` curls the app shell, so the container is only reported *healthy*
once it is actually serving. CI waits on that signal and saves
`docker compose logs app` as `startup-web.log` — that is the **proof the
application started inside the container**.

## How we know it isn't broken

[`tooling/screenshots/capture.mjs`](../tooling/screenshots/capture.mjs) drives
the served app with Playwright. Flutter web paints to a `<canvas>`, so the
harness first enables Flutter's accessibility **semantics tree** (its trigger is
a 1×1px off-screen node, so the click is dispatched via JS), which exposes the
buttons and the counter value as real DOM nodes. For each device it then:

1. waits for `<flutter-view>` and screenshots the loaded state,
2. clicks **Increment ×2 → Add 100 → Decrement**,
3. asserts the counter walked **0 → 101**, the screen visibly changed (pixel
   diff), and no page errors were thrown,
4. screenshots the result.

Any device that fails an assertion makes the run exit non-zero — so a device
where the app is broken fails the pipeline rather than silently producing a
screenshot. The Android job additionally verifies the app process is alive
(`adb shell pidof`) before screenshotting, dumping a crash log on failure.

## Device / OS coverage

| Profile         | Where           | OS signal                         |
| --------------- | --------------- | --------------------------------- |
| Desktop Chrome  | Web + Playwright | Desktop viewport / UA            |
| iPhone 13       | Web + Playwright | iOS Safari UA, DPR, touch         |
| Pixel 5         | Web + Playwright | Android Chrome UA, DPR, touch     |
| iPad (gen 7)    | Web + Playwright | iPadOS viewport, touch            |
| Galaxy S9+      | Web + Playwright | Android viewport, touch           |
| Android API 30  | Emulator        | **Real** Android 11               |
| Android API 34  | Emulator        | **Real** Android 14               |

## Artifacts

- `web-screenshots/<device>-01-loaded.png` / `-02-after.png` — before/after per device.
- `web-screenshots/summary.json` — per-device pass/fail + counter values.
- `web-screenshots/startup-web.log` — container startup logs.
- `android-screenshots-api<level>/android-api<level>.png` — emulator screenshot.

## Design tradeoffs

- **Web path is fully dockerized**; the Android emulator runs on the runner's
  KVM rather than nested-in-Docker, which is flaky/unsupported on hosted
  runners. The Web matrix gives fast, deterministic cross-device coverage; the
  Android job adds real-OS confidence.
- **Playwright device emulation uses Chromium** with each device's viewport / UA
  / DPR / touch. For a canvas-rendered Flutter app this is deterministic and
  sufficient; true per-engine rendering (WebKit for iOS) is intentionally out of
  scope, with real Android coverage provided by the emulator job.

## Running locally

```bash
# Tests
flutter test

# Dockerized screenshots (needs Docker)
docker compose up --build --abort-on-container-exit --exit-code-from shots

# Screenshots without Docker (needs Node + Chrome)
flutter build web --release
python3 -m http.server 8000 --directory build/web &
cd tooling/screenshots && npm install && npx playwright install chromium
APP_URL=http://localhost:8000 ARTIFACTS_DIR=../../artifacts node capture.mjs
```
