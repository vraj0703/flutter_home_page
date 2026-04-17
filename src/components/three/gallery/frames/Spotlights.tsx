import { useRef, useEffect } from 'react'
import * as THREE from 'three'
import { FRAME_Y, CEIL_Y, BACK_WALL_Z } from '../dimensions'

/* ── Back wall spotlight — warm overhead aimed at back wall center ── */
export function BackWallSpotlight() {
  const ref = useRef<THREE.SpotLight>(null)
  // Static target — set once
  useEffect(() => {
    if (ref.current) { ref.current.target.position.set(0, 1, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[0, CEIL_Y - 0.3, BACK_WALL_Z + 3]} angle={0.6} penumbra={0.9} intensity={2.5} color="#FFD9A0" distance={10} decay={1.5} />
}

/* ── Testimonial spotlight — individual warm light per frame ── */
export function TestimonialSpotlight({ x }: { x: number }) {
  const ref = useRef<THREE.SpotLight>(null)
  // Static target — set once
  useEffect(() => {
    if (ref.current) { ref.current.target.position.set(x, FRAME_Y, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[x, CEIL_Y - 0.5, BACK_WALL_Z + 2.5]} angle={0.4} penumbra={0.8} intensity={1.0} color="#FFE0B0" distance={6} decay={2} />
}
