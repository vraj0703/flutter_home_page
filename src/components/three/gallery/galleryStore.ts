/**
 * Gallery state store — replaces module-level mutable state.
 *
 * Minimal reactive store: components read via getters, write via setters.
 * Pub/sub event bus for navigation (CTA, Back, Connect, Skills, KBBack)
 * crosses the Three.js → React boundary.
 */

/* ── Scroll & Camera state ─────────────────────────── */

let _scrollProgress = 0
export function getScrollProgress() { return _scrollProgress }
export function setScrollProgress(p: number) { _scrollProgress = p }

let _scrollContainer: HTMLElement | null = null
export function setScrollContainer(el: HTMLElement | null) { _scrollContainer = el }

let _cameraResetRequested = false
export function isCameraResetRequested() { return _cameraResetRequested }
export function requestCameraReset() { _cameraResetRequested = true }
export function consumeCameraReset() { _cameraResetRequested = false }

/* ── Focus state ───────────────────────────────────── */

let _focusProjectIndex = -1
let _focusActive = false
let _focusListeners: Array<(state: { index: number; active: boolean }) => void> = []

export function getFocusState() { return { index: _focusProjectIndex, active: _focusActive } }
function _emitFocus() {
  const state = { index: _focusProjectIndex, active: _focusActive }
  _focusListeners.slice().forEach(fn => fn(state))
}
export function setClickTarget(i: number) {
  _focusProjectIndex = i; _focusActive = true
  _emitFocus()
}
export function clearFocus() {
  _focusActive = false; _focusProjectIndex = -1
  _emitFocus()
}
/** Subscribe to focus state changes. Fires immediately with current state, then on every setClickTarget / clearFocus. Returns unsubscribe. */
export function subscribeFocusChange(fn: (state: { index: number; active: boolean }) => void) {
  _focusListeners.push(fn)
  fn({ index: _focusProjectIndex, active: _focusActive })
  return () => { _focusListeners = _focusListeners.filter(f => f !== fn) }
}

/* ── Accessibility: prefers-reduced-motion ─────────
   Mirror of the OS media query, set from App.tsx via a useReducedMotion
   hook. Read inside useFrame callbacks that drive non-essential motion
   (corridor roll, keycap RGB wave, particle drift, camera click-orbit)
   to skip or flatten the animation when the user asks for less motion.
   WCAG 2.1 SC 2.3.3. */

let _reducedMotion = false
export function isReducedMotion() { return _reducedMotion }
export function setReducedMotion(v: boolean) { _reducedMotion = v }

/* ── Keyboard visibility state ─────────────────────
   Distinct from `_kbFocused` (user is orbiting it). `_kbVisible` tracks
   whether the keyboard is in its reveal position at all. During preload
   the keyboard is parked at y=-500 and frustum-culled — no pixels drawn,
   but every Keycap/Particles/Underglow useFrame would still tick on each
   Canvas frame. Keycaps, Particles, and Underglow read this flag at the
   top of their useFrame and early-return when false, so we don't pay CPU
   for animation the user can't see.
   Default: true — standalone keyboard mounts (e.g. a hypothetical
   KeyboardScene in isolation) keep animating without needing to opt in. */

let _kbVisible = true
export function isKbVisible() { return _kbVisible }
export function setKbVisible(v: boolean) { _kbVisible = v }

/* ── Keyboard focus state ──────────────────────────── */

let _kbFocused = false
let _kbFocusListeners: Array<(focused: boolean) => void> = []

export function isKbFocused() { return _kbFocused }
export function setKbFocused(v: boolean) {
  if (v === _kbFocused) return
  _kbFocused = v
  // Snapshot before iterating — a listener that unsubscribes itself would
  // otherwise mutate the array we're walking.
  _kbFocusListeners.slice().forEach(fn => fn(v))
}
export function subscribeKbFocus(fn: (focused: boolean) => void) {
  _kbFocusListeners.push(fn)
  fn(_kbFocused)
  return () => { _kbFocusListeners = _kbFocusListeners.filter(f => f !== fn) }
}

/* ── Scroll animation lock ─────────────────────────── */

let _scrollAnimating = false
export function isScrollAnimating() { return _scrollAnimating }
export function setScrollAnimating(v: boolean) { _scrollAnimating = v }

/* ── Gallery frameloop gate ─────────────────────────
   When the app transitions to the contact phase, the R3F Canvas is paused
   to free GPU cycles for Flutter (eliminates cross-engine GPU contention
   during the 1.6s transition overlap). Canvas subscribes and switches its
   `frameloop` prop to "never" → no useFrame ticks, no Bloom pass.            */

let _galleryFrameloopActive = true
let _galleryFrameloopListeners: Array<(active: boolean) => void> = []
export function isGalleryFrameloopActive() { return _galleryFrameloopActive }
export function setGalleryFrameloopActive(active: boolean) {
  if (active === _galleryFrameloopActive) return
  _galleryFrameloopActive = active
  _galleryFrameloopListeners.slice().forEach(fn => fn(active))
}
export function subscribeGalleryFrameloop(fn: (active: boolean) => void) {
  _galleryFrameloopListeners.push(fn)
  fn(_galleryFrameloopActive)
  return () => { _galleryFrameloopListeners = _galleryFrameloopListeners.filter(f => f !== fn) }
}

/* ── Navigation event bus ─────────────────────────── */

let _ctaClickListeners: Array<() => void> = []
export function subscribeCTAClick(fn: () => void) {
  _ctaClickListeners.push(fn)
  return () => { _ctaClickListeners = _ctaClickListeners.filter(f => f !== fn) }
}
export function fireCTAClick() { _ctaClickListeners.slice().forEach(fn => fn()) }

let _backClickListeners: Array<() => void> = []
export function subscribeBackClick(fn: () => void) {
  _backClickListeners.push(fn)
  return () => { _backClickListeners = _backClickListeners.filter(f => f !== fn) }
}
export function fireBackClick() { _backClickListeners.slice().forEach(fn => fn()) }

let _connectClickListeners: Array<() => void> = []
export function subscribeConnectClick(fn: () => void) {
  _connectClickListeners.push(fn)
  return () => { _connectClickListeners = _connectClickListeners.filter(f => f !== fn) }
}
export function fireConnectClick() { _connectClickListeners.slice().forEach(fn => fn()) }

let _skillsClickListeners: Array<() => void> = []
export function subscribeSkillsClick(fn: () => void) {
  _skillsClickListeners.push(fn)
  return () => { _skillsClickListeners = _skillsClickListeners.filter(f => f !== fn) }
}
export function fireSkillsClick() { _skillsClickListeners.slice().forEach(fn => fn()) }

let _kbBackClickListeners: Array<() => void> = []
export function subscribeKBBackClick(fn: () => void) {
  _kbBackClickListeners.push(fn)
  return () => { _kbBackClickListeners = _kbBackClickListeners.filter(f => f !== fn) }
}
export function fireKBBackClick() { _kbBackClickListeners.slice().forEach(fn => fn()) }

/* ── Project-open event (lateral-controls "Open ↗" button) ─
   The control panel renders the button and emits this event with the
   project id; App.tsx subscribes and dispatches per-project route handling.
   Per-project click behavior is owned by RAJ-165 to RAJ-171. */

let _projectOpenListeners: Array<(projectId: string) => void> = []
export function subscribeProjectOpen(fn: (projectId: string) => void) {
  _projectOpenListeners.push(fn)
  return () => { _projectOpenListeners = _projectOpenListeners.filter(f => f !== fn) }
}
export function fireProjectOpen(projectId: string) {
  _projectOpenListeners.slice().forEach(fn => fn(projectId))
}

/* ── Compound actions ──────────────────────────────── */

export function resetGalleryScroll() {
  if (_scrollContainer) _scrollContainer.scrollTop = 0
  _scrollProgress = 0
  _kbFocused = false
  _cameraResetRequested = true
}
