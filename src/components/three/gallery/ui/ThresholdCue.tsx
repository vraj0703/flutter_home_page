/**
 * ThresholdCue — neon stair-lines receding into corridor
 *
 * Extracted from GalleryScene.tsx (pure mechanical refactor).
 */

import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { FLOOR_Y } from '../dimensions'
import { damp } from '../utils'
import { getScrollProgress } from '../galleryStore'

// Stair line config: vertical crosswalk stripes across the floor, receding into corridor.
// Each line is a thin upright plane (width × height) at the floor level.
// w = width across corridor (widens = funnel), h = visible height, z = depth into corridor
export const STAIR_LINES = [
  { z: -2.5, w: 3.2, h: 0.02 },  // line 1 — widest
  { z: -3.3, w: 2.4, h: 0.02 },  // line 2
  // SCROLL text sits here at z=-4.0
  { z: -4.7, w: 1.2, h: 0.02 },  // line 3
  { z: -5.5, w: 0.4, h: 0.02 },  // line 4 — narrowest
]

// Neon gold HDR color — values > 1.0 make Bloom glow (like the radio/back button)
export const NEON_GOLD: [number, number, number] = [2.5, 1.8, 0.6]

export function ThresholdCue() {
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
    // Beckon shifts whole group forward into corridor
    grp.current.position.z = beckonZ

    // Subtle Y hover
    const liftPhase = Math.sin(t * 1.8 + 0.3)
    grp.current.position.y = Math.max(0, liftPhase) * 0.015 * idleScale

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

      // Combine: pulse + breath. Floor at 0.5 so lines never go invisible
      const glow = (0.5 + pulse * 0.5) * breathMul * idleScale

      mat.color.setRGB(
        NEON_GOLD[0] * glow,
        NEON_GOLD[1] * glow,
        NEON_GOLD[2] * glow,
      )
      mat.opacity = opacity.current
    }

    // ── Fade choreography ──
    // First-scroll reward: brief 15% scale-up on first movement
    // Reset when user returns to entrance (scroll back to top)
    if (firstScrollRef.current && p < 0.003) firstScrollRef.current = false
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
    <group ref={grp}>
      {/* Neon stair lines — flat on floor, receding into corridor like runway stripes */}
      {STAIR_LINES.map((line, i) => (
        <mesh
          key={i}
          ref={el => { lineRefs.current[i] = el }}
          position={[0, FLOOR_Y + 0.02, line.z]}
          rotation={[-Math.PI / 2, 0, 0]}
        >
          <planeGeometry args={[line.w, line.h]} />
          <meshBasicMaterial
            color={NEON_GOLD}
            transparent
            opacity={1.0}
            toneMapped={false}
            side={THREE.DoubleSide}
          />
        </mesh>
      ))}

      {/* "SCROLL" neon text — flat on floor between first two lines */}
      <Text
        position={[0, FLOOR_Y + 0.02, -4.0]}
        rotation={[-Math.PI / 2, 0, 0]}
        fontSize={0.35}
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
