import { useRef } from 'react'
import { useFrame, useThree } from '@react-three/fiber'

/* ── Shader warm-up: compile all materials on first frames ── */
export function ShaderWarmup() {
  const { gl, scene, camera } = useThree()
  const done = useRef(false)

  useFrame(() => {
    if (done.current) return
    done.current = true
    gl.compile(scene, camera)
  })

  return null
}
