/**
 * ThresholdCue — neon "SCROLL" cue at corridor entrance.
 *
 * Simplified: the 4 stair-lines were removed; the SCROLL text now carries
 * the beckon/lift/fade/idle-escalation motion on its own for a cleaner cue.
 */

import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { FLOOR_Y } from '../dimensions'
import { damp } from '../utils'
import { getScrollProgress } from '../galleryStore'

// Neon gold HDR color — values > 1.0 make Bloom glow
export const NEON_GOLD: [number, number, number] = [2.5, 1.8, 0.6]

export function ThresholdCue() {
  const grp = useRef<THREE.Group>(null)
  const opacity = useRef(1)
  const firstScrollRef = useRef(false)
  const scrollMatRef = useRef<THREE.MeshBasicMaterial>(null)

  useFrame(({ clock }, delta) => {
    if (!grp.current) return
    const t = clock.elapsedTime
    const p = getScrollProgress()

    // ── Idle escalation: after 4s no scroll, amplitude + speed grow ──
    const idleTime = p < 0.01 ? Math.max(0, t - 4.0) : 0
    const idleScale = 1 + Math.min(idleTime * 0.08, 0.6)
    const idleSpeed = 1 + Math.min(idleTime * 0.06, 0.5)

    // ── Beckon motion: asymmetric Z-bounce (fast lunge forward, slow return) ──
    const raw = Math.sin(t * 1.8)
    const skewed = raw > 0
      ? Math.pow(raw, 0.6)
      : -Math.pow(-raw, 1.4)
    grp.current.position.z = skewed * 0.22 * idleScale

    // Subtle Y hover
    const liftPhase = Math.sin(t * 1.8 + 0.3)
    grp.current.position.y = Math.max(0, liftPhase) * 0.015 * idleScale

    // ── Emissive breathing for the SCROLL text ──
    const breathRaw = Math.sin(t * 2.1)
    const breathSkew = breathRaw > 0 ? Math.pow(breathRaw, 0.5) : breathRaw
    const breathMul = 0.6 + breathSkew * 0.4

    // Pulse on the SCROLL material
    const pulse = Math.pow(Math.max(0, Math.sin(t * 2.2 * idleSpeed)), 2.0)
    const glow = (0.5 + pulse * 0.5) * breathMul * idleScale
    if (scrollMatRef.current) {
      scrollMatRef.current.color.setRGB(
        NEON_GOLD[0] * glow,
        NEON_GOLD[1] * glow,
        NEON_GOLD[2] * glow,
      )
      scrollMatRef.current.opacity = opacity.current * 0.8
    }

    // ── Fade choreography ──
    if (firstScrollRef.current && p < 0.003) firstScrollRef.current = false
    if (!firstScrollRef.current && p > 0.005) firstScrollRef.current = true
    const justStarted = firstScrollRef.current && p < 0.02
    const targetScale = justStarted ? 1.15 : 1.0
    const s = grp.current.scale.x
    grp.current.scale.setScalar(s + (targetScale - s) * (1 - Math.exp(-6 * delta)))

    const fadeTarget = p < 0.03 ? 1
      : p < 0.12 ? 1 - Math.pow((p - 0.03) / 0.09, 1.6)
      : 0
    opacity.current = damp(opacity.current, fadeTarget, 5, delta)
    grp.current.visible = opacity.current > 0.01
  })

  return (
    <group ref={grp}>
      {/* "SCROLL" neon text — flat on floor at corridor entrance */}
      <Text
        position={[0, FLOOR_Y + 0.02, -4.0]}
        rotation={[-Math.PI / 2, 0, 0]}
        fontSize={0.35}
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.35}
        font="/fonts/inconsolata_nerd_mono_regular.ttf"
      >
        <meshBasicMaterial ref={scrollMatRef} color={NEON_GOLD} toneMapped={false} transparent opacity={0.8} />
        SCROLL
      </Text>
    </group>
  )
}
