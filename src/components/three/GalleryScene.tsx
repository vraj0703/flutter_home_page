/**
 * GalleryScene.tsx — Unified 3D Gallery (decomposed)
 *
 * Extracted modules:
 *   - ./gallery/galleryStore    — all shared state & event buses
 *   - ./gallery/dimensions      — all scene constants & room geometry
 *   - ./gallery/utils           — damp, tmpVec3, useFrameSize, useFocusDistance
 *   - ./gallery/materials       — useMaterials
 *   - ./gallery/textures        — useProjectTexture
 *   - ../../audio/RadioEngine   — radio playback & state
 *
 * Components defined here:
 *   WallFrame, TestimonialFrame, TubeLight, FrameSpotlight, ThresholdCue,
 *   GraffitiBackButton, WallRadio, LetsConnectFrame, BackWallSpotlight,
 *   TestimonialSpotlight, FloatingKB, CameraRig, GalleryCorridor,
 *   KeyboardOrbit, ReverseScroll, ShaderWarmup, GalleryScene (exported)
 */

import { Suspense, useRef, useMemo, useEffect, useState, useCallback } from 'react'
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { ScrollControls, useScroll, Text, OrbitControls, MeshReflectorMaterial } from '@react-three/drei'
import { EffectComposer, Bloom, ToneMapping } from '@react-three/postprocessing'
import * as THREE from 'three'
import { LEFT_PROJECTS, RIGHT_PROJECTS, type Project } from '../../config/projects'
import { trackProjectClicked } from '../../analytics/posthog'
import { type Testimonial } from '../../config/testimonials'
import { Keyboard as SkillKeyboard, resetBoot, Particles as KBParticles } from '../three/KeyboardScene'
import { getAudioEngine } from '../../audio'

// State & events
import {
  getScrollProgress, setScrollProgress,
  isKbFocused, setKbFocused,
  getFocusState, setClickTarget, clearFocus,
  isCameraResetRequested, consumeCameraReset,
  isScrollUnlockRequested, consumeScrollUnlock,
  setScrollContainer,
  fireCTAClick, fireBackClick, fireConnectClick,
} from './gallery/galleryStore'

// Constants
import {
  CW, CH, FRAME_MAX_H, FRAME_DEPTH, FRAME_BORDER, FRAME_Y, SPACING,
  WALL_X, FLOOR_Y, CEIL_Y,
  CORRIDOR_LEN, BACK_WALL_Z, RIGHT_WALL_LEN,
  TEST_CARDS, ALL_TEST_CARDS, TEST_SPACING, TEST_START_X, TEST_PAN_END,
  KB_ROOM, KB_X, KB_Z, KB_ENTRY_X, KB_END_X,
  WALL_LOCK_Z,
} from './gallery/dimensions'

// Utilities
import { damp, tmpVec3, useFrameSize, useFocusDistance } from './gallery/utils'

// Materials
import { useMaterials } from './gallery/materials'

// Textures
import { useProjectTexture } from './gallery/textures'

// Radio
import {
  toggleRadioMute, setRadioVolume, nextRadioChannel,
  subscribeRadio, getRadioState, _playRadio,
} from '../../audio/RadioEngine'

/* ── Re-exports for backward compatibility ─────────────────── */
export {
  subscribeCTAClick, subscribeBackClick, subscribeConnectClick,
  subscribeKbFocus, requestScrollUnlock, setClickTarget,
} from './gallery/galleryStore'
export { resetGalleryScroll } from './gallery/galleryStore'
export {
  preloadRadio, stopRadio, startRadioOnGalleryEnter,
  toggleRadioMute, setRadioVolume, nextRadioChannel,
  subscribeRadio, getRadioState,
} from '../../audio/RadioEngine'

/* ── WallFrame ───────────────────────────────────────────────── */
function WallFrame({ project, position, side, projectIndex, mats }: {
  project: Project; position: [number, number, number]; side: 'left' | 'right'; projectIndex: number; mats: ReturnType<typeof useMaterials>
}) {
  const tex = useProjectTexture(project)
  const artMat = useMemo(() => new THREE.MeshStandardMaterial({ map: tex, roughness: 0.5, metalness: 0, emissive: '#ffffff', emissiveMap: tex, emissiveIntensity: 0.08 }), [tex])
  const grp = useRef<THREE.Group>(null), hov = useRef(false), pop = useRef(0)
  const glowRef = useRef<THREE.Mesh>(null)
  const entry = useRef({ t: -1, delay: projectIndex * 0.15 })
  const frame = useFrameSize(), rotY = side === 'left' ? Math.PI / 2 : -Math.PI / 2
  const labelY = -(frame.h / 2 + FRAME_BORDER + 0.35), mw = 0.12
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0, transparent: true, opacity: 0,
    roughness: 0.2, metalness: 0.4, side: THREE.BackSide,
  }), [])

  useEffect(() => () => { artMat.dispose(); glowMat.dispose() }, [artMat, glowMat])

  useFrame(({ camera }, delta) => {
    if (!grp.current) return
    const t = hov.current ? 0.08 : 0; pop.current = damp(pop.current, t, 10, delta); grp.current.position.z = pop.current
    // Entry settle — one-shot damped scale pulse when gallery first entered
    if (entry.current.t < 0 && getScrollProgress() > 0.001) entry.current.t = 0
    if (entry.current.t >= 0 && entry.current.t < entry.current.delay + 2) {
      entry.current.t += delta
      const localT = entry.current.t - entry.current.delay
      if (localT > 0 && localT < 2) {
        grp.current.scale.setScalar(1 + Math.sin(localT * 4) * 0.06 * Math.exp(-localT * 2.0))
      } else if (localT >= 2) {
        grp.current.scale.setScalar(1)
      }
    }
    // Proximity glow — subtle emissive border when camera is within 8 units
    if (glowRef.current) {
      grp.current.getWorldPosition(tmpVec3)
      const dist = camera.position.distanceTo(tmpVec3)
      const proximity = Math.max(0, 1 - dist / 8) // 0 at 8+ units, 1 at 0
      const targetGlow = (hov.current ? 0.6 : proximity * 0.25)
      const targetOpacity = (hov.current ? 0.4 : proximity * 0.15)
      glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
      glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
    }
  })
  return (
    <group position={position} rotation={[0, rotY, 0]}>
      <group ref={grp}>
        <mesh onClick={() => { setClickTarget(projectIndex); trackProjectClicked(project.id, project.title); getAudioEngine()?.playShutterClick() }} onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer'; getAudioEngine()?.playHoverPing() }} onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }} material={mats.frameOuter}><boxGeometry args={[frame.w + FRAME_BORDER * 2 + mw * 2, frame.h + FRAME_BORDER * 2 + mw * 2, FRAME_DEPTH]} /></mesh>
        {/* Proximity glow border */}
        <mesh ref={glowRef} material={glowMat}><boxGeometry args={[frame.w + FRAME_BORDER * 2 + mw * 2 + 0.08, frame.h + FRAME_BORDER * 2 + mw * 2 + 0.08, FRAME_DEPTH + 0.04]} /></mesh>
        <mesh position={[0, 0, 0.01]} material={mats.frameInner}><boxGeometry args={[frame.w + mw * 2 + 0.02, frame.h + mw * 2 + 0.02, FRAME_DEPTH - 0.02]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 - 0.01]} material={mats.mat}><planeGeometry args={[frame.w + mw * 2, frame.h + mw * 2]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.001]} material={mats.artBg}><planeGeometry args={[frame.w, frame.h]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.005]} material={artMat}><planeGeometry args={[frame.w, frame.h]} /></mesh>
        <group position={[0, labelY + 0.05, FRAME_DEPTH / 2]}>
          <mesh position={[0, -0.08, 0]}><planeGeometry args={[1.2, 0.35]} /><meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.6} /></mesh>
          <Text position={[0, 0, 0.005]} fontSize={0.1} color="#2A2420" anchorX="center" anchorY="top" letterSpacing={-0.01}>{project.title}</Text>
          <Text position={[0, -0.16, 0.005]} fontSize={0.055} color="#5C4A30" anchorX="center" anchorY="top" letterSpacing={0.04}>{project.description}</Text>
        </group>
      </group>
    </group>
  )
}

/* ── Testimonial frame on back wall ──────────────────────────── */
function TestimonialFrame({ testimonial, position, mats }: {
  testimonial: Testimonial; position: [number, number, number]; mats: ReturnType<typeof useMaterials>
}) {
  const frame = useFrameSize()
  const fw = Math.min(frame.w, 3.2), fh = Math.min(frame.h, 2.8)
  const mw = 0.10
  const isCTA = !!testimonial.isCTA

  return (
    <group position={position}>
      <mesh material={mats.frameOuter}>
        <boxGeometry args={[fw + FRAME_BORDER * 2 + mw * 2, fh + FRAME_BORDER * 2 + mw * 2, FRAME_DEPTH]} />
      </mesh>
      <mesh position={[0, 0, 0.01]} material={mats.frameInner}>
        <boxGeometry args={[fw + mw * 2 + 0.02, fh + mw * 2 + 0.02, FRAME_DEPTH - 0.02]} />
      </mesh>
      <mesh position={[0, 0, FRAME_DEPTH / 2 - 0.01]} material={mats.mat}>
        <planeGeometry args={[fw + mw * 2, fh + mw * 2]} />
      </mesh>
      <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.001]}>
        <planeGeometry args={[fw, fh]} />
        <meshStandardMaterial color={isCTA ? '#2A2420' : '#F5F0E8'} emissive={isCTA ? '#2A2420' : '#F5F0E8'} emissiveIntensity={0.05} roughness={0.9} />
      </mesh>

      {isCTA ? (
        /* ── CTA card: "Recommend Vishal" ── */
        <group>
          <Text position={[0, 0.5, FRAME_DEPTH / 2 + 0.005]} fontSize={0.18} color="#C8A45C" anchorX="center" anchorY="middle" font="/fonts/modrnt_urban.otf">
            Recommend Vishal
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.085} color="#A09880" anchorX="center" anchorY="middle" maxWidth={fw - 0.6} lineHeight={1.6}>
            Share your experience working together
          </Text>
          <mesh position={[0, -0.4, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.4, 0.003]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -0.7, FRAME_DEPTH / 2 + 0.005]} fontSize={0.07} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.12} font="/fonts/inconsolata_nerd_mono_regular.ttf">
            CLICK TO WRITE
          </Text>
          {/* Invisible click target */}
          <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.01]} onClick={() => fireCTAClick()}>
            <planeGeometry args={[fw, fh]} />
            <meshBasicMaterial transparent opacity={0} />
          </mesh>
        </group>
      ) : (
        /* ── Regular testimonial card ── */
        <group>
          <Text position={[-fw / 2 + 0.2, fh / 2 - 0.25, FRAME_DEPTH / 2 + 0.005]} fontSize={0.4} color="#C8A45C" anchorX="left" anchorY="top" font="/fonts/poseidon.otf">
            "
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" maxWidth={fw - 0.5} lineHeight={1.7}>
            {testimonial.text}
          </Text>
          <mesh position={[0, -fh / 2 + 0.7, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.5, 0.004]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -fh / 2 + 0.48, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" font="/fonts/modrnt_urban.otf">
            {testimonial.name}
          </Text>
          <Text position={[0, -fh / 2 + 0.28, FRAME_DEPTH / 2 + 0.005]} fontSize={0.055} color="#9A8A6E" anchorX="center" anchorY="middle" letterSpacing={0.08} font="/fonts/inconsolata_nerd_mono_regular.ttf">
            {testimonial.role} · {testimonial.company}
          </Text>
        </group>
      )}

      <group position={[0, -(fh / 2 + FRAME_BORDER + 0.25), FRAME_DEPTH / 2]}>
        <mesh position={[0, -0.05, 0]}>
          <planeGeometry args={[1.0, 0.25]} />
          <meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.6} />
        </mesh>
        <Text position={[0, 0, 0.005]} fontSize={0.06} color="#2A2420" anchorX="center" anchorY="middle" letterSpacing={0.1} font="/fonts/inconsolata_nerd_mono_regular.ttf">
          {isCTA ? 'RECOMMEND' : 'TESTIMONIAL'}
        </Text>
      </group>
    </group>
  )
}

/* ── Tube light — glowing cylinder mounted above each frame ── */
function TubeLight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
  const fy = FRAME_Y + FRAME_MAX_H / 2 + FRAME_BORDER + 0.3
  const tubeLen = 1.8
  const tubeR = 0.025
  const o = side === 'left' ? 1 : -1
  return (
    <group position={[position[0], fy, position[2]]}>
      {/* Mounting bracket */}
      <mesh position={[0, 0.04, 0]}>
        <boxGeometry args={[0.03, 0.02, tubeLen * 0.6]} />
        <meshStandardMaterial color="#888" roughness={0.4} metalness={0.6} />
      </mesh>
      {/* Glowing tube — emissive only, no spotlight */}
      <mesh position={[o * 0.08, 0, 0]} rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[tubeR, tubeR, tubeLen, 12]} />
        <meshStandardMaterial color="#FFF5E6" emissive="#FFE0B0" emissiveIntensity={3.0} roughness={0.2} metalness={0} />
      </mesh>
    </group>
  )
}

/* ── Frame spotlight — warm focused light on each project frame ── */
function FrameSpotlight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
  const lightRef = useRef<THREE.SpotLight>(null)
  const targetX = side === 'left' ? position[0] + 0.5 : position[0] - 0.5
  // Static target — set once, not per frame
  useEffect(() => {
    if (lightRef.current) {
      lightRef.current.target.position.set(position[0], position[1], position[2])
      lightRef.current.target.updateMatrixWorld()
    }
  })
  return (
    <spotLight
      ref={lightRef}
      position={[targetX, position[1] + 2.5, position[2]]}
      angle={0.45}
      penumbra={0.8}
      intensity={1.2}
      color="#FFE0B0"
      distance={6}
      decay={2}
    />
  )
}

/* ── Threshold Cue — neon stair-lines receding into corridor ──────────
 *
 * 6 neon lines on the floor like a runway/staircase leading into the gallery.
 * Each line progressively narrower, dimmer, and more spaced — forced perspective.
 * Staggered pulse wave travels INTO the corridor (directional invitation).
 * Neon HDR glow via meshBasicMaterial + toneMapped=false + Bloom post-process.
 * "SCROLL" text after the first line.
 *
 * Idle escalation: after 4s no scroll, pulse speed increases
 * First-scroll reward: brief scale-up before graceful fade
 * Fade window: scrollProgress 0.03–0.12 (power curve)
 */

// Stair line config: lines widen as they recede → inverted triangle pointing INTO corridor
const STAIR_LINES = [
  { z: 0,     w: 0.2, h: 0.005, brightness: 1.0  },
  { z: -1.3,  w: 0.6, h: 0.006, brightness: 0.75 },
  { z: -2.3,  w: 1.2, h: 0.007, brightness: 0.55 },
  { z: -3.1,  w: 1.8, h: 0.008, brightness: 0.38 },
  { z: -3.7,  w: 2.6, h: 0.010, brightness: 0.24 },
  { z: -4.2,  w: 3.6, h: 0.012, brightness: 0.14 },
]

// Neon gold HDR color — values > 1.0 make Bloom glow (like the radio/back button)
const NEON_GOLD: [number, number, number] = [2.5, 1.8, 0.6]

function ThresholdCue() {
  const grp = useRef<THREE.Group>(null)
  const opacity = useRef(1)
  const firstScrollRef = useRef(false)
  const lineRefs = useRef<(THREE.Mesh | null)[]>([])

  useFrame(({ clock }, delta) => {
    if (!grp.current) return
    const t = clock.elapsedTime
    const p = getScrollProgress()

    // ── Idle escalation: after 4s no scroll, amplitude + speed grow ──
    const idleTime = p < 0.01 ? Math.max(0, t - 4.0) : 0
    const idleScale = 1 + Math.min(idleTime * 0.08, 0.6) // caps at 1.6x amplitude
    const idleSpeed = 1 + Math.min(idleTime * 0.06, 0.5)  // caps at 1.5x pulse speed

    // ── Beckon motion: asymmetric Z-bounce on the whole group ──
    // Fast lunge forward (0.3 of cycle), slow float back (0.7)
    const raw = Math.sin(t * 1.8)
    const skewed = raw > 0
      ? Math.pow(raw, 0.6)    // compress peak — arrives fast, lingers
      : -Math.pow(-raw, 1.4)  // deepen return — slow departure
    const beckonZ = skewed * 0.22 * idleScale
    grp.current.position.z = -3 + beckonZ

    // Subtle Y hover — lifts slightly on forward stroke
    const liftPhase = Math.sin(t * 1.8 + 0.3)
    grp.current.position.y = FLOOR_Y + 0.03 + Math.max(0, liftPhase) * 0.015 * idleScale

    // ── Emissive breathing: asymmetric (dwell bright, snap dark) ──
    // This modulates ALL lines globally on top of the per-line pulse wave
    const breathRaw = Math.sin(t * 2.1) // ~3s period
    const breathSkew = breathRaw > 0
      ? Math.pow(breathRaw, 0.5)  // lingers near bright
      : breathRaw                  // snaps through dark
    const breathMul = 0.6 + breathSkew * 0.4 // range: 0.6–1.0 multiplier

    // ── Staggered neon pulse wave — travels INTO the corridor ──
    for (let i = 0; i < STAIR_LINES.length; i++) {
      const mesh = lineRefs.current[i]
      if (!mesh) continue
      const mat = mesh.material as THREE.MeshBasicMaterial

      // Per-line phase offset: pulse propagates forward (0.35s stagger)
      const phase = t * 2.2 * idleSpeed - i * 0.35
      const pulse = Math.pow(Math.max(0, Math.sin(phase)), 2.0)

      // Combine: base brightness × pulse × global breath × idle
      const base = STAIR_LINES[i].brightness
      const glow = base * (0.4 + pulse * 0.6) * breathMul * idleScale

      mat.color.setRGB(
        NEON_GOLD[0] * glow,
        NEON_GOLD[1] * glow,
        NEON_GOLD[2] * glow,
      )
      mat.opacity = opacity.current * base
    }

    // ── Fade choreography ──
    // First-scroll reward: brief 15% scale-up on first movement
    if (!firstScrollRef.current && p > 0.005) firstScrollRef.current = true
    const justStarted = firstScrollRef.current && p < 0.02
    const targetScale = justStarted ? 1.15 : 1.0
    const s = grp.current.scale.x
    grp.current.scale.setScalar(s + (targetScale - s) * (1 - Math.exp(-6 * delta)))

    // Extended fade: scrollProgress 0.03–0.12, power curve (unhurried)
    const fadeTarget = p < 0.03 ? 1
      : p < 0.12 ? 1 - Math.pow((p - 0.03) / 0.09, 1.6)
      : 0
    opacity.current = damp(opacity.current, fadeTarget, 5, delta)
    grp.current.visible = opacity.current > 0.01
  })

  return (
    <group ref={grp} position={[0, FLOOR_Y + 0.03, -3]} rotation={[-Math.PI / 2, 0, 0]}>
      {/* Neon stair lines — receding into corridor like a runway */}
      {STAIR_LINES.map((line, i) => (
        <mesh
          key={i}
          ref={el => { lineRefs.current[i] = el }}
          position={[0, line.z, 0]}
        >
          <planeGeometry args={[line.w, line.h]} />
          <meshBasicMaterial
            color={NEON_GOLD}
            transparent
            opacity={line.brightness}
            toneMapped={false}
          />
        </mesh>
      ))}

      {/* "SCROLL" neon text — after the first line, on the floor */}
      <Text
        position={[0, -0.6, 0]}
        fontSize={0.14}
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.35}
        font="/fonts/inconsolata_nerd_mono_regular.ttf"
      >
        <meshBasicMaterial color={NEON_GOLD} toneMapped={false} transparent opacity={0.8} />
        SCROLL
      </Text>
    </group>
  )
}

/* ── Graffiti back button — spray-painted on left wall before frame 1 ── */
function GraffitiBackButton() {
  const grp = useRef<THREE.Group>(null)
  const hov = useRef(false)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#FFFFFF', emissive: '#FFFFFF', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useEffect(() => () => { glowMat.dispose() }, [glowMat])

  useFrame(({ camera }, delta) => {
    if (!grp.current || !glowRef.current) return
    grp.current.getWorldPosition(tmpVec3)
    const dist = camera.position.distanceTo(tmpVec3)
    const proximity = Math.max(0, 1 - dist / 6)
    const targetGlow = hov.current ? 0.8 : proximity * 0.2
    const targetOpacity = hov.current ? 0.15 : proximity * 0.06
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
  })

  return (
    <group position={[-WALL_X + 0.1, FRAME_Y, -1]} rotation={[0, Math.PI / 2, 0]}>
      <group ref={grp}>
        {/* Hover glow backdrop */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[1.6, 1.0]} />
        </mesh>

        {/* Paint drip / splatter background — rough rectangle */}
        <mesh position={[0, 0, 0.005]}>
          <planeGeometry args={[1.4, 0.75]} />
          <meshBasicMaterial transparent opacity={0} />
        </mesh>

        {/* Arrow ← */}
        <Text
          position={[-0.42, 0.02, 0.01]}
          fontSize={0.28}
          anchorX="center"
          anchorY="middle"
          letterSpacing={0}
          font={undefined}
        >
          <meshBasicMaterial color={[1.5, 1.3, 1.0]} toneMapped={false} />
          ←
        </Text>

        <Text
          position={[0.12, 0.02, 0.01]}
          fontSize={0.22}
          anchorX="center"
          anchorY="middle"
          letterSpacing={0.15}
          font="/flutter/assets/fonts/modrnt_urban.otf"
        >
          <meshBasicMaterial color={[2.5, 1.8, 0.8]} toneMapped={false} />
          BACK
        </Text>

        {/* Underline drip */}
        <mesh position={[0, -0.22, 0.008]}>
          <planeGeometry args={[1.1, 0.02]} />
          <meshStandardMaterial color="#E8E0D0" transparent opacity={0.4} roughness={1} metalness={0} />
        </mesh>

        {/* Invisible click plane */}
        <mesh
          position={[0, 0, 0.02]}
          onClick={() => { fireBackClick(); getAudioEngine()?.playButtonClick() }}
          onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[1.6, 1.0]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}

/* ── Wall Radio — streaming radio player on right wall ── */
function WallRadio() {
  const grp = useRef<THREE.Group>(null)
  const hov = useRef(false)
  const knobRef = useRef<THREE.Group>(null)
  const [, forceUpdate] = useState(0)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useEffect(() => {
    const listener = () => forceUpdate(n => n + 1)
    return subscribeRadio(listener)
  }, [])

  // M key to mute
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'm' || e.key === 'M') toggleRadioMute() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  // Animate volume knob rotation
  useFrame(({ camera }, delta) => {
    if (!grp.current || !glowRef.current) return
    // Proximity glow
    grp.current.getWorldPosition(tmpVec3)
    const dist = camera.position.distanceTo(tmpVec3)
    const proximity = Math.max(0, 1 - dist / 6)
    const targetGlow = hov.current ? 0.7 : proximity * 0.2
    const targetOpacity = hov.current ? 0.12 : proximity * 0.05
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
    // Knob rotation: 0 vol = -135°, 1 vol = +135°
    if (knobRef.current) {
      const { volume } = getRadioState()
      const targetAngle = (-135 + volume * 270) * Math.PI / 180
      knobRef.current.rotation.z = damp(knobRef.current.rotation.z, targetAngle, 15, delta)
    }
  })

  // Cycle volume: 0 → 0.25 → 0.5 → 0.75 → 1.0 → 0 (mute)
  const handleVolumeCycle = useCallback(() => {
    const { volume: _radioVolume, playing: _radioPlaying } = getRadioState()
    const steps = [0, 0.25, 0.5, 0.75, 1.0]
    const current = steps.findIndex(s => Math.abs(s - _radioVolume) < 0.05)
    const next = (current + 1) % steps.length
    setRadioVolume(steps[next])
    // Auto-start if off and volume > 0
    if (!_radioPlaying && steps[next] > 0) _playRadio()
    getAudioEngine()?.playButtonClick()
  }, [])

  const handleMuteToggle = useCallback(() => {
    const { playing: _radioPlaying } = getRadioState()
    if (!_radioPlaying) {
      _playRadio()
    } else {
      toggleRadioMute()
    }
    getAudioEngine()?.playButtonClick()
  }, [])

  const handleNext = useCallback(() => {
    nextRadioChannel()
    getAudioEngine()?.playButtonClick()
  }, [])

  const { playing: _radioPlaying, muted: _radioMuted, loading: _radioLoading, channel: channelName, volume: _radioVolume } = getRadioState()
  const statusText = _radioLoading ? 'TUNING...' : _radioPlaying ? (_radioMuted ? 'MUTED' : 'ON AIR') : 'OFF'

  // Neon float multipliers for HDR glowing
  const neonCyan: [number, number, number] = [0.2, 2.0, 2.5]
  const neonPink: [number, number, number] = [2.8, 0.4, 1.5]
  const neonYellow: [number, number, number] = [2.5, 2.0, 0.4]
  const neonRed: [number, number, number] = [2.5, 0.5, 0.5]
  const neonGreen: [number, number, number] = [0.4, 2.5, 0.6]
  const disabled: [number, number, number] = [0.8, 0.8, 0.8]

  const statusColor = _radioLoading ? neonYellow : _radioPlaying ? (_radioMuted ? neonRed : neonGreen) : disabled

  return (
    <group position={[WALL_X - 0.1, FRAME_Y, -1]} rotation={[0, -Math.PI / 2, 0]}>
      <group ref={grp}>
        {/* Hover backdrop (invisible until hovered heavily) */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[2.0, 1.4]} />
        </mesh>

        {/* Radio Hitbox - invisible background */}
        <mesh position={[0, 0, 0.005]}>
          <planeGeometry args={[1.8, 1.2]} />
          <meshBasicMaterial transparent opacity={0} />
        </mesh>

        {/* ── Title: Graffiti Display ── */}
        <Text position={[0, 0.25, 0.01]} fontSize={0.22} anchorX="center" anchorY="middle" letterSpacing={0.06} font="/flutter/assets/fonts/modrnt_urban.otf">
          <meshBasicMaterial color={neonCyan} toneMapped={false} />
          {channelName}
        </Text>

        {/* ── Subtitle: Status ── */}
        <Text position={[0, 0.05, 0.01]} fontSize={0.07} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/inconsolata_nerd_mono_regular.ttf">
          <meshBasicMaterial color={statusColor} toneMapped={false} />
          {`[ ${statusText} ]`}
        </Text>

        {/* ── Controls Row (Pure Stencil Text) ── */}

        {/* VOL Cycle Button */}
        <group position={[-0.4, -0.3, 0.01]}
          onClick={handleVolumeCycle}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={neonYellow} toneMapped={false} />
            VOL+
          </Text>
          <mesh><planeGeometry args={[0.4, 0.2]} /><meshBasicMaterial transparent opacity={0} /></mesh>
        </group>

        {/* Mute/Play Button */}
        <group position={[0, -0.3, 0.01]}
          onClick={handleMuteToggle}
          onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={_radioPlaying ? (_radioMuted ? disabled : neonCyan) : neonPink} toneMapped={false} />
            {_radioPlaying ? (_radioMuted ? 'UNMUTE' : 'MUTE') : 'PLAY'}
          </Text>
          <mesh><planeGeometry args={[0.4, 0.2]} /><meshBasicMaterial transparent opacity={0} /></mesh>
        </group>

        {/* Next Button */}
        <group position={[0.4, -0.3, 0.01]}
          onClick={handleNext}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={neonPink} toneMapped={false} />
            NEXT
          </Text>
          <mesh><planeGeometry args={[0.4, 0.2]} /><meshBasicMaterial transparent opacity={0} /></mesh>
        </group>

        {/* Graffiti Underline */}
        <mesh position={[0, -0.5, 0.01]}>
          <planeGeometry args={[1.2, 0.005]} />
          <meshBasicMaterial color={neonCyan} transparent opacity={0.6} toneMapped={false} />
        </mesh>
      </group>
    </group>
  )
}

/* ── Let's Connect — framed CTA on keyboard room right wall ── */
function LetsConnectFrame() {
  const hov = useRef(false)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useEffect(() => () => { glowMat.dispose() }, [glowMat])

  useFrame(({ camera }, delta) => {
    if (!glowRef.current) return
    glowRef.current.getWorldPosition(tmpVec3)
    const dist = camera.position.distanceTo(tmpVec3)
    const proximity = Math.max(0, 1 - dist / 12)
    const targetGlow = hov.current ? 0.8 : proximity * 0.3
    const targetOpacity = hov.current ? 0.2 : proximity * 0.08
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
  })

  return (
    <group position={[KB_ENTRY_X + 0.1, 1.5, (BACK_WALL_Z + KB_Z - KB_ROOM / 2) / 2]} rotation={[0, Math.PI / 2, 0]}>
      {/* Glow backdrop */}
      <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.02]}>
        <planeGeometry args={[3.5, 2.0]} />
      </mesh>

      {/* Frame outer */}
      <mesh position={[0, 0, 0.005]}>
        <planeGeometry args={[3.2, 1.6]} />
        <meshStandardMaterial color="#1E1C18" roughness={0.6} metalness={0.2} transparent opacity={0.6} />
      </mesh>

      {/* Frame border */}
      <mesh position={[0, 0, 0.003]}>
        <planeGeometry args={[3.4, 1.8]} />
        <meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.5} transparent opacity={0.15} />
      </mesh>

      {/* Main text */}
      <Text
        position={[0, 0.15, 0.01]}
        fontSize={0.35}
        color="#C8A45C"
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.08}
        fontWeight={700}
      >
        Let's Connect
      </Text>

      {/* Subtitle */}
      <Text
        position={[0, -0.25, 0.01]}
        fontSize={0.1}
        color="#8A7A62"
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.12}
      >
        CLICK TO REACH OUT
      </Text>

      {/* Accent line */}
      <mesh position={[0, -0.08, 0.008]}>
        <planeGeometry args={[1.8, 0.008]} />
        <meshStandardMaterial color="#C8A45C" transparent opacity={0.5} />
      </mesh>

      {/* Click plane */}
      <mesh
        position={[0, 0, 0.02]}
        onClick={() => { fireConnectClick(); getAudioEngine()?.playButtonClick() }}
        onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
        onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
      >
        <planeGeometry args={[3.2, 1.6]} />
        <meshStandardMaterial transparent opacity={0} />
      </mesh>
    </group>
  )
}

/* ── Back wall spotlight — warm overhead aimed at back wall center ── */
function BackWallSpotlight() {
  const ref = useRef<THREE.SpotLight>(null)
  // Static target — set once
  useEffect(() => {
    if (ref.current) { ref.current.target.position.set(0, 1, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[0, CEIL_Y - 0.3, BACK_WALL_Z + 3]} angle={0.6} penumbra={0.9} intensity={2.5} color="#FFD9A0" distance={10} decay={1.5} />
}

/* ── Testimonial spotlight — individual warm light per frame ── */
function TestimonialSpotlight({ x }: { x: number }) {
  const ref = useRef<THREE.SpotLight>(null)
  // Static target — set once
  useEffect(() => {
    if (ref.current) { ref.current.target.position.set(x, FRAME_Y, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[x, CEIL_Y - 0.5, BACK_WALL_Z + 2.5]} angle={0.4} penumbra={0.8} intensity={1.0} color="#FFE0B0" distance={6} decay={2} />
}

/* ── Floating keyboard — gentle rotation + bob ───────────── */
function FloatingKB({ position }: { position: [number, number, number] }) {
  const outerRef = useRef<THREE.Group>(null)
  // 3-phase lifecycle:
  // - unmounted (scroll < 5%): nothing in scene graph
  // - preloading (5-93%): mounted 500 units below, compiling shaders across frames
  // - visible (>93%): camera turn is complete, teleport to real position
  const [phase, setPhase] = useState<'unmounted' | 'preloading' | 'visible'>('preloading')

  useFrame(({ clock }, delta) => {
    const p = getScrollProgress()
    if (phase === 'unmounted' && p > 0.05) setPhase('preloading')
    if (phase === 'preloading' && p > 0.93) setPhase('visible')
    if (phase === 'visible' && p < 0.05) setPhase('preloading')

    if (!outerRef.current) return
    if (p < 0.97) {
      const baseRot = clock.elapsedTime * 0.1
      outerRef.current.rotation.y = Math.PI + baseRot % (Math.PI * 2)
      outerRef.current.position.y = position[1] + Math.sin(clock.elapsedTime * 0.4) * 0.08
    } else {
      let diff = Math.PI - outerRef.current.rotation.y
      while (diff < -Math.PI) diff += Math.PI * 2
      while (diff > Math.PI) diff -= Math.PI * 2
      outerRef.current.rotation.y += diff * (1 - Math.exp(-3 * delta))
      outerRef.current.position.y = damp(outerRef.current.position.y, position[1], 3, delta)
    }
  })

  if (phase === 'unmounted') return null

  return (
    <group
      ref={outerRef}
      // During preload: hide 500 units below the scene — out of camera frustum
      // but still in the scene graph so Three.js compiles geometries/shaders
      position={phase === 'preloading' ? [position[0], -500, position[2]] : position}
    >
      <group rotation={[0, -Math.PI / 2, 0]} scale={0.7}>
        <SkillKeyboard />
      </group>
    </group>
  )
}

/* ══════════════════════════════════════════════════════════
   CAMERA RIG — walk forward, lock on wall, pan right, keyboard orbit
   ══════════════════════════════════════════════════════════ */
function CameraRig() {
  const scroll = useScroll()
  const { camera, clock } = useThree()
  const focusDist = useFocusDistance()
  const curPos = useRef(new THREE.Vector3(0, 0.5, 3))
  const curLook = useRef(new THREE.Vector3(0, 0.5, -10))
  const prevOff = useRef(0)
  const kbTriggered = useRef(false)
  const kbFocused = useRef(false)

  useFrame(() => {
    // Reset camera state when gallery re-enters
    if (isCameraResetRequested()) {
      consumeCameraReset()
      kbTriggered.current = false
      kbFocused.current = false
      setKbFocused(false)
      curPos.current.set(0, 0.5, 3)
      curLook.current.set(0, 0.5, -10)
      prevOff.current = 0
      clearFocus()
    }

    const p = scroll.offset
    setScrollProgress(p)

    // Handle scroll unlock request (back scroll from keyboard)
    if (isScrollUnlockRequested() && kbFocused.current) {
      consumeScrollUnlock()
      kbTriggered.current = false
      kbFocused.current = false
      setKbFocused(false)
      const el = scroll.el
      if (el) {
        // Snap directly — no smooth scroll which fights drei's tracking
        el.scrollTop = el.scrollHeight * 0.85
      }
      return
    }

    // Hysteresis: once KB focused, detect back-scroll to exit
    if (kbFocused.current) {
      if (p < 0.96) {
        // User scrolled back — exit keyboard
        kbTriggered.current = false
        kbFocused.current = false
        setKbFocused(false)
        const el = scroll.el
        if (el) {
          // Snap to turn phase — no smooth scroll
          el.scrollTop = el.scrollHeight * 0.87
        }
      } else {
        setScrollProgress(Math.max(p, 0.97))
        return
      }
    }

    const { active: focusActive } = getFocusState()

    if (p < 0.92) { kbTriggered.current = false }
    if (focusActive && Math.abs(p - prevOff.current) > 0.002) { clearFocus() }
    prevOff.current = p

    let tPos: THREE.Vector3, tLook: THREE.Vector3

    // Re-read focus state after potential clearFocus() call
    const { active: fa, index: fpi } = getFocusState()

    if (fa && fpi >= 0) {
      // Focus on a project frame (click-to-zoom)
      const isLeft = fpi < LEFT_PROJECTS.length
      const pi = isLeft ? fpi : fpi - LEFT_PROJECTS.length
      const z = -(pi + 1) * SPACING, lookY = FRAME_Y - 0.3
      if (isLeft) { tPos = new THREE.Vector3(-WALL_X + focusDist + 0.15, lookY, z); tLook = new THREE.Vector3(-WALL_X + 0.15, lookY, z) }
      else { tPos = new THREE.Vector3(WALL_X - focusDist - 0.15, lookY, z); tLook = new THREE.Vector3(WALL_X - 0.15, lookY, z) }
    } else if (p < 0.58) {
      // Walk forward — ends exactly at WALL_LOCK_Z
      const t = p / 0.58
      const z = 3 - t * (3 - WALL_LOCK_Z)
      tPos = new THREE.Vector3(0, 0.5, z)
      const wallProximity = Math.max(0, (p - 0.45) / 0.13)
      const lookZ = (z - 10) + (BACK_WALL_Z - (z - 10)) * wallProximity * wallProximity
      tLook = new THREE.Vector3(0, 0.5, lookZ)
    } else if (p < 0.88) {
      // Pan right along the back wall
      const t = (p - 0.58) / 0.30
      const panX = t * TEST_PAN_END
      tPos = new THREE.Vector3(panX, 0.6, WALL_LOCK_Z)
      tLook = new THREE.Vector3(panX, 0.6, BACK_WALL_Z)
    } else if (p < 0.93) {
      // Turn right — look down the corridor at the keyboard
      const cx = TEST_PAN_END
      tPos = new THREE.Vector3(cx, 0.8, KB_Z)
      tLook = new THREE.Vector3(KB_X, 0.8, KB_Z)
    } else if (p < 0.97 || !kbTriggered.current) {
      // Zoom in — stay below ceiling, camera max y = 2.5
      // Also enters here if p >= 0.97 but kbTriggered is false (fast scroll skip)
      // This prevents teleporting to orbit before the zoom phase completes
      if (!kbTriggered.current) { kbTriggered.current = true; resetBoot(); getAudioEngine()?.playBootSweep() }
      const t = Math.min(1, (p - 0.93) / 0.04)
      const ease = Math.sin(t * Math.PI / 2)
      const cx = TEST_PAN_END
      tPos = new THREE.Vector3(
        cx + ease * (KB_X - cx),
        0.8 + ease * 1.7,
        KB_Z + ease * 5
      )
      tLook = new THREE.Vector3(KB_X, FLOOR_Y, KB_Z)
      // Only allow orbit focus once the camera has actually arrived (lerped close enough)
      if (p >= 0.97 && curPos.current.distanceTo(tPos) < 1.0) {
        kbFocused.current = true
        setKbFocused(true)
        camera.position.set(KB_X, 2.5, KB_Z + 5)
        camera.lookAt(KB_X, FLOOR_Y, KB_Z)
        return
      }
    } else {
      // Keyboard focus — OrbitControls takes over
      if (!kbFocused.current) {
        kbFocused.current = true
        setKbFocused(true)
        camera.position.set(KB_X, 2.5, KB_Z + 5)
        camera.lookAt(KB_X, FLOOR_Y, KB_Z)
      }
      return
    }

    // Direct position for wall-lock + pan + turn; lerp for walk + focus + keyboard zoom
    const { active: faFinal } = getFocusState()
    const isLocked = !faFinal && p >= 0.58 && p < 0.93
    const isKeyboard = !faFinal && p >= 0.93
    if (isLocked) {
      curPos.current.copy(tPos)
      curLook.current.copy(tLook)
    } else if (isKeyboard) {
      curPos.current.lerp(tPos, 0.06)
      curLook.current.lerp(tLook, 0.06)
    } else {
      const ls = faFinal ? 0.18 : 0.08
      curPos.current.lerp(tPos, ls); curLook.current.lerp(tLook, ls)
    }

    camera.position.copy(curPos.current)

    // Subtle head-bob during corridor walk (sinusoidal Y offset)
    if (!faFinal && p < 0.58) {
      const walkSpeed = Math.abs(p - prevOff.current) * 400
      const bobAmount = Math.min(walkSpeed, 1) * 0.02
      camera.position.y += Math.sin(clock.elapsedTime * 3.5) * bobAmount
    }

    // FOV transition: 65 (gallery) -> 50 (keyboard intimate) during zoom
    const perspCam = camera as THREE.PerspectiveCamera
    const targetFov = p >= 0.97 ? 50 : (p >= 0.93 ? 65 - (Math.sin(((p - 0.93) / 0.04) * Math.PI / 2)) * 15 : 65)
    if (Math.abs(perspCam.fov - targetFov) > 0.1) {
      perspCam.fov += (targetFov - perspCam.fov) * 0.08
      perspCam.updateProjectionMatrix()
    }

    if (!faFinal && p >= 0.88 && p < 0.93) {
      // Manual Y rotation for the turn
      const turnT = (p - 0.88) / 0.05
      const ease = turnT * turnT * (3 - 2 * turnT)
      camera.rotation.set(0, -ease * Math.PI / 2, 0)
    } else if (!faFinal && p >= 0.93) {
      camera.lookAt(curLook.current)
    } else {
      camera.lookAt(curLook.current)
      const t = clock.elapsedTime
      camera.rotation.z += Math.sin(t * 0.5) * 0.002 + Math.sin(t * 0.3) * 0.001
    }
  })
  return null
}

/* ══════════════════════════════════════════════════════════
   GALLERY CORRIDOR + BACK WALL + KEYBOARD EXHIBITION HALL
   ══════════════════════════════════════════════════════════ */
function GalleryCorridor() {
  const mats = useMaterials()

  return (
    <group>
      {/* ── PROJECT CORRIDOR ─────────────────────────────── */}

      {/* Floor — Glossy Museum Concrete */}
      <mesh receiveShadow rotation={[-Math.PI / 2, 0, 0]} position={[KB_X / 2, FLOOR_Y, KB_Z]}>
        <planeGeometry args={[200, 200]} />
        <MeshReflectorMaterial
          blur={[400, 200]}
          resolution={256}
          mixBlur={2.5}
          mixStrength={1.5}
          roughness={0.9}
          depthScale={0}
          color="#8A7A62"
          metalness={0.05}
          mirror={0.05}
        />
      </mesh>

      {/* Ceiling — warm ceramic, bright */}
      <mesh rotation={[Math.PI / 2, 0, 0]} position={[KB_X / 2, CEIL_Y, KB_Z]}>
        <planeGeometry args={[200, 200]} />
        <meshStandardMaterial color={[0.85, 0.78, 0.72]} roughness={0.5} metalness={0.0} side={THREE.DoubleSide} />
      </mesh>

      {/* Left wall — full corridor length */}
      <mesh position={[-WALL_X, 0.5, -CORRIDOR_LEN / 2 + 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wall}>
        <planeGeometry args={[CORRIDOR_LEN + 4, CH + 2]} />
      </mesh>

      {/* Right wall — stops after 3 project pairs, creates L-opening */}
      <mesh position={[WALL_X, 0.5, (-RIGHT_WALL_LEN) / 2 + 2]} rotation={[0, -Math.PI / 2, 0]} material={mats.wall}>
        <planeGeometry args={[RIGHT_WALL_LEN, CH + 2]} />
      </mesh>

      {/* Entrance wall */}
      <group position={[0, 0, 4]}>
        <mesh material={mats.wall}><planeGeometry args={[CW, CH + 2]} /></mesh>
      </group>

      {/* Threshold cue — suspended light line at corridor entrance */}
      <ThresholdCue />

      {/* ── BACK WALL — About Me + Testimonials ────────── */}
      {/* Stops at keyboard room entry */}
      <mesh position={[(KB_ENTRY_X) / 2 - WALL_X, 0.5, BACK_WALL_Z]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X + CW, CH + 2]} />
      </mesh>

      {/* Front wall of testimonial wing — stops at room entry */}
      <mesh position={[(KB_ENTRY_X + WALL_X) / 2, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X - WALL_X, CH + 2]} />
      </mesh>

      {/* About Me — center of corridor (x=0) */}
      <group position={[0, 0, BACK_WALL_Z + 0.02]}>
        <mesh position={[0, 1.8, -0.02]}>
          <planeGeometry args={[5, 1.2]} />
          <meshBasicMaterial color="#C8A45C" transparent opacity={0.02} />
        </mesh>

        {/* Main Neon Title */}
        <Text position={[0, 1.75, 0]} fontSize={0.8} color="#FFE0B0" anchorX="center" anchorY="bottom" letterSpacing={0.05} font="/fonts/poseidon.otf">
          VISHAL RAJ
        </Text>
        <mesh position={[0, 1.65, 0]}><planeGeometry args={[2.5, 0.003]} /><meshBasicMaterial color="#C8A45C" /></mesh>

        {/* Description Bio */}
        <Text position={[0, 1.5, 0]} fontSize={0.11} color="#C4B496" anchorX="center" anchorY="top" maxWidth={4.2} textAlign="center" lineHeight={1.5} letterSpacing={0.02} font="/flutter/assets/fonts/inconsolata_nerd_mono_regular.ttf">
          I make software that works quietly and well. For a decade, I've been building mobile apps,
          developer tools, and lately, AI systems that can think for themselves. I believe good
          engineering is invisible — you only notice it when it's missing.
        </Text>
      </group>

      {/* ── BACK WALL LIGHTING — warm testimonial zone ── */}
      {/* Central overhead spotlight on back wall */}
      <BackWallSpotlight />
      {/* Warm fill lights along testimonial wall */}
      <pointLight position={[TEST_START_X, CEIL_Y - 1, BACK_WALL_Z + 2]} intensity={1.0} color="#FFE8C8" distance={15} decay={2} />
      <pointLight position={[TEST_START_X + TEST_CARDS.length * TEST_SPACING / 2, CEIL_Y - 0.5, BACK_WALL_Z + 1.5]} intensity={0.8} color="#FFF0D8" distance={20} decay={2} />

      {/* Testimonial frames on the back wall (includes CTA as last card) */}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialFrame
          key={t.id}
          testimonial={t}
          position={[TEST_START_X + i * TEST_SPACING, FRAME_Y, BACK_WALL_Z + 0.08]}
          mats={mats}
        />
      ))}

      {/* Individual spotlights on each testimonial frame */}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialSpotlight key={`tspot-${t.id}`} x={TEST_START_X + i * TEST_SPACING} />
      ))}

      {/* Graffiti back button — on left wall before frame 1 */}
      <GraffitiBackButton />

      {/* Radio player — on right wall opposite back button */}
      <WallRadio />

      {/* Left wall frames (4) */}
      {LEFT_PROJECTS.map((proj, i) => {
        const z = -(i + 1) * SPACING
        return (
          <group key={proj.id}>
            <WallFrame project={proj} position={[-WALL_X + 0.08, FRAME_Y, z]} side="left" projectIndex={i} mats={mats} />
            <TubeLight position={[-WALL_X + 0.08, CEIL_Y, z]} side="left" />
            <FrameSpotlight position={[-WALL_X + 0.08, FRAME_Y, z]} side="left" />
          </group>
        )
      })}

      {/* Right wall frames (3) */}
      {RIGHT_PROJECTS.map((proj, i) => {
        const z = -(i + 1) * SPACING
        return (
          <group key={proj.id}>
            <WallFrame project={proj} position={[WALL_X - 0.08, FRAME_Y, z]} side="right" projectIndex={LEFT_PROJECTS.length + i} mats={mats} />
            <TubeLight position={[WALL_X - 0.08, CEIL_Y, z]} side="right" />
            <FrameSpotlight position={[WALL_X - 0.08, FRAME_Y, z]} side="right" />
          </group>
        )
      })}


      {/* ── KEYBOARD EXHIBITION HALL — 24x24 room ──────── */}
      {/* Room center: (KB_X, KB_Z), walls at +/-12 from center */}
      {/* Entry wall at KB_ENTRY_X has 8-unit opening matching corridor width */}

      {/* Keyboard room walls (DoubleSide for orbit camera) */}
      <mesh position={[KB_X, 1.5, KB_Z + KB_ROOM / 2]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_X, 1.5, KB_Z - KB_ROOM / 2]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_END_X, 1.5, KB_Z]} rotation={[0, -Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      {/* Entry panels */}
      <mesh position={[KB_ENTRY_X, 1, (KB_Z + KB_ROOM / 2 + BACK_WALL_Z + CW) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X, 1, (BACK_WALL_Z + KB_Z - KB_ROOM / 2) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>

      {/* Corridor extension walls — prevent void when orbiting */}
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>

      {/* Let's Connect — on right wall of keyboard room */}
      <LetsConnectFrame />

      {/* Keyboard — centered in the hall */}
      <FloatingKB position={[KB_X, 0.6, KB_Z]} />

      <group position={[KB_X, 1.5, KB_Z]}>
        <KBParticles count={25} />
      </group>

    </group>
  )
}

/* ══════════════════════════════════════════════════════════
   EXPORTED SCENE — single gallery, single scroll
   ══════════════════════════════════════════════════════════ */

function KeyboardOrbit() {
  const controlsRef = useRef<any>(null)
  useFrame(() => {
    if (!controlsRef.current) return
    const active = getScrollProgress() >= 0.97
    controlsRef.current.enabled = active
    if (active) {
      controlsRef.current.target.set(KB_X, 0, KB_Z)
    }
  })
  return (
    <OrbitControls
      ref={controlsRef}
      enabled={false}
      enableZoom={false}
      enablePan={false}
      minPolarAngle={Math.PI / 4}
      maxPolarAngle={Math.PI / 2.2}
      dampingFactor={0.05}
      makeDefault
    />
  )
}

/* ── Reverse scroll direction — scroll up = walk forward into gallery ── */
function ReverseScroll() {
  const scroll = useScroll()
  const attached = useRef(false)

  useFrame(() => {
    if (attached.current || !scroll.el) return
    attached.current = true
    const el = scroll.el
    setScrollContainer(el)

    el.addEventListener('wheel', (e: WheelEvent) => {
      // When keyboard is focused, let OrbitControls handle wheel events
      if (isKbFocused()) return
      e.preventDefault()
      el.scrollTop -= e.deltaY
    }, { passive: false })
  })

  return null
}

/* ── Shader warm-up: compile all materials on first frames ── */
function ShaderWarmup() {
  const { gl, scene, camera } = useThree()
  const done = useRef(false)

  useFrame(() => {
    if (done.current) return
    done.current = true
    gl.compile(scene, camera)
  })

  return null
}

export function GalleryScene() {
  return (
    <Canvas
      dpr={Math.min(window.devicePixelRatio, 2)}
      camera={{ position: [0, 0.3, 3], fov: 65 }}
      gl={{ antialias: false, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 1.6, preserveDrawingBuffer: true, powerPreference: 'high-performance' }}
      style={{ position: 'absolute', inset: 0 }}
      onCreated={({ gl }) => { gl.setClearColor(new THREE.Color('#C4B496'), 1) }}
    >
      <color attach="background" args={['#C4B496']} />
      <fog attach="fog" args={['#C4B496', 25, 80]} />

      <ambientLight intensity={0.35} color="#FFF8E8" />
      <hemisphereLight args={['#FFF8E8', '#C4B496', 0.4]} />

      <KeyboardOrbit />
      <ShaderWarmup />

      {/* Post-Processing fixed pipeline: Render Scene -> Bloom over 1.0 -> ACES Filmic mapping -> Screen */}
      <EffectComposer>
        <Bloom luminanceThreshold={1.0} intensity={2.0} mipmapBlur />
        <ToneMapping mode={THREE.ACESFilmicToneMapping} />
      </EffectComposer>

      <Suspense fallback={null}>
        <ScrollControls pages={16} damping={0.2}>
          <ReverseScroll />
          <CameraRig />
          <GalleryCorridor />
        </ScrollControls>
      </Suspense>
    </Canvas>
  )
}
