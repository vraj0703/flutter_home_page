import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'

import { isKbFocused } from '../galleryStore'
import { KB_X, KB_Z } from '../dimensions'
import { KB_VIEW_TARGET_Y } from './cameraConstants'

export function KeyboardOrbit() {
  const controlsRef = useRef<any>(null)
  const lastEnabled = useRef(false)

  useFrame(() => {
    if (!controlsRef.current) return
    const active = isKbFocused()
    if (lastEnabled.current !== active) {
      lastEnabled.current = active
      controlsRef.current.enabled = active
      if (active) {
        // Target matches CameraRig's KB_VIEW_TARGET_Y so the orbit pivots
        // around the actual keyboard cap surface (not 0.21u above it).
        controlsRef.current.target.set(KB_X, KB_VIEW_TARGET_Y, KB_Z)
        controlsRef.current.update()
      }
    }
  })
  return (
    <OrbitControls
      ref={controlsRef}
      enabled={false}
      enableZoom={false}
      enablePan={false}
      // Polar limits frame the keyboard as a hero on a pedestal — no ceiling,
      // no floor crawl. ~61° to ~86° from +Y axis.
      minPolarAngle={Math.PI * 0.34}
      maxPolarAngle={Math.PI * 0.48}
      enableDamping={true}
      // Dropped from 0.12 → 0.08 (~140ms half-life). Combined with rotateSpeed
      // 0.5, flicks now glide instead of wading. Premium weight comes from the
      // 300ms breath-hold before orbit enables, not from sluggish damping.
      dampingFactor={0.08}
      rotateSpeed={0.5}
    />
  )
}
