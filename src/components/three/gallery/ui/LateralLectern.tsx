/**
 * LateralLectern — wheeled docent's lectern that rolls in front of the
 * active project frame in lateral view, carrying the navigation controls.
 *
 * Replaces the HTML control panel with an in-world equivalent. Matches
 * the gallery's existing UI vocabulary (HDR neon text + modrnt_urban
 * font, like SkillsButton / GraffitiBackButton) — not the brushed-metal
 * "museum placard" direction that failed in RAJ-172.
 *
 * Behavior
 *   • Hidden below floor when no project is focused.
 *   • Rises into place at the active frame's parking spot on focus.
 *   • Damps along the corridor when arrows nav between same-wall frames,
 *     wheels visibly spinning.
 *   • For cross-corridor jumps it slides through the corridor and rotates
 *     to face the new wall — kept simple (single damp, no choreography).
 *   • Sinks back below floor on clearFocus.
 *
 * Interactions
 *   ◀ Prev   |   counter + title   |   ▶ Next
 *      ✕ Gallery               Open ↗
 *   plus window keyboard: Esc / ← → / Enter.
 */

import { useRef, useEffect, useState, useCallback, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { LEFT_PROJECTS, PROJECTS } from '../../../../config/projects'
import { FLOOR_Y, WALL_X, SPACING } from '../dimensions'
import { damp } from '../utils'
import {
  subscribeFocusChange, setClickTarget, clearFocus, fireProjectOpen,
} from '../galleryStore'
import { getAudioEngine } from '../../../../audio'
import { prefersReducedMotion } from '../../../../hooks/useReducedMotion'

const TOTAL = PROJECTS.length

/* ── Geometry constants ─────────────────────────────────────────
   Designed for visibility at lateral-view camera distance (~3.5u
   from camera). Lessons from RAJ-172: at this distance, sub-0.5u
   geometry with sub-0.06 text is unreadable. */
const BASE_W = 0.7
const BASE_D = 0.55
const BASE_H = 0.08
const WHEEL_R = 0.05
const WHEEL_W = 0.04
const STEM_W = 0.07
/** Stem height brings the reading surface to viewer chest level. The
 *  camera in lateral view sits at world y ≈ 0.5; the lectern's floor is
 *  at FLOOR_Y = -1.5, so a stem of 1.3 puts the top at y ≈ 0.0, just
 *  below the camera's gaze for a natural reading angle. */
const STEM_H = 1.3
const TOP_W = 0.85
const TOP_D = 0.6
const TOP_THICK = 0.04
/** Reading angle. Negative because the surface needs to tilt FORWARD —
 *  front edge (toward viewer) drops, back edge raises. The first cut
 *  used the positive sign and rendered an inverted lectern. */
const TOP_TILT = -Math.PI / 9
const TOP_Y = BASE_H + STEM_H

/** How far in front of the wall the lectern parks. */
const PARK_DIST_FROM_WALL = 1.6
/** Y offset added to FLOOR_Y when raised vs hidden. Hidden = -2 (below floor). */
const HIDDEN_Y = -2.4
const RAISED_Y = 0

/* ── Audio gating ──────────────────────────────────────────── */
const ARROW_DEBOUNCE_MS = 120

/** A single wheel — black rubber, no metalness so it renders consistently
 *  without an envMap. Cylinder rotated 90° around Z so its axis is the
 *  lectern's local X (wheels roll along Z, the corridor direction). */
function Wheel({
  position, wheelRef,
}: {
  position: [number, number, number]
  wheelRef: (m: THREE.Mesh | null) => void
}) {
  return (
    <mesh
      ref={wheelRef}
      position={position}
      rotation={[0, 0, Math.PI / 2]}
    >
      <cylinderGeometry args={[WHEEL_R, WHEEL_R, WHEEL_W, 16]} />
      <meshStandardMaterial color="#1A1A1A" roughness={0.6} metalness={0.0} />
    </mesh>
  )
}

export function LateralLectern() {
  const grp = useRef<THREE.Group>(null)
  const w1 = useRef<THREE.Mesh | null>(null)
  const w2 = useRef<THREE.Mesh | null>(null)
  const w3 = useRef<THREE.Mesh | null>(null)
  const w4 = useRef<THREE.Mesh | null>(null)

  const [focus, setFocus] = useState<{ index: number; active: boolean }>(
    { index: -1, active: false },
  )
  const lastArrowAt = useRef(0)

  // Damp targets — driven from focus state.
  const targetX = useRef(0)
  const targetZ = useRef(0)
  const targetRotY = useRef(0)
  const targetY = useRef(HIDDEN_Y)
  const cur = useRef({ x: 0, z: 0, y: HIDDEN_Y, rotY: 0 })
  const lastPos = useRef({ x: 0, z: 0 })

  // Subscribe to focus changes from galleryStore. Update damp targets
  // inside the callback (lint-approved pattern).
  useEffect(() => {
    let initialised = false
    const unsub = subscribeFocusChange((state) => {
      setFocus(state)
      if (state.active && state.index >= 0) {
        const isLeft = state.index < LEFT_PROJECTS.length
        const pi = isLeft ? state.index : state.index - LEFT_PROJECTS.length
        targetZ.current = -(pi + 1) * SPACING
        targetX.current = isLeft
          ? -WALL_X + PARK_DIST_FROM_WALL
          : WALL_X - PARK_DIST_FROM_WALL
        targetRotY.current = isLeft ? -Math.PI / 2 : Math.PI / 2
        targetY.current = RAISED_Y
        // First-time placement: snap to target so we don't roll across the
        // entire corridor on first focus.
        if (!initialised) {
          cur.current.x = targetX.current
          cur.current.z = targetZ.current
          cur.current.rotY = targetRotY.current
          initialised = true
        }
      } else {
        targetY.current = HIDDEN_Y
      }
    })
    return unsub
  }, [])

  useFrame((_, delta) => {
    if (!grp.current) return
    const dt = Math.min(delta, 0.05)
    const reduced = prefersReducedMotion()
    const positionSpeed = reduced ? 30 : 5  // damp speed; "reduced" effectively snaps
    const liftSpeed = reduced ? 30 : 8

    cur.current.x = damp(cur.current.x, targetX.current, positionSpeed, dt)
    cur.current.z = damp(cur.current.z, targetZ.current, positionSpeed, dt)
    cur.current.y = damp(cur.current.y, targetY.current, liftSpeed, dt)
    // Rotation damps too. Take shortest angular path.
    let dRot = targetRotY.current - cur.current.rotY
    if (dRot > Math.PI) dRot -= Math.PI * 2
    if (dRot < -Math.PI) dRot += Math.PI * 2
    cur.current.rotY += dRot * (1 - Math.exp(-positionSpeed * dt))

    grp.current.position.set(cur.current.x, FLOOR_Y + cur.current.y, cur.current.z)
    grp.current.rotation.y = cur.current.rotY

    // Wheel spin from horizontal movement this frame.
    const dx = cur.current.x - lastPos.current.x
    const dz = cur.current.z - lastPos.current.z
    const distance = Math.hypot(dx, dz)
    lastPos.current.x = cur.current.x
    lastPos.current.z = cur.current.z
    if (distance > 0.0001 && !reduced) {
      const spin = -distance / WHEEL_R
      ;[w1, w2, w3, w4].forEach((r) => {
        if (r.current) r.current.rotation.x += spin
      })
    }
  })

  /* ── Click handlers ──────────────────────────────────────── */

  const goPrev = useCallback(() => {
    const now = performance.now()
    if (now - lastArrowAt.current < ARROW_DEBOUNCE_MS) return
    lastArrowAt.current = now
    if (focus.index < 0) return
    const next = (focus.index - 1 + TOTAL) % TOTAL
    if (focus.index === 0 && !prefersReducedMotion()) {
      getAudioEngine()?.playWrapChime()
    }
    setClickTarget(next)
  }, [focus.index])

  const goNext = useCallback(() => {
    const now = performance.now()
    if (now - lastArrowAt.current < ARROW_DEBOUNCE_MS) return
    lastArrowAt.current = now
    if (focus.index < 0) return
    const next = (focus.index + 1) % TOTAL
    if (focus.index === TOTAL - 1 && !prefersReducedMotion()) {
      getAudioEngine()?.playWrapChime()
    }
    setClickTarget(next)
  }, [focus.index])

  const goGallery = useCallback(() => clearFocus(), [])

  const onOpen = useCallback(() => {
    if (focus.index < 0) return
    getAudioEngine()?.playButtonClick()
    fireProjectOpen(PROJECTS[focus.index].id)
  }, [focus.index])

  // Window keyboard map — only active while a project is focused.
  useEffect(() => {
    if (!focus.active) return
    const handler = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement | null
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
      if (e.key === 'Escape') { e.preventDefault(); goGallery() }
      else if (e.key === 'ArrowLeft') { e.preventDefault(); goPrev() }
      else if (e.key === 'ArrowRight') { e.preventDefault(); goNext() }
      else if (e.key === 'Enter') { e.preventDefault(); onOpen() }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [focus.active, goGallery, goPrev, goNext, onOpen])

  /* ── Materials ──────────────────────────────────────────── */

  const woodMat = useMemo(
    () => new THREE.MeshStandardMaterial({
      color: '#5A3A22',          // warm walnut, lighter so the body reads as wood
      roughness: 0.85,
      metalness: 0.0,
    }),
    [],
  )
  const topMat = useMemo(
    () => new THREE.MeshStandardMaterial({
      color: '#3A2410',          // darker top — contrast for the HDR text
      roughness: 0.65,
      metalness: 0.0,
      emissive: '#1A1008',
      emissiveIntensity: 0.4,    // subtle lift so the surface isn't pure black
    }),
    [],
  )
  useEffect(() => () => {
    woodMat.dispose()
    topMat.dispose()
  }, [woodMat, topMat])

  const project = focus.index >= 0 ? PROJECTS[focus.index] : null
  const counterText = project ? `P${focus.index + 1} / ${TOTAL}` : ''
  const titleText = project ? project.title.toUpperCase() : ''

  // Even when hidden, we keep the group rendered so positioning is
  // continuous; visibility is handled by the y-offset (sunk below floor).

  return (
    <group ref={grp}>
      {/* ── Base + wheels ───────────────────────── */}
      <mesh position={[0, BASE_H / 2 + WHEEL_R, 0]} material={woodMat}>
        <boxGeometry args={[BASE_W, BASE_H, BASE_D]} />
      </mesh>
      <Wheel position={[-BASE_W / 2 + 0.03, WHEEL_R, -BASE_D / 2 + 0.03]} wheelRef={(m) => { w1.current = m }} />
      <Wheel position={[ BASE_W / 2 - 0.03, WHEEL_R, -BASE_D / 2 + 0.03]} wheelRef={(m) => { w2.current = m }} />
      <Wheel position={[-BASE_W / 2 + 0.03, WHEEL_R,  BASE_D / 2 - 0.03]} wheelRef={(m) => { w3.current = m }} />
      <Wheel position={[ BASE_W / 2 - 0.03, WHEEL_R,  BASE_D / 2 - 0.03]} wheelRef={(m) => { w4.current = m }} />

      {/* ── Stem ─────────────────────────────────── */}
      <mesh position={[0, BASE_H + WHEEL_R + STEM_H / 2, 0]} material={woodMat}>
        <boxGeometry args={[STEM_W, STEM_H, STEM_W]} />
      </mesh>

      {/* ── Reading top — angled toward viewer ─────
           After group rotation, viewer is in local -Z direction. Tilting
           around X by +TOP_TILT lifts the +Z edge and lowers the -Z edge,
           so the top "bows toward" the viewer. */}
      <group
        position={[0, TOP_Y + WHEEL_R, 0.04]}
        rotation={[TOP_TILT, 0, 0]}
      >
        <mesh material={topMat}>
          <boxGeometry args={[TOP_W, TOP_THICK, TOP_D]} />
        </mesh>

        {/* Text + click planes live just above the top surface (local +Y).
            The whole group is tilted forward, so:
              local +Z = back edge (raised)  → top of camera view
              local -Z = front edge (lowered) → bottom of camera view
            Reading order top→bottom: title → counter → arrows → buttons. */}

        {/* Title — large HDR neon at the BACK (top of view). */}
        <Text
          position={[0, TOP_THICK / 2 + 0.005, 0.18]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.075}
          font="/fonts/modrnt_urban.otf"
          letterSpacing={0.08}
          anchorX="center"
          anchorY="middle"
          maxWidth={TOP_W - 0.1}
        >
          <meshBasicMaterial color={[2.5, 1.8, 0.8]} toneMapped={false} />
          {titleText}
        </Text>

        {/* Counter "P3 / 7" just below title */}
        <Text
          position={[0, TOP_THICK / 2 + 0.005, 0.10]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.045}
          font="/fonts/inconsolata_nerd_mono_regular.ttf"
          letterSpacing={0.06}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[1.6, 1.4, 1.0]} toneMapped={false} />
          {counterText}
        </Text>

        {/* Arrows ◀ ▶ in middle row, flanking the title-counter column */}
        <Text
          position={[-TOP_W / 2 + 0.09, TOP_THICK / 2 + 0.005, 0.0]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.085}
          font={undefined}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[1.5, 1.3, 1.0]} toneMapped={false} />
          {'◀'}
        </Text>
        <Text
          position={[TOP_W / 2 - 0.09, TOP_THICK / 2 + 0.005, 0.0]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.085}
          font={undefined}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[1.5, 1.3, 1.0]} toneMapped={false} />
          {'▶'}
        </Text>

        {/* Action row at the FRONT (bottom of view, closest to viewer's hands) */}
        <Text
          position={[-TOP_W / 2 + 0.16, TOP_THICK / 2 + 0.005, -0.18]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.04}
          font="/fonts/inconsolata_nerd_mono_regular.ttf"
          letterSpacing={0.1}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[1.4, 1.2, 0.9]} toneMapped={false} />
          ✕ GALLERY
        </Text>
        <Text
          position={[TOP_W / 2 - 0.16, TOP_THICK / 2 + 0.005, -0.18]}
          rotation={[-Math.PI / 2, 0, 0]}
          fontSize={0.04}
          font="/fonts/inconsolata_nerd_mono_regular.ttf"
          letterSpacing={0.1}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[2.2, 1.7, 0.7]} toneMapped={false} />
          OPEN →
        </Text>

        {/* ── Click planes — invisible meshes laid flat on the top.
             rotation[-PI/2,0,0] makes a plane parallel to the local XZ
             plane (the surface). Z values match the text rows above. */}
        <mesh
          position={[-TOP_W / 2 + 0.09, TOP_THICK / 2 + 0.001, 0.0]}
          rotation={[-Math.PI / 2, 0, 0]}
          onClick={(e) => { e.stopPropagation(); goPrev() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[0.18, 0.22]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
        <mesh
          position={[TOP_W / 2 - 0.09, TOP_THICK / 2 + 0.001, 0.0]}
          rotation={[-Math.PI / 2, 0, 0]}
          onClick={(e) => { e.stopPropagation(); goNext() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[0.18, 0.22]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
        <mesh
          position={[-TOP_W / 2 + 0.16, TOP_THICK / 2 + 0.001, -0.18]}
          rotation={[-Math.PI / 2, 0, 0]}
          onClick={(e) => { e.stopPropagation(); goGallery() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[0.30, 0.16]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
        <mesh
          position={[TOP_W / 2 - 0.16, TOP_THICK / 2 + 0.001, -0.18]}
          rotation={[-Math.PI / 2, 0, 0]}
          onClick={(e) => { e.stopPropagation(); onOpen() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[0.30, 0.16]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}
