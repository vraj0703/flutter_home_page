/**
 * WallRadio — streaming radio player on right wall
 *
 * Extracted from GalleryScene.tsx (pure mechanical refactor).
 */

import { useRef, useMemo, useEffect, useState, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'

import { WALL_X, FRAME_Y } from '../dimensions'

// Neon HDR color constants — hoisted outside component to avoid per-render alloc
const NEON_CYAN: [number, number, number] = [0.2, 2.0, 2.5]
const NEON_PINK: [number, number, number] = [2.8, 0.4, 1.5]
const NEON_YELLOW: [number, number, number] = [2.5, 2.0, 0.4]
const NEON_GREEN: [number, number, number] = [0.4, 2.5, 0.6]
const NEON_DISABLED: [number, number, number] = [0.8, 0.8, 0.8]
import { damp, tmpVec3 } from '../utils'
import {
  nextRadioChannel, stopRadio,
  subscribeRadio, getRadioState, _playRadio,
} from '../../../../audio/RadioEngine'
import { getAudioEngine } from '../../../../audio'

export function WallRadio() {
  const grp = useRef<THREE.Group>(null)
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

  // P key toggles radio play/stop (M key used to mute — no longer needed)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'p' || e.key === 'P') {
        const { playing } = getRadioState()
        if (playing) stopRadio(); else _playRadio()
      }
    }
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
    glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, proximity * 0.2, 10, delta)
    glowMat.opacity = damp(glowMat.opacity, proximity * 0.05, 10, delta)
    // Knob rotation: 0 vol = -135°, 1 vol = +135°
    if (knobRef.current) {
      const { volume } = getRadioState()
      const targetAngle = (-135 + volume * 270) * Math.PI / 180
      knobRef.current.rotation.z = damp(knobRef.current.rotation.z, targetAngle, 15, delta)
    }
  })

  // Two-state toggle: PLAY ⇄ STOP (no intermediate mute state)
  const handlePlayToggle = useCallback(() => {
    const { playing: _radioPlaying } = getRadioState()
    if (_radioPlaying) {
      stopRadio()
    } else {
      _playRadio()
    }
    getAudioEngine()?.playButtonClick()
  }, [])

  const handleNext = useCallback(() => {
    nextRadioChannel()
    getAudioEngine()?.playButtonClick()
  }, [])

  const { playing: _radioPlaying, loading: _radioLoading, channel: channelName } = getRadioState()
  const statusText = _radioLoading ? 'TUNING...' : _radioPlaying ? 'ON AIR' : 'OFF'
  const statusColor = _radioLoading ? NEON_YELLOW : _radioPlaying ? NEON_GREEN : NEON_DISABLED

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
          <meshBasicMaterial color={NEON_CYAN} toneMapped={false} />
          {channelName}
        </Text>

        {/* ── Subtitle: Status ── */}
        <Text position={[0, 0.05, 0.01]} fontSize={0.07} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/inconsolata_nerd_mono_regular.ttf">
          <meshBasicMaterial color={statusColor} toneMapped={false} />
          {`[ ${statusText} ]`}
        </Text>

        {/* ── Controls Row (Pure Stencil Text) ── */}

        {/* Play/Stop Button — two-state toggle. Positioned + sized so click
            plane does NOT overlap with NEXT (was at x=-0.25 width 0.8 which
            overlapped NEXT at x=+0.25 width 0.6 → STOP would trigger NEXT). */}
        <group position={[-0.35, -0.3, 0.01]}
          onClick={(e) => { e.stopPropagation(); handlePlayToggle() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={_radioPlaying ? NEON_CYAN : NEON_PINK} toneMapped={false} />
            {_radioPlaying ? 'STOP' : 'PLAY'}
          </Text>
          <mesh><planeGeometry args={[0.55, 0.35]} /><meshBasicMaterial transparent opacity={0} /></mesh>
        </group>

        {/* Next Button */}
        <group position={[0.35, -0.3, 0.01]}
          onClick={(e) => { e.stopPropagation(); handleNext() }}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={NEON_PINK} toneMapped={false} />
            NEXT
          </Text>
          <mesh><planeGeometry args={[0.55, 0.35]} /><meshBasicMaterial transparent opacity={0} /></mesh>
        </group>

        {/* Graffiti Underline */}
        <mesh position={[0, -0.5, 0.01]}>
          <planeGeometry args={[1.2, 0.005]} />
          <meshBasicMaterial color={NEON_CYAN} transparent opacity={0.6} toneMapped={false} />
        </mesh>
      </group>
    </group>
  )
}
