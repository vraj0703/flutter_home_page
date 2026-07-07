# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All npm commands run from the repo root.

| Command | What it does |
|---|---|
| `npm run dev` | Vite dev server (React + Tailwind). Custom middleware in `vite.config.ts` serves `public/flutter/*` with correct MIME types — needed because Vite's SPA fallback would otherwise return `index.html` for `.js`/`.wasm` requests. |
| `npm run build` | `tsc -b && vite build` — TypeScript-only React build into `dist/`. Does **not** rebuild Flutter. |
| `npm run lint` | ESLint (flat config, `eslint.config.js`). |
| `npm run preview` | Serve `dist/` locally. |
| `npm run flutter:build` | `flutter build web --wasm --release --base-href /flutter/`. Run from repo root; the script `cd`s into `flutter/`. |
| `npm run flutter:build:js` | JS-only fallback build (no WASM). |
| `npm run flutter:copy` | `rsync` Flutter output into `public/flutter/`, **excluding `index.html`** (the React app keeps its own `public/flutter/index.html` shell — overwriting it breaks the iframe). |
| `npm run flutter:full` | `flutter:build` + `flutter:copy`. |
| `npm run build:all` | Full prod build: `flutter:full` then `vite build`. This is what CI runs. |

There are no test scripts in `package.json` — **do not run `npm test`**, it will fail. The parent `~/CLAUDE.md`'s blanket "run npm test before reporting done" rule does not apply in this repo. Flutter tests live in `flutter/test/` and run via `flutter test` from inside `flutter/` (single test: `flutter test test/path/to/file_test.dart`).

No standalone typecheck script either — `npm run build` runs `tsc -b` first, or use `npx tsc -b --noEmit` for a build-free check.

`flutter:copy` shells out to `rsync`, which is not on the default Windows PATH. Git Bash ships it at `C:\Program Files\Git\usr\bin` — add that to PATH or run the npm script from a Git Bash shell. CI (Ubuntu) has it natively.

`public/flutter/` is gitignored and regenerated on every build — never commit changes there.

## Architecture

This is a **hybrid React + Flutter web** portfolio. The two frontends share the page via an iframe and a typed postMessage bridge.

### Phase machine (the central state)

`src/App.tsx` owns a single `phase` state: `'flutter' | 'react' | 'contact'`.

- `flutter` — Flutter iframe visible, R3F gallery hidden (opacity 0, pointer-events none). Flutter handles the landing hero.
- `react` — Three.js gallery visible, Flutter iframe hidden + paused. R3F frameloop active.
- `contact` — Flutter iframe visible again on the contact route, R3F frameloop paused.

Phase transitions go through `transitionToPhase()` which:
1. Pre-routes Flutter (`flutterBridge.gotoHome()` / `gotoContact()`) **before** the wipe overlay so Flutter has ~800ms of background time to lay out before becoming visible.
2. Pauses/resumes R3F (`setGalleryFrameloopActive`) for GPU contention — Flutter's beach shader and R3F can't both render at 60fps.
3. Runs `SectionTransition` (GSAP wipe), commits the phase swap at midpoint, fires analytics.

`flutterBridge.resetHandoff()` must be called when re-entering Flutter — the `handoffTriggered` flag is one-shot and contact's "back to gallery" button re-fires it.

### Flutter ↔ React bridge

`src/bridge/flutterBridge.ts` is a singleton `FlutterBridge` instance. Do **not** add raw `postMessage` calls — route through this bridge so origin checks, queueing, and ack semantics stay centralized.

- Inbound types: `flutter-loading`, `flutter-ready`, `flutter-handoff`, `flutter-error`. Filtered by `event.origin === window.location.origin` to block extension/iframe spoofing.
- Outbound types: `goto-home`, `goto-contact`, `flutter-pause`, `flutter-resume`, `reduced-motion`. Versioned with `PROTOCOL_VERSION = '2.0'`; today's Flutter handles the legacy unversioned shape, the v2 generic `navigate` is shipped but not yet wired in Flutter.
- Messages sent before `flutter-ready` are queued and drained on ready.
- `FlutterEmbed.tsx` registers itself on the bridge via `flutterBridge.attach(iframe)` and uses callback refs so the bridge subscription can be a stable empty-deps effect.

### Cache busting

`vite.config.ts` injects a build-time `__BUILD_ID__` (Date.now in base36). `App.tsx` uses it in the iframe `src`: `/flutter/index.html?v=${__BUILD_ID__}`. A prior deploy poisoned Fastly with a stale Flutter response, so this and the SW cleanup block in `index.html` exist to recover users who cached the bad version. The cleanup script in `index.html` (force-unregister Flutter SW + clear caches on every page load) is intentionally aggressive and safe to remove a couple of weeks after the fix lands.

### Lighthouse / audit context

`IS_AUDIT_CONTEXT` in `App.tsx` detects `Chrome-Lighthouse|HeadlessChrome` and **skips mounting the Flutter iframe entirely**. The Flutter WASM bundle reliably trips Chrome DevTools Protocol response-body timeouts in CI, producing `PROTOCOL_TIMEOUT` before Lighthouse can score anything. When skipping, `flutterReady` starts `true` and the preloader's weighted progress (Flutter 80% / React 20%) collapses to React-only.

### Three.js gallery

Lives under `src/components/three/gallery/`. State is module-level mutable with getter/setter accessors in `galleryStore.ts` (not Zustand/Redux — small surface, R3F-ergonomic). Cross-boundary navigation (CTA, Back, Connect, Skills) goes through pub/sub event helpers in the same file. `isReducedMotion()` is read inline inside `useFrame` callbacks (camera, keycap RGB wave, particle drift) to flatten animation; the value is published from `App.tsx` via `setReducedMotion()` and forwarded to Flutter via `flutterBridge.sendReducedMotion()`.

`GalleryScene` uses `frameloop="never"` toggled via `setGalleryFrameloopActive` — the GPU defense against running R3F + Flutter shaders simultaneously. `display: none` was tried and caused a one-frame WebGL re-init flash on return, so opacity gating is the canonical pattern.

### Build chunking

`vite.config.ts` `manualChunks` splits the bundle into `three` (three + @react-three/*), `gsap`, and `react` (react-dom + react/*). Custom shader extensions `.frag` and `.vert` are added to `assetsInclude`.

### Firebase Hosting

`firebase.json` rewrites: `/privacy-policy` → `/privacy-policy.html`, `/static` → `/static/index.html`, then the SPA fallback `**/!(*.*)` → `/index.html`. Headers: `must-revalidate` for HTML, `max-age=31536000, immutable` for hashed JS/CSS/fonts/images **and for `/flutter/**/!(index.html)`** — Flutter's `index.html` itself must stay short-cached because rebuilds change the asset URLs it loads.

The Firebase project is `vishal-raj-space-firebase-home`. CI deploys to channel `live` only on push to `main` (PR runs build + Lighthouse but skip deploy).

### Flutter app structure

Entry: `flutter/lib/main.dart` → `FlameScene` (`views/scene.dart`) wraps `StatefulScene` in `MultiBlocProvider` (`SceneBloc` + `MenuDrawerCubit`). Uses **flame** for the canvas, **flutter_bloc** + **freezed** for state, and **my_feature_flags** (a path-linked package at `../../flutter/my_feature_flags` — outside this repo).

**Cross-repo coupling:** `MenuFeatures.defaultFlags` here is duplicated against `base_app`'s defaults in the linked package. There's no shared config yet, so changes to either side must be mirrored in the other repo or features will silently disagree at runtime.

### CI

`.github/workflows/deploy.yml`: Flutter SDK pinned to `3.38.3`, Node 22. Build job runs `npm run build:all`, uploads `dist/` as an artifact, runs Lighthouse with `continue-on-error: true` (thresholds in `.lighthouserc.json` are all `warn`). Deploy job downloads the artifact rather than rebuilding (saves ≈2 min). Bump the Flutter version in this workflow when you upgrade locally.

### PostHog proxy worker

`workers/posthog-proxy/` is a Cloudflare Worker (deployed separately via `wrangler`, not part of `npm run build:all`) that proxies `vishalraj.space/ingest/*` to PostHog. The route is configured in `wrangler.toml`.
