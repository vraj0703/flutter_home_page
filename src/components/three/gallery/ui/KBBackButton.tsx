/**
 * KBBackButton — neon back button on KB entry wall (visible behind keyboard
 * from hero camera, above the corridor passage).
 */

import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { KB_ENTRY_X, KB_Z, KB_ROOM, BACK_WALL_Z, CW } from '../dimensions'
import { damp, tmpVec3 } from '../utils'
import { fireKBBackClick } from '../galleryStore'
import { getAudioEngine } from '../../../../audio'

// Shared Y with LetsConnectFrame for vertical alignment
const BUTTON_Y = 1.8

export function KBBackButton() {
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
    const proximity = Math.max(0, 1 - dist / 14)
    const targetGlow = hov.current ? 0.8 : proximity * 0.25
    const targetOpacity = hov.current ? 0.15 : proximity * 0.08
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
  })

  return (
    <group
      position={[
        KB_ENTRY_X + 0.1,
        BUTTON_Y,
        (KB_Z + KB_ROOM / 2 + BACK_WALL_Z + CW) / 2,
      ]}
      rotation={[0, Math.PI / 2, 0]}
    >
      <group ref={grp}>
        {/* Hover glow backdrop */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[2.4, 1.2]} />
        </mesh>

        {/* Arrow ← (default font — modrnt_urban.otf doesn't have the glyph).
            Kept close to BACK text (0.33u apart total) so both fit inside FOV
            cone from any orbit angle. Previous design had ~0.85u separation
            which clipped out parts at extreme angles. */}
        <Text
          position={[-0.32, 0.02, 0.01]}
          fontSize={0.42}
          anchorX="center"
          anchorY="middle"
        >
          <meshBasicMaterial color={[1.8, 1.5, 1.1]} toneMapped={false} side={THREE.DoubleSide} />
          {'\u2190'}
        </Text>

        {/* Text: BACK */}
        <Text
          position={[0.12, 0.02, 0.01]}
          fontSize={0.38}
          anchorX="center"
          anchorY="middle"
          letterSpacing={0.12}
          font="/flutter/assets/fonts/modrnt_urban.otf"
        >
          <meshBasicMaterial color={[2.5, 1.8, 0.8]} toneMapped={false} side={THREE.DoubleSide} />
          BACK
        </Text>

        {/* Underline drip */}
        <mesh position={[0, -0.35, 0.008]}>
          <planeGeometry args={[1.8, 0.025]} />
          <meshStandardMaterial color="#E8E0D0" transparent opacity={0.4} roughness={1} metalness={0} />
        </mesh>

        {/* Invisible click plane */}
        <mesh
          position={[0, 0, 0.02]}
          onClick={() => { fireKBBackClick(); getAudioEngine()?.playButtonClick() }}
          onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[2.4, 1.2]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}
