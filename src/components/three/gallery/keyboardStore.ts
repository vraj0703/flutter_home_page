/**
 * Keyboard boot animation state.
 *
 * Moved here from module-level `let`-bindings in KeyboardScene.tsx. The old
 * arrangement had three `let` variables mutated from useFrame callbacks in
 * multiple components and reset via an imported function from CameraRig —
 * a cross-file mutable singleton disguised as module scope. It:
 *   - broke React's component model (couldn't mount two keyboards),
 *   - made testing impossible,
 *   - was a tearing hazard under React's concurrent rendering.
 *
 * The shape here is still mutable — that's deliberate. These values are
 * read and written at 60+ fps from useFrame, and the per-frame function-
 * call overhead of getter/setter wrappers would be wasted. Exposing a
 * single `bootState` object with documented fields keeps the hot path
 * allocation-free while making the file of record explicit.
 *
 * Writers: KeyboardScene's <Keyboard> component (advances phase) and
 *   CameraRig (calls resetBoot on Skills click).
 * Readers: KeyboardScene's <Keycap> and <Underglow>.
 */

export const BOOT_DURATION = 1.5
export const BOOT_FLASH_DURATION = 0.35

export interface BootState {
  /** 0 = dormant, 1 = fully booted. Ramps linearly over BOOT_DURATION seconds. */
  phase: number
  /** clock.elapsedTime when boot started, or -1 before first tick. */
  startTime: number
  /** clock.elapsedTime when the power-on flash fired, or -1 if not yet. */
  flashTime: number
}

export const bootState: BootState = {
  phase: 0,
  startTime: -1,
  flashTime: -1,
}

/** Reset boot animation to dormant. Called when user clicks Skills button so
 *  the keyboard re-plays its entrance on every visit. */
export function resetBoot() {
  bootState.phase = 0
  bootState.startTime = -1
  bootState.flashTime = -1
}
