import { useRef, useMemo } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import type { ShaderMaterial, Texture } from 'three'
import godRaysFrag from '../../shaders/godRays.frag?raw'
import logoVert from '../../shaders/logo.vert?raw'

interface GodRaysProps {
  logoTexture: Texture
  opacity?: number
}

export function GodRays({ logoTexture, opacity: _opacity = 1 }: GodRaysProps) {
  const ref = useRef<ShaderMaterial>(null)
  const { viewport, size } = useThree()

  // Light position in pixel space (Y=0 at top), smoothed
  const lightPx = useRef({ x: size.width / 2, y: size.height * 0.3 })

  const uniforms = useMemo(() => ({
    uSize: { value: [size.width, size.height] },
    uLightPos: { value: [size.width / 2, size.height * 0.3] },
    uLogoPos: { value: [size.width / 2, size.height * 0.45] },
    uLogoSize: { value: [size.width * 0.35, size.height * 0.45] },
    uLogoTexture: { value: logoTexture },
  }), [])

  useFrame(({ pointer }, delta) => {
    if (!ref.current) return
    const u = ref.current.uniforms

    // Pointer NDC (-1..1) → pixel coords (Y=0 at top)
    const targetX = (pointer.x * 0.5 + 0.5) * size.width
    const targetY = (1.0 - (pointer.y * 0.5 + 0.5)) * size.height

    // Frame-rate independent smooth follow (was: * 0.04 which is frame-rate dependent)
    const speed = 2.5
    lightPx.current.x += (targetX - lightPx.current.x) * (1 - Math.exp(-speed * delta))
    lightPx.current.y += (targetY - lightPx.current.y) * (1 - Math.exp(-speed * delta))

    u.uSize.value = [size.width, size.height]
    u.uLightPos.value = [lightPx.current.x, lightPx.current.y]
    // Logo stays centered — update if logo moves (miniMode)
    u.uLogoPos.value = [size.width / 2, size.height * 0.45]
    u.uLogoSize.value = [size.width * 0.35, size.height * 0.45]
    u.uLogoTexture.value = logoTexture
  })

  return (
    <mesh position={[0, 0, -5]} scale={[viewport.width * 2, viewport.height * 2, 1]}>
      <planeGeometry args={[1, 1]} />
      <shaderMaterial
        ref={ref}
        vertexShader={logoVert}
        fragmentShader={godRaysFrag}
        uniforms={uniforms}
        depthWrite={false}
      />
    </mesh>
  )
}
