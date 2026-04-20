import * as THREE from 'three'
import {
  TEST_PAN_END, WALL_LOCK_Z, KB_ENTRY_X, KB_X, KB_Z,
} from '../dimensions'

// Module-scratch vectors — mutated in CameraRig.useFrame in place to avoid
// per-frame allocations. Never reference these outside useFrame.
export const _tPos = new THREE.Vector3()
export const _tLook = new THREE.Vector3()
export const _scratchFwd = new THREE.Vector3()

// Final keyboard hero-shot view — single source of truth shared by the
// scripted camera animation and KeyboardOrbit's target.
export const KB_VIEW_TARGET_Y = 0.45
export const KB_VIEW_CAM_DY = 1.64   // 5.3 * cos(72°)
export const KB_VIEW_CAM_DZ = 5.04   // 5.3 * sin(72°)

/* ── Click-driven camera animation waypoints ─────────
   A (pan end) → B (turn to face KB) → C (dolly into room) → D (hero shot)
   All positions/lookAts computed from gallery dimensions. */

// A: Starting pose — camera at pan end, looking along back wall
export const ANIM_A_POS = new THREE.Vector3(TEST_PAN_END, 0.6, WALL_LOCK_Z)
export const ANIM_A_LOOK = new THREE.Vector3(TEST_PAN_END, 0.6, WALL_LOCK_Z - 4)

// B: Turn — camera stays put, looks toward KB entry
export const ANIM_B_POS = new THREE.Vector3(TEST_PAN_END, 0.8, WALL_LOCK_Z)
export const ANIM_B_LOOK = new THREE.Vector3(KB_ENTRY_X, 0.8, WALL_LOCK_Z)

// C: Apex — camera flies HIGH over the keyboard, looking straight down.
// This is the midpoint of the 180° orbit; camera arcs from corridor side
// (Beat 2 start) up over the keyboard (Beat 2 end) then down to the
// opposite side (Beat 3 end / hero).
export const ANIM_C_POS = new THREE.Vector3(KB_X, 4.5, KB_Z + 0.5)
export const ANIM_C_LOOK = new THREE.Vector3(KB_X, 0.5, KB_Z)

// D: Hero — camera lands on the OPPOSITE side of the keyboard from where it
// started. The keyboard's LANGUAGES row (local +Z, rotated to world +X by
// FloatingKB's PI/2 combined rotation) now faces the camera directly = the
// natural "sit-down-to-type" hero shot.
export const ANIM_D_POS = new THREE.Vector3(KB_X + KB_VIEW_CAM_DZ, KB_VIEW_TARGET_Y + KB_VIEW_CAM_DY, KB_Z)
export const ANIM_D_LOOK = new THREE.Vector3(KB_X, KB_VIEW_TARGET_Y, KB_Z)

/* ── Animation timing (ms) ─────────────────────────── */
export const BEAT_1_MS = 700    // A → B: turn to face KB
export const BEAT_2_MS = 700    // B → C: dolly into room
export const BEAT_3_MS = 800    // C → D: spring zoom to keyboard
export const BEAT_4_MS = 300    // D hold: breath + yaw float → orbit enable
export const TOTAL_TO_KB_MS = BEAT_1_MS + BEAT_2_MS + BEAT_3_MS + BEAT_4_MS  // 2500ms

export const TOTAL_TO_TESTIMONIAL_MS = 2000  // reverse D → A
