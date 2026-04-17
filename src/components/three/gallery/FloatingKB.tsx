import { useRef, useState } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import { Keyboard as SkillKeyboard } from '../KeyboardScene'
import { getScrollProgress } from './galleryStore'
import { damp } from './utils'

export function FloatingKB({ position }: { position: [number, number, number] }) {
  const outerRef = useRef<THREE.Group>(null)
  // 3-phase lifecycle:
  // - unmounted (scroll < 5%): nothing in scene graph
  // - preloading (5-93%): mounted 500 units below, compiling shaders across frames
  // - visible (>93%): camera turn is complete, teleport to real position
  const [phase, setPhase] = useState<'preloading' | 'visible'>('preloading')

  useFrame(({ clock }, delta) => {
    const p = getScrollProgress()
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
