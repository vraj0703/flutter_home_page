/**
 * GraffitiBackButton — spray-painted on left wall before frame 1
 *
 * Extracted from GalleryScene.tsx (pure mechanical refactor).
 */

import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { WALL_X, FRAME_Y } from '../dimensions'
import { damp, tmpVec3 } from '../utils'
import { fireBackClick } from '../galleryStore'
import { getAudioEngine } from '../../../../audio'

export function GraffitiBackButton() {
  const grp = useRef<THREE.Group>(null)
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
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, proximity * 0.2, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, proximity * 0.06, 10, delta)
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
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[1.6, 1.0]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}
