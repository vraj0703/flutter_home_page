import * as THREE from 'three'

// Module-scratch vectors — mutated in CameraRig.useFrame in place to avoid
// per-frame allocations (was causing 240+ Vector3 allocs/sec → GC hitches +
// the tPos-undefined crash class). Never reference these outside useFrame.
export const _tPos = new THREE.Vector3()
export const _tLook = new THREE.Vector3()
export const _scratchFwd = new THREE.Vector3()  // used by KB-exit to seed curLook

// Final keyboard hero-shot view — single source of truth shared by the
// scripted zoom phase, the orbit handoff hold, and KeyboardOrbit's target.
// Polar ≈ 72° from +Y, radius ≈ 5.3 → safely inside [61°, 86°] orbit range.
// Target Y = 0.45 matches the actual keyboard cap-surface world-Y (parent at
// 0.6, scale 0.7, internal group y=-0.3 → ~0.39, +KEY_H/2). FLOOR_Y was
// causing the camera to look 2m below the keyboard during handoff.
export const KB_VIEW_TARGET_Y = 0.45
export const KB_VIEW_CAM_DY = 1.64   // 5.3 * cos(72°)
export const KB_VIEW_CAM_DZ = 5.04   // 5.3 * sin(72°)
