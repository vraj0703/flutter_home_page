import { useRef, useState } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import { Keyboard as SkillKeyboard } from '../KeyboardScene'
import { getScrollProgress, isKbFocused } from './galleryStore'
import { damp } from './utils'

/* ── Keyboard orientation ───────────────────────────
   The inner group is rotated -π/2 on Y. Outer rotation = π gives a combined
   rotation of π/2 — keyboard's LANGUAGES row (local +Z) faces world +X.
   The camera flies around 180° to land on the +X side, so the LANGUAGES row
   ends up facing the camera = natural "sit-down-to-type" hero shot.
*/
const KB_REST_ROT = Math.PI

export function FloatingKB({ position }: { position: [number, number, number] }) {
  const outerRef = useRef<THREE.Group>(null)
  const [phase, setPhase] = useState<'preloading' | 'visible'>('preloading')

  useFrame(({ clock }, delta) => {
    const p = getScrollProgress()
    if (phase === 'preloading' && p > 0.93) setPhase('visible')
    if (phase === 'visible' && p < 0.05) setPhase('preloading')

    if (!outerRef.current) return

    if (isKbFocused()) {
      // Locked at rest orientation while user interacts via OrbitControls.
      outerRef.current.rotation.y = KB_REST_ROT
      outerRef.current.position.y = position[1]
      return
    }

    if (p < 0.97) {
      // Pre-reveal ambient spin (only visible if keyboard is in corridor view —
      // currently hidden below scene during preloading state).
      const baseRot = clock.elapsedTime * 0.1
      outerRef.current.rotation.y = KB_REST_ROT + baseRot % (Math.PI * 2)
      outerRef.current.position.y = position[1] + Math.sin(clock.elapsedTime * 0.4) * 0.08
    } else {
      // Settle to rest orientation, ready for Skills click camera orbit.
      let diff = KB_REST_ROT - outerRef.current.rotation.y
      while (diff < -Math.PI) diff += Math.PI * 2
      while (diff > Math.PI) diff -= Math.PI * 2
      outerRef.current.rotation.y += diff * (1 - Math.exp(-3 * delta))
      outerRef.current.position.y = damp(outerRef.current.position.y, position[1], 3, delta)
    }
  })

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
