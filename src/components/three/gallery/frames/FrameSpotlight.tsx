import { useRef, useEffect } from 'react'
import * as THREE from 'three'

export function FrameSpotlight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
  const lightRef = useRef<THREE.SpotLight>(null)
  const targetX = side === 'left' ? position[0] + 0.5 : position[0] - 0.5
  // Static target — set once, not per frame
  useEffect(() => {
    if (lightRef.current) {
      lightRef.current.target.position.set(position[0], position[1], position[2])
      lightRef.current.target.updateMatrixWorld()
    }
  })
  return (
    <spotLight
      ref={lightRef}
      position={[targetX, position[1] + 2.5, position[2]]}
      angle={0.45}
      penumbra={0.8}
      intensity={1.2}
      color="#FFE0B0"
      distance={6}
      decay={2}
    />
  )
}
