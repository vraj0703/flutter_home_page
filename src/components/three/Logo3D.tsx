import { useRef, useState, useCallback, useEffect, useMemo } from 'react'
import { useFrame } from '@react-three/fiber'
import type { Group, ShaderMaterial, Texture } from 'three'
import logoVert from '../../shaders/logo.vert?raw'
import logoFrag from '../../shaders/logo.frag?raw'

function springStep(
  current: number, target: number, velocity: number,
  mass: number, stiffness: number, damping: number, dt: number
): [number, number] {
  const force = -stiffness * (current - target) - damping * velocity
  const accel = force / mass
  const newVel = velocity + accel * dt
  return [current + newVel * dt, newVel]
}

interface Logo3DProps {
  texture: Texture | null
  onClick?: () => void
  miniMode?: boolean
}

const TINT = [0.78, 0.557, 0.325] // #C78E53

export function Logo3D({ texture, onClick, miniMode = false }: Logo3DProps) {
  const groupRef = useRef<Group>(null)
  const matRef = useRef<ShaderMaterial>(null)
  const [hovered, setHovered] = useState(false)

  const spring = useRef({
    x: 0, y: 0.2, scale: 3.0,
    vx: 0, vy: 0, vScale: 0,
  })

  const SP = { mass: 0.8, stiffness: 200, damping: 15 }
  const target = useRef({ x: 0, y: 0.2, scale: 3.0 })

  useEffect(() => {
    if (miniMode) {
      target.current = { x: -3.2, y: 2.0, scale: 0.3 }
    } else {
      target.current = { x: 0, y: 0.2, scale: 3.0 }
    }
  }, [miniMode])

  const uniforms = useMemo(() => ({
    uSize: { value: [1, 1] },
    uLogoTexture: { value: texture },
    uTint: { value: TINT },
    uOpacity: { value: 1.0 },
  }), [texture])

  useFrame((_, delta) => {
    if (!groupRef.current) return
    const dt = Math.min(delta, 1 / 30)
    const s = spring.current
    const t = target.current

    ;[s.x, s.vx] = springStep(s.x, t.x, s.vx, SP.mass, SP.stiffness, SP.damping, dt)
    ;[s.y, s.vy] = springStep(s.y, t.y, s.vy, SP.mass, SP.stiffness, SP.damping, dt)
    ;[s.scale, s.vScale] = springStep(s.scale, t.scale, s.vScale, SP.mass, SP.stiffness, SP.damping, dt)

    groupRef.current.position.x = s.x
    groupRef.current.position.y = s.y
    groupRef.current.scale.setScalar(s.scale)

    if (matRef.current) {
      matRef.current.uniforms.uOpacity.value = hovered ? 1.0 : 0.95
    }
  })

  const handlePointerOver = useCallback(() => {
    setHovered(true)
    document.body.style.cursor = 'pointer'
  }, [])

  const handlePointerOut = useCallback(() => {
    setHovered(false)
    document.body.style.cursor = 'default'
  }, [])

  if (!texture) return null

  const aspect = texture.image ? (texture.image as HTMLImageElement).width / (texture.image as HTMLImageElement).height : 1

  return (
    <group ref={groupRef} position={[0, 0.2, 0]} scale={[3, 3, 3]}>
      <mesh
        onClick={onClick}
        onPointerOver={handlePointerOver}
        onPointerOut={handlePointerOut}
      >
        <planeGeometry args={[0.8 * aspect, 0.8]} />
        <shaderMaterial
          ref={matRef}
          vertexShader={logoVert}
          fragmentShader={logoFrag}
          uniforms={uniforms}
          transparent
          depthWrite={false}
        />
      </mesh>
    </group>
  )
}
