/**
 * LetsConnectFrame — neon CTA on KB end wall (opposite from Back button).
 * Vertically aligned with KBBackButton at Y=1.8.
 */

import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { KB_ENTRY_X, BACK_WALL_Z, KB_Z, KB_ROOM } from '../dimensions'
import { damp, tmpVec3 } from '../utils'
import { fireConnectClick } from '../galleryStore'
import { getAudioEngine } from '../../../../audio'

// Shared Y with KBBackButton for vertical alignment
const BUTTON_Y = 1.8

export function LetsConnectFrame() {
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
    const proximity = Math.max(0, 1 - dist / 14)
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, proximity * 0.25, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, proximity * 0.08, 10, delta)
  })

  return (
    <group
      position={[KB_ENTRY_X + 0.1, BUTTON_Y, (BACK_WALL_Z + KB_Z - KB_ROOM / 2) / 2]}
      rotation={[0, Math.PI / 2, 0]}
    >
      <group ref={grp}>
        {/* Hover glow backdrop */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[3.6, 1.2]} />
        </mesh>

        {/* Text: LET'S CONNECT */}
        <Text
          position={[0, 0.02, 0.01]}
          fontSize={0.38}
          anchorX="center"
          anchorY="middle"
          letterSpacing={0.1}
          font="/flutter/assets/fonts/modrnt_urban.otf"
        >
          <meshBasicMaterial color={[2.5, 1.8, 0.8]} toneMapped={false} />
          LET'S CONNECT
        </Text>

        {/* Underline drip */}
        <mesh position={[0, -0.35, 0.008]}>
          <planeGeometry args={[2.6, 0.025]} />
          <meshStandardMaterial color="#E8E0D0" transparent opacity={0.4} roughness={1} metalness={0} />
        </mesh>

        {/* Invisible click plane */}
        <mesh
          position={[0, 0, 0.02]}
          onClick={() => { fireConnectClick(); getAudioEngine()?.playButtonClick() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[3.6, 1.2]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}
