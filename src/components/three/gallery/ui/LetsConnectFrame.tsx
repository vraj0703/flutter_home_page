/**
 * LetsConnectFrame — framed CTA on keyboard room right wall
 *
 * Extracted from GalleryScene.tsx (pure mechanical refactor).
 */

import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { KB_ENTRY_X, BACK_WALL_Z, KB_Z, KB_ROOM } from '../dimensions'
import { damp, tmpVec3 } from '../utils'
import { fireConnectClick } from '../galleryStore'
import { getAudioEngine } from '../../../../audio'

export function LetsConnectFrame() {
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
