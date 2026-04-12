/**
 * Gallery state store — replaces module-level mutable state.
 *
 * This is a minimal reactive store (no Zustand dependency) that centralizes
 * all cross-component gallery state. Components read via getGalleryState()
 * and write via the exported setters. The pub/sub event bus for navigation
 * events (CTA click, Back, Connect) remains as it correctly crosses the
 * Three.js → React boundary.
 */

/* ── Scroll & Camera state ─────────────────────────── */

let _scrollProgress = 0
export function getScrollProgress() { return _scrollProgress }
export function setScrollProgress(p: number) { _scrollProgress = p }

let _scrollContainer: HTMLElement | null = null
export function getScrollContainer() { return _scrollContainer }
export function setScrollContainer(el: HTMLElement | null) { _scrollContainer = el }

let _cameraResetRequested = false
export function isCameraResetRequested() { return _cameraResetRequested }
export function requestCameraReset() { _cameraResetRequested = true }
export function consumeCameraReset() { _cameraResetRequested = false }

/* ── Focus state ───────────────────────────────────── */

let _focusProjectIndex = -1
let _focusActive = false
export function getFocusState() { return { index: _focusProjectIndex, active: _focusActive } }
export function setClickTarget(i: number) { _focusProjectIndex = i; _focusActive = true }
export function clearFocus() { _focusActive = false; _focusProjectIndex = -1 }

/* ── Keyboard focus state ──────────────────────────── */

let _kbFocused = false
let _kbFocusListeners: Array<(focused: boolean) => void> = []

export function isKbFocused() { return _kbFocused }
export function setKbFocused(v: boolean) {
  if (v === _kbFocused) return
  _kbFocused = v
  _kbFocusListeners.forEach(fn => fn(v))
}
export function subscribeKbFocus(fn: (focused: boolean) => void) {
  _kbFocusListeners.push(fn)
  fn(_kbFocused)
  return () => { _kbFocusListeners = _kbFocusListeners.filter(f => f !== fn) }
}

/* ── Scroll unlock request ─────────────────────────── */

let _scrollUnlockRequested = false
export function isScrollUnlockRequested() { return _scrollUnlockRequested }
export function requestScrollUnlock() { _scrollUnlockRequested = true }
export function consumeScrollUnlock() { _scrollUnlockRequested = false }

/* ── Navigation event bus (CTA, Back, Connect) ─────── */

let _ctaClickListeners: Array<() => void> = []
export function subscribeCTAClick(fn: () => void) {
  _ctaClickListeners.push(fn)
  return () => { _ctaClickListeners = _ctaClickListeners.filter(f => f !== fn) }
}
export function fireCTAClick() { _ctaClickListeners.forEach(fn => fn()) }

let _backClickListeners: Array<() => void> = []
export function subscribeBackClick(fn: () => void) {
  _backClickListeners.push(fn)
  return () => { _backClickListeners = _backClickListeners.filter(f => f !== fn) }
}
export function fireBackClick() { _backClickListeners.forEach(fn => fn()) }

let _connectClickListeners: Array<() => void> = []
export function subscribeConnectClick(fn: () => void) {
  _connectClickListeners.push(fn)
  return () => { _connectClickListeners = _connectClickListeners.filter(f => f !== fn) }
}
export function fireConnectClick() { _connectClickListeners.forEach(fn => fn()) }

/* ── Compound actions ──────────────────────────────── */

export function resetGalleryScroll() {
  if (_scrollContainer) _scrollContainer.scrollTop = 0
  _scrollProgress = 0
  _kbFocused = false
  _cameraResetRequested = true
}
