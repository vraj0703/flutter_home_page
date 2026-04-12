/**
 * Gallery module barrel export.
 * Re-exports all public APIs from the decomposed gallery modules.
 */

// Store (replaces module-level mutable state)
export {
  getScrollProgress, setScrollProgress,
  getScrollContainer, setScrollContainer,
  isCameraResetRequested, requestCameraReset, consumeCameraReset,
  getFocusState, setClickTarget, clearFocus,
  isKbFocused, setKbFocused, subscribeKbFocus,
  isScrollUnlockRequested, requestScrollUnlock, consumeScrollUnlock,
  subscribeCTAClick, fireCTAClick,
  subscribeBackClick, fireBackClick,
  subscribeConnectClick, fireConnectClick,
  resetGalleryScroll,
} from './galleryStore'

// Dimensions
export * from './dimensions'

// Utils
export { damp, tmpVec3, useFrameSize, useFocusDistance } from './utils'

// Materials
export { useMaterials, type MaterialPalette } from './materials'

// Textures
export { useProjectTexture } from './textures'
