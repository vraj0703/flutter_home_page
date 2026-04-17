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
const NEON_RED: [number, number, number] = [2.5, 0.5, 0.5]
const NEON_GREEN: [number, number, number] = [0.4, 2.5, 0.6]
const NEON_DISABLED: [number, number, number] = [0.8, 0.8, 0.8]
import { damp, tmpVec3 } from '../utils'
import {
  toggleRadioMute, setRadioVolume, nextRadioChannel,
  subscribeRadio, getRadioState, _playRadio,
} from '../../../../audio/RadioEngine'
import { getAudioEngine } from '../../../../audio'

export function WallRadio() {
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

  const statusColor = _radioLoading ? NEON_YELLOW : _radioPlaying ? (_radioMuted ? NEON_RED : NEON_GREEN) : NEON_DISABLED

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

        {/* VOL Cycle Button */}
        <group position={[-0.4, -0.3, 0.01]}
          onClick={handleVolumeCycle}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          <Text fontSize={0.09} anchorX="center" anchorY="middle" letterSpacing={0.1} font="/flutter/assets/fonts/modrnt_urban.otf">
            <meshBasicMaterial color={NEON_YELLOW} toneMapped={false} />
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
            <meshBasicMaterial color={_radioPlaying ? (_radioMuted ? NEON_DISABLED : NEON_CYAN) : NEON_PINK} toneMapped={false} />
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
            <meshBasicMaterial color={NEON_PINK} toneMapped={false} />
            NEXT
          </Text>
          <mesh><planeGeometry args={[0.4, 0.2]} /><meshBasicMaterial transparent opacity={0} /></mesh>
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
