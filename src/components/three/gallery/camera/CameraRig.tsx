import { useRef, useEffect } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { useScroll } from '@react-three/drei'
import * as THREE from 'three'
import { LEFT_PROJECTS } from '../../../../config/projects'
import { resetBoot } from '../keyboardStore'
import { getAudioEngine } from '../../../../audio'

import {
  setScrollProgress,
  setKbFocused,
  getFocusState, clearFocus,
  isCameraResetRequested, consumeCameraReset,
  isScrollAnimating, setScrollAnimating,
  subscribeSkillsClick,
  subscribeKBBackClick,
  isReducedMotion,
} from '../galleryStore'

import {
  WALL_X, BACK_WALL_Z, WALL_LOCK_Z,
  TEST_PAN_END, SPACING, FRAME_Y,
  KB_X, KB_Z,
} from '../dimensions'

import { damp, useFocusDistance } from '../utils'

import {
  _tPos, _tLook,
  KB_VIEW_TARGET_Y, KB_VIEW_CAM_DY, KB_VIEW_CAM_DZ,
  ANIM_A_POS, ANIM_A_LOOK,
  ANIM_B_POS, ANIM_B_LOOK,
  ANIM_D_POS, ANIM_D_LOOK,
  BEAT_1_MS, BEAT_2_MS, BEAT_3_MS, BEAT_4_MS,
  TOTAL_TO_TESTIMONIAL_MS,
} from './cameraConstants'

/* ── Easing helpers ───────────────────────────────────── */

function easeInOutCubic(t: number): number {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
}

/* ── Scratch vectors for click animation (need two — pos & look same frame) */
const _animPos = new THREE.Vector3()
const _animLook = new THREE.Vector3()

function lerpPos(a: THREE.Vector3, b: THREE.Vector3, t: number): THREE.Vector3 {
  return _animPos.lerpVectors(a, b, t)
}
function lerpLook(a: THREE.Vector3, b: THREE.Vector3, t: number): THREE.Vector3 {
  return _animLook.lerpVectors(a, b, t)
}

/* ── CameraRig ────────────────────────────────────────── */

export function CameraRig() {
  const scroll = useScroll()
  const { camera, clock } = useThree()
  const focusDist = useFocusDistance()
  const curPos = useRef(new THREE.Vector3(0, 0.5, 3))
  const curLook = useRef(new THREE.Vector3(0, 0.5, -10))
  const prevOff = useRef(0)
  const kbFocused = useRef(false)
  const kbSettled = useRef(false)

  // Click-driven animation state
  const animPhase = useRef<'idle' | 'toKB' | 'toTestimonial'>('idle')
  const animStart = useRef(0)

  // ── Subscribe to Skills click → animate to KB ──
  useEffect(() => {
    return subscribeSkillsClick(() => {
      // Reduced motion: skip the 2-second orbit choreography, jump directly
      // to the hero shot. Keyboard boot-up is still reset so the keys still
      // power on; only the camera swing is suppressed.
      if (isReducedMotion()) {
        camera.position.copy(ANIM_D_POS)
        camera.lookAt(ANIM_D_LOOK)
        const perspCam = camera as THREE.PerspectiveCamera
        perspCam.fov = 50
        perspCam.updateProjectionMatrix()
        kbFocused.current = true
        kbSettled.current = true
        setKbFocused(true)
        resetBoot()
        getAudioEngine()?.playBootSweep()
        return
      }

      const now = performance.now()
      animPhase.current = 'toKB'
      animStart.current = now
      // Capture current camera state as animation start
      curPos.current.copy(camera.position)
      camera.getWorldDirection(_tLook)
      curLook.current.copy(camera.position).add(_tLook.multiplyScalar(5))
      setScrollAnimating(true)
      resetBoot()
      getAudioEngine()?.playBootSweep()
    })
  }, [camera])

  // ── Subscribe to KB Back click → animate to testimonial ──
  useEffect(() => {
    return subscribeKBBackClick(() => {
      // Reduced motion: jump back to testimonial view without the reverse orbit.
      if (isReducedMotion()) {
        camera.position.copy(ANIM_A_POS)
        camera.lookAt(ANIM_A_LOOK)
        const perspCam = camera as THREE.PerspectiveCamera
        perspCam.fov = 65
        perspCam.updateProjectionMatrix()
        kbFocused.current = false
        kbSettled.current = false
        setKbFocused(false)
        curPos.current.copy(ANIM_A_POS)
        curLook.current.copy(ANIM_A_LOOK)
        return
      }

      const now = performance.now()
      animPhase.current = 'toTestimonial'
      animStart.current = now
      kbFocused.current = false
      kbSettled.current = false
      setKbFocused(false)
      curPos.current.copy(camera.position)
      camera.getWorldDirection(_tLook)
      curLook.current.copy(camera.position).add(_tLook.multiplyScalar(5))
      setScrollAnimating(true)
    })
  }, [camera])

  useFrame((_, delta) => {
    // Clamp delta to avoid huge jumps on tab switch / cold start
    const dt = Math.min(delta, 0.05)

    // Reset camera state when gallery re-enters
    if (isCameraResetRequested()) {
      consumeCameraReset()
      kbFocused.current = false
      kbSettled.current = false
      setScrollAnimating(false)
      setKbFocused(false)
      curPos.current.set(0, 0.5, 3)
      curLook.current.set(0, 0.5, -10)
      prevOff.current = 0
      animPhase.current = 'idle'
      clearFocus()
    }

    // ── Click-driven camera animation (Skills → KB or KB → testimonial) ──
    if (animPhase.current !== 'idle') {
      const elapsed = performance.now() - animStart.current

      if (animPhase.current === 'toKB') {
        // 3-beat animation:
        //   Beat 1 (turn 90°): A → B, camera looks toward KB entry
        //   Beat 2 (orbit 180° + zoom): B → D, continuous spherical arc around
        //     the keyboard, radius spirals 20 → 5, camera ends on opposite side
        //   Beat 3 (hold): settle at D, yaw float, handoff to OrbitControls
        let pos: THREE.Vector3
        let look: THREE.Vector3
        let fovTarget: number

        const ORBIT_MS = BEAT_2_MS + BEAT_3_MS  // 1500ms continuous arc
        const HOLD_START_MS = BEAT_1_MS + ORBIT_MS

        if (elapsed < BEAT_1_MS) {
          // Beat 1: Turn to face KB entry (unchanged)
          const t = easeInOutCubic(elapsed / BEAT_1_MS)
          pos = lerpPos(ANIM_A_POS, ANIM_B_POS, t)
          look = lerpLook(ANIM_A_LOOK, ANIM_B_LOOK, t)
          fovTarget = 65 - t * 5  // 65 → 60
        } else if (elapsed < HOLD_START_MS) {
          // Beat 2: Parametric 180° orbit around keyboard with spiral-inward
          // zoom. Uses spherical coords (azimuth + radius) for a continuous
          // curved arc, not linear lerps through kink points.
          const raw = (elapsed - BEAT_1_MS) / ORBIT_MS
          const t = easeInOutCubic(raw)

          // Azimuth around keyboard's Y axis: PI (camera at -X of keyboard) →
          // 0 (camera at +X). Going through PI/2 takes the camera through the
          // +Z side (corridor side) — camera arcs OVER the corridor side of
          // the keyboard before descending to the opposite hero position.
          const azimuth = Math.PI - Math.PI * t

          // Radius spirals 20 → 5.04, with a mid-arc inward dip (sin bump)
          // so the camera passes CLOSE to the keyboard at the midpoint,
          // creating a tight dramatic orbit instead of a wide lazy arc.
          const startRad = 20
          const endRad = KB_VIEW_CAM_DZ  // 5.04
          const rad = startRad * (1 - t) + endRad * t - 6 * Math.sin(Math.PI * t)

          // Height rises 0.2 → 1.64 above target Y, with a +1.5u peak at
          // midpoint (camera lifts OVER the keyboard for a soaring feel).
          const startH = ANIM_B_POS.y - KB_VIEW_TARGET_Y  // 0.7 - 0.45 = 0.25
          const endH = KB_VIEW_CAM_DY  // 1.64
          const height = startH * (1 - t) + endH * t + 1.5 * Math.sin(Math.PI * t)

          pos = _animPos.set(
            KB_X + rad * Math.cos(azimuth),
            KB_VIEW_TARGET_Y + height,
            KB_Z + rad * Math.sin(azimuth),
          )
          // Always look at the keyboard center — this is what makes it feel
          // like a true orbit rather than a dolly.
          look = _animLook.set(KB_X, KB_VIEW_TARGET_Y, KB_Z)

          // FOV smoothly narrows 60 → 50 across the entire orbit
          fovTarget = 60 - t * 10
        } else {
          // Beat 3: Hold + settle → enable orbit
          pos = _animPos.copy(ANIM_D_POS)
          look = _animLook.copy(ANIM_D_LOOK)
          fovTarget = 50
          const holdElapsed = elapsed - HOLD_START_MS
          // Tiny yaw float during hold
          look.x += Math.sin(holdElapsed / 4000 * Math.PI * 2) * 0.005 * KB_VIEW_CAM_DZ
          if (holdElapsed >= BEAT_4_MS) {
            kbFocused.current = true
            kbSettled.current = true
            setKbFocused(true)
            setScrollAnimating(false)
            animPhase.current = 'idle'
          }
        }

        camera.position.copy(pos)
        camera.lookAt(look)
        const perspCam = camera as THREE.PerspectiveCamera
        perspCam.fov = damp(perspCam.fov, fovTarget, 5, Math.min(delta, 0.05))
        perspCam.updateProjectionMatrix()
        return
      }

      if (animPhase.current === 'toTestimonial') {
        // Reverse: D → A over TOTAL_TO_TESTIMONIAL_MS with easeInOutCubic
        const t = easeInOutCubic(Math.min(1, elapsed / TOTAL_TO_TESTIMONIAL_MS))
        // Reverse: interpolate D→A
        const pos = lerpPos(ANIM_D_POS, ANIM_A_POS, t)
        const look = lerpLook(ANIM_D_LOOK, ANIM_A_LOOK, t)
        const fovTarget = 50 + t * 15  // 50 → 65

        camera.position.copy(pos)
        camera.lookAt(look)
        const perspCam = camera as THREE.PerspectiveCamera
        perspCam.fov = damp(perspCam.fov, fovTarget, 5, Math.min(delta, 0.05))
        perspCam.updateProjectionMatrix()

        if (elapsed >= TOTAL_TO_TESTIMONIAL_MS) {
          // Re-seed curPos/curLook so scroll-driven camera picks up smoothly
          curPos.current.copy(ANIM_A_POS)
          curLook.current.copy(ANIM_A_LOOK)
          animPhase.current = 'idle'
          setScrollAnimating(false)
        }
        return
      }
    }

    const p = scroll.offset
    setScrollProgress(p)

    // Skip scroll-driven logic while animating
    if (isScrollAnimating()) {
      prevOff.current = p
      return
    }

    // Once orbit fully owns the camera, skip all rig writes.
    if (kbSettled.current) return

    const { active: focusActive } = getFocusState()

    if (focusActive && Math.abs(p - prevOff.current) > 0.002) { clearFocus() }
    prevOff.current = p

    // Use module-scratch vectors — mutated in place each frame, never realloc.
    const tPos = _tPos
    const tLook = _tLook

    // Re-read focus state after potential clearFocus() call
    const { active: fa, index: fpi } = getFocusState()

    if (fa && fpi >= 0) {
      // Focus on a project frame (click-to-zoom)
      const isLeft = fpi < LEFT_PROJECTS.length
      const pi = isLeft ? fpi : fpi - LEFT_PROJECTS.length
      const z = -(pi + 1) * SPACING, lookY = FRAME_Y - 0.3
      if (isLeft) { tPos.set(-WALL_X + focusDist + 0.15, lookY, z); tLook.set(-WALL_X + 0.15, lookY, z) }
      else { tPos.set(WALL_X - focusDist - 0.15, lookY, z); tLook.set(WALL_X - 0.15, lookY, z) }
    } else if (p < 0.58) {
      // Walk forward — ends exactly at WALL_LOCK_Z
      const t = p / 0.58
      const z = 3 - t * (3 - WALL_LOCK_Z)
      tPos.set(0, 0.5, z)
      const wallProximity = Math.max(0, (p - 0.45) / 0.13)
      const lookZ = (z - 10) + (BACK_WALL_Z - (z - 10)) * wallProximity * wallProximity
      tLook.set(0, 0.5, lookZ)
    } else {
      // Pan right along the back wall (testimonials) — full 0.58–1.0 range.
      // Camera looks straight at the back wall throughout — no lean/anticipation.
      // The old micro-lean (p >= 0.96) was anticipation for the scroll-gate's
      // turn phase. Since the transition is now click-driven (Skills button),
      // the lean is redundant and caused the wall to appear tilted at pan end.
      const t = (p - 0.58) / 0.42
      const panX = t * TEST_PAN_END
      tPos.set(panX, 0.6, WALL_LOCK_Z)
      tLook.set(panX, 0.6, BACK_WALL_Z)
    }

    // Continuous damp speed — no step-function at phase boundaries
    const { active: faFinal } = getFocusState()
    let dampSpeed: number
    if (faFinal) {
      dampSpeed = 12
    } else if (p < 0.58) {
      dampSpeed = 6          // walk forward
    } else {
      dampSpeed = 10         // pan through testimonials
    }

    curPos.current.x = damp(curPos.current.x, tPos.x, dampSpeed, dt)
    curPos.current.y = damp(curPos.current.y, tPos.y, dampSpeed, dt)
    curPos.current.z = damp(curPos.current.z, tPos.z, dampSpeed, dt)
    curLook.current.x = damp(curLook.current.x, tLook.x, dampSpeed, dt)
    curLook.current.y = damp(curLook.current.y, tLook.y, dampSpeed, dt)
    curLook.current.z = damp(curLook.current.z, tLook.z, dampSpeed, dt)

    camera.position.copy(curPos.current)

    // FOV transition: 65 throughout gallery walk + pan
    const perspCam = camera as THREE.PerspectiveCamera
    const targetFov = 65
    const newFov = damp(perspCam.fov, targetFov, 5, dt)
    if (Math.abs(perspCam.fov - newFov) > 0.01) {
      perspCam.fov = newFov
      perspCam.updateProjectionMatrix()
    }

    camera.lookAt(curLook.current)
    // Subtle organic camera roll while in the corridor — gives the walk a
    // breathing, hand-held feel. Skipped during orbit so it never
    // fights the scripted look targets, and skipped entirely when the
    // user prefers reduced motion (WCAG 2.1 SC 2.3.3).
    if (!faFinal && p < 0.58 && !isReducedMotion()) {
      const t = clock.elapsedTime
      const roll = Math.sin(t * 0.5) * 0.002 + Math.sin(t * 0.3) * 0.001
      camera.rotateZ(roll)
    }
  })
  return null
}
