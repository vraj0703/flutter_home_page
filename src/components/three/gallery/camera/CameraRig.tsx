import { useRef, useCallback } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import { useScroll } from '@react-three/drei'
import * as THREE from 'three'
import { LEFT_PROJECTS } from '../../../../config/projects'
import { resetBoot } from '../../KeyboardScene'
import { getAudioEngine } from '../../../../audio'

import {
  setScrollProgress,
  setKbFocused,
  getFocusState, clearFocus,
  isCameraResetRequested, consumeCameraReset,
  isScrollUnlockRequested, consumeScrollUnlock,
  isScrollAnimating, setScrollAnimating,
  isGateReleaseRequested, consumeGateRelease,
} from '../galleryStore'

import {
  WALL_X, BACK_WALL_Z, WALL_LOCK_Z,
  TEST_PAN_END, SPACING, FRAME_Y,
  KB_X, KB_Z,
} from '../dimensions'

import { damp, useFocusDistance } from '../utils'

import {
  _tPos, _tLook, _scratchFwd,
  KB_VIEW_TARGET_Y, KB_VIEW_CAM_DY, KB_VIEW_CAM_DZ,
} from './cameraConstants'

export function CameraRig() {
  const scroll = useScroll()
  const { camera, clock } = useThree()
  const focusDist = useFocusDistance()
  const curPos = useRef(new THREE.Vector3(0, 0.5, 3))
  const curLook = useRef(new THREE.Vector3(0, 0.5, -10))
  const prevOff = useRef(0)
  const kbTriggered = useRef(false)
  const kbFocused = useRef(false)
  // Soft handoff to OrbitControls — replaces the old hard camera.position.set()
  // snap that was killing the elastic spring landing. Once the scripted zoom
  // damps within reach of KB_VIEW_POS, we enter a 300ms "breath" hold during
  // which curPos finishes settling and a tiny yaw float keeps the scene alive.
  // After the hold, kbFocused flips and KeyboardOrbit takes over from a known
  // exact pose — no jerk on first drag, no spring teleport.
  const kbHoldStart = useRef(0)        // performance.now() when hold began (0 = not in hold)
  const kbSettled = useRef(false)      // true once orbit owns the camera
  const KB_HOLD_MS = 300
  // ── Scroll gate at last testimonial card ──
  const gateActive = useRef(true)
  const GATE = 0.86                   // scroll progress where pan ends
  const KB_TARGET = 0.97              // scroll progress for keyboard orbit
  const audioFired = useRef(false)    // tracks boot sweep firing during animation
  const animationEndTime = useRef(0)  // timestamp of last animation end (for debounce)

  /**
   * Animate scroll from current position to target with anticipation + follow-through.
   * Frame-rate independent (uses performance.now() timestamps).
   * Forward: 80ms anticipation → cubic ease body → spring settle
   * Reverse: 80ms recoil hold → power2 pull → soft land
   */
  const animateScrollTo = useCallback((target: number, isReverse = false) => {
    const el = scroll.el
    if (!el || isScrollAnimating()) return
    // drei ScrollControls: scroll.offset = scrollTop / (scrollHeight - clientHeight)
    // NOT scrollTop / scrollHeight. Use the correct scrollable range.
    const range = el.scrollHeight - el.clientHeight
    setScrollAnimating(true)
    audioFired.current = false

    const startTime = performance.now()
    const anticipationMs = 80
    const totalMs = isReverse ? 950 : 1100

    const finish = () => {
      el.scrollTop = range * target
      setScrollAnimating(false)
      animationEndTime.current = performance.now()
    }

    const step = (now: number) => {
      const elapsed = now - startTime
      const current = el.scrollTop / range
      const dist = target - current

      if (!isReverse && !audioFired.current && elapsed >= 80) {
        audioFired.current = true
        getAudioEngine()?.playBootSweep()
      }

      if (elapsed < anticipationMs) {
        const t = elapsed / anticipationMs
        const easeIn = t * t * 0.003
        el.scrollTop += (target - current) * range * easeIn
      } else if (Math.abs(dist) > 0.002) {
        const bodyElapsed = elapsed - anticipationMs
        const bodyT = Math.min(1, bodyElapsed / (totalMs - anticipationMs))
        const shaped = bodyT < 0.5
          ? 4 * bodyT * bodyT * bodyT
          : 1 - Math.pow(-2 * bodyT + 2, 3) / 2
        const lerpFactor = 0.015 + shaped * 0.055
        el.scrollTop += dist * range * lerpFactor
      } else {
        finish()
        return
      }

      if (elapsed > totalMs + 500) {
        finish()
        return
      }

      requestAnimationFrame(step)
    }
    requestAnimationFrame(step)
  }, [scroll])

  useFrame((_, delta) => {
    // Clamp delta to avoid huge jumps on tab switch / cold start
    const dt = Math.min(delta, 0.05)

    // Reset camera state when gallery re-enters
    if (isCameraResetRequested()) {
      consumeCameraReset()
      kbTriggered.current = false
      kbFocused.current = false
      kbHoldStart.current = 0
      kbSettled.current = false
      gateActive.current = true
      setScrollAnimating(false)
      setKbFocused(false)
      curPos.current.set(0, 0.5, 3)
      curLook.current.set(0, 0.5, -10)
      prevOff.current = 0
      audioFired.current = false
      clearFocus()
    }

    let p = scroll.offset
    const rawP = p // raw (unclamped) scroll.offset — used for prevOff tracking
    setScrollProgress(p)

    // Rate-limited state dump removed — was flooding console during orbit
    // and causing main-thread jank that could read as visual flashes.

    // Skip all gate/keyboard logic while animating — let the animation drive scroll
    if (isScrollAnimating()) {
      prevOff.current = p
      // Trigger keyboard boot ONLY if we're moving toward the keyboard
      // (gate released forward animation, not the reverse exit animation)
      if (!gateActive.current && p >= 0.91 && !kbTriggered.current) {
        kbTriggered.current = true
        resetBoot()
      }
      // NOTE: kbFocused is no longer set during animation. The post-damping
      // settle/hold logic in the zoom phase owns the orbit handoff so the
      // spring landing finishes before OrbitControls takes the camera.
      // Fall through to camera position calculations below
    } else {
      // ── Debounce window after animation ends ──
      // drei ScrollControls has damping so scroll.offset lags scrollTop.
      // During the 400ms after an animation ends, we ignore the gate
      // release check to prevent false forward-scroll detection as
      // scroll.offset catches up with the snapped scrollTop.
      const msSinceAnim = performance.now() - animationEndTime.current
      const inDebounce = msSinceAnim < 400

      // Re-engage gate when user scrolls back into pan territory
      if (p < GATE - 0.02) {
        gateActive.current = true
      }

      // Gate release — triggered by wheel handler accumulating forward force
      if (gateActive.current && isGateReleaseRequested() && !inDebounce) {
        consumeGateRelease()
        gateActive.current = false
        animateScrollTo(KB_TARGET)
      } else if (gateActive.current && p >= GATE) {
        // Clamp scroll.offset to GATE while gate is active.
        // The wheel handler itself prevents scrollTop from exceeding gate,
        // but drei's damping may still report p > GATE for a few frames.
        p = GATE
        setScrollProgress(p)
      }

      // Shared KB-exit: reset all orbit state, re-seed curPos/curLook from
      // where orbit left the camera, and animate back to the gate.
      const exitKeyboardOrbit = () => {
        kbTriggered.current = false
        kbFocused.current = false
        kbHoldStart.current = 0
        kbSettled.current = false
        setKbFocused(false)
        gateActive.current = true
        curPos.current.copy(camera.position)
        camera.getWorldDirection(_scratchFwd)
        curLook.current.copy(camera.position).add(_scratchFwd.multiplyScalar(5))
        animateScrollTo(GATE, true)
      }

      // Handle back-scroll from keyboard (via requestScrollUnlock from ReverseScroll)
      if (isScrollUnlockRequested() && kbFocused.current) {
        consumeScrollUnlock()
        exitKeyboardOrbit()
        return
      }

      // Hysteresis: detect back-scroll while KB focused (fallback)
      if (kbFocused.current) {
        if (p < 0.96) {
          exitKeyboardOrbit()
        } else {
          return
        }
      }
    }

    const { active: focusActive } = getFocusState()

    if (p < 0.90) { kbTriggered.current = false }
    if (focusActive && Math.abs(p - prevOff.current) > 0.002) { clearFocus() }
    // Always track raw scroll.offset for prevOff (not the clamped p)
    // This prevents false forward-delta detection after gate clamps to GATE
    prevOff.current = rawP

    // Once orbit fully owns the camera, skip all rig writes.
    if (kbSettled.current) return

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
    } else if (p < 0.86) {
      // Pan right along the back wall (testimonials)
      const t = (p - 0.58) / 0.28
      const panX = t * TEST_PAN_END
      tPos.set(panX, 0.6, WALL_LOCK_Z)
      // Micro-lean: at p=0.84–0.86, glance slightly toward KB room (anticipation)
      let lookX = panX
      let lookZ = BACK_WALL_Z
      if (p >= 0.84) {
        const leanT = (p - 0.84) / 0.02
        const leanEase = leanT * leanT // quadratic ease-in, subtle
        lookX += leanEase * (KB_X - TEST_PAN_END) * 0.12
        lookZ -= leanEase * 0.8 // nudge look point forward (around the corner)
      }
      tLook.set(lookX, 0.6, lookZ)
    } else if (p < 0.91) {
      // Turn + approach: ease-in (hesitate) then ease-out (commit)
      const t = (p - 0.86) / 0.05
      const ease = t < 0.4
        ? Math.pow(t / 0.4, 3) * 0.4                          // ease-in to 0.4
        : 0.4 + (1 - Math.pow(1 - (t - 0.4) / 0.6, 3)) * 0.6  // ease-out remainder
      const cx = TEST_PAN_END
      tPos.set(
        cx,
        0.6 + ease * 0.2,
        WALL_LOCK_Z + ease * (KB_Z - WALL_LOCK_Z),
      )
      tLook.set(
        cx + ease * (KB_X - cx),
        0.6 + ease * 0.2,
        BACK_WALL_Z + ease * (KB_Z - BACK_WALL_Z),
      )
    } else {
      // p >= 0.91 — keyboard zoom phase
      if (!kbTriggered.current) { kbTriggered.current = true; resetBoot() }
      // Zoom into keyboard with spring overshoot (~6% past target, then settle)
      const t = Math.min(1, (p - 0.91) / 0.06)
      const c4 = (2 * Math.PI) / 3
      const ease = t === 0 ? 0 : t >= 1 ? 1
        : Math.pow(2, -8 * t) * Math.sin((t * 10 - 0.75) * c4) + 1
      const cx = TEST_PAN_END
      // Final position aligns exactly with KB_VIEW_POS (the orbit handoff
      // anchor) so the spring lands on the same point OrbitControls starts
      // from — no jerk on first drag.
      const finalX = KB_X
      const finalY = KB_VIEW_TARGET_Y + KB_VIEW_CAM_DY  // ~2.09
      const finalZ = KB_Z + KB_VIEW_CAM_DZ              // ~KB_Z+5.04
      tPos.set(
        cx + ease * (finalX - cx),
        0.8 + ease * (finalY - 0.8),
        WALL_LOCK_Z + ease * (finalZ - WALL_LOCK_Z),
      )
      // tLook now matches the orbit target (was FLOOR_Y → looking 2m below
      // the keyboard, the "looking at floor" handoff bug). KB_VIEW_TARGET_Y
      // sits at the actual cap-surface world Y.
      tLook.set(KB_X, KB_VIEW_TARGET_Y, KB_Z)
    }

    // Continuous damp speed — no step-function at phase boundaries
    const { active: faFinal } = getFocusState()
    let dampSpeed: number
    if (faFinal) {
      dampSpeed = 12
    } else if (p < 0.58) {
      dampSpeed = 6          // walk forward
    } else if (p < 0.83) {
      dampSpeed = 10         // pan through testimonials
    } else if (p < 0.86) {
      // Brake approach: taper 10 → 3 over last 3% of pan (pre-gate deceleration)
      const t = (p - 0.83) / 0.03
      dampSpeed = 10 - t * 7
    } else if (p < 0.91) {
      // Turn phase: smooth 3.5
      dampSpeed = 3.5
    } else {
      // Keyboard zoom: 4 → 5 as we settle (snappier final landing)
      const t = Math.min((p - 0.91) / 0.06, 1)
      dampSpeed = 4 + t * 1
    }

    curPos.current.x = damp(curPos.current.x, tPos.x, dampSpeed, dt)
    curPos.current.y = damp(curPos.current.y, tPos.y, dampSpeed, dt)
    curPos.current.z = damp(curPos.current.z, tPos.z, dampSpeed, dt)
    curLook.current.x = damp(curLook.current.x, tLook.x, dampSpeed, dt)
    curLook.current.y = damp(curLook.current.y, tLook.y, dampSpeed, dt)
    curLook.current.z = damp(curLook.current.z, tLook.z, dampSpeed, dt)

    // ── Soft handoff to OrbitControls (replaces the old hard snap) ──
    // When the scripted zoom has damped within reach of the final view AND
    // the gate has been released, enter a 300ms breath-hold. During the hold
    // we keep damping (curPos finishes the spring) and overlay a tiny yaw
    // float to keep the scene alive. After the hold we snap curPos exactly
    // to the orbit start pose and flip kbFocused — OrbitControls reads from
    // a known exact pose, so the first user drag has zero jerk.
    if (!faFinal && p >= 0.91 && !gateActive.current && !kbFocused.current) {
      const dx = curPos.current.x - tPos.x
      const dy = curPos.current.y - tPos.y
      const dz = curPos.current.z - tPos.z
      const distSq = dx * dx + dy * dy + dz * dz
      if (distSq < 0.04) {  // within 0.2u of final
        if (kbHoldStart.current === 0) {
          kbHoldStart.current = performance.now()
        }
        const heldMs = performance.now() - kbHoldStart.current
        // Idle yaw float during hold — ±0.005 rad on the look target, 4s period.
        const floatPhase = (heldMs / 4000) * Math.PI * 2
        curLook.current.x += Math.sin(floatPhase) * 0.005 * KB_VIEW_CAM_DZ
        if (heldMs >= KB_HOLD_MS) {
          // Snap to exact orbit start pose so OrbitControls inherits a
          // deterministic camera state — eliminates first-drag snap.
          curPos.current.set(KB_X, KB_VIEW_TARGET_Y + KB_VIEW_CAM_DY, KB_Z + KB_VIEW_CAM_DZ)
          curLook.current.set(KB_X, KB_VIEW_TARGET_Y, KB_Z)
          camera.position.copy(curPos.current)
          camera.lookAt(curLook.current)
          kbFocused.current = true
          kbSettled.current = true
          setKbFocused(true)
          return
        }
      } else {
        // Drifted out of hold range (user scrolled back) — reset hold timer.
        kbHoldStart.current = 0
      }
    }

    camera.position.copy(curPos.current)

    // FOV transition: 65 (gallery) → 62 (brake) → 58 (turn) → 50 (keyboard landing)
    // Starts tightening at gate approach (p=0.83) — FOV is part of anticipation
    const perspCam = camera as THREE.PerspectiveCamera
    let targetFov: number
    if (p >= 0.97) {
      targetFov = 50
    } else if (p >= 0.91) {
      // Keyboard zoom: 58 → 50 (final narrowing)
      const t = (p - 0.91) / 0.06
      targetFov = 58 - t * 8
    } else if (p >= 0.86) {
      // Turn phase: 62 → 58
      const t = (p - 0.86) / 0.05
      targetFov = 62 - t * 4
    } else if (p >= 0.83) {
      // Brake approach: 65 → 62 (subtle anticipation)
      const t = (p - 0.83) / 0.03
      targetFov = 65 - t * 3
    } else {
      targetFov = 65
    }
    // Frame-rate independent FOV damp (speed 5 = ~140ms half-life)
    const newFov = damp(perspCam.fov, targetFov, 5, dt)
    if (Math.abs(perspCam.fov - newFov) > 0.01) {
      perspCam.fov = newFov
      perspCam.updateProjectionMatrix()
    }

    camera.lookAt(curLook.current)
    // Subtle organic camera roll while in the corridor — gives the walk a
    // breathing, hand-held feel. Skipped during turn/zoom/orbit so it never
    // fights the scripted look targets or the hold yaw float.
    if (!faFinal && p < 0.86) {
      const t = clock.elapsedTime
      camera.rotation.z += Math.sin(t * 0.5) * 0.002 + Math.sin(t * 0.3) * 0.001
    }
  })
  return null
}
