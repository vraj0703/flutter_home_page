import { Canvas } from '@react-three/fiber'
import { EffectComposer, Vignette } from '@react-three/postprocessing'
import type { Texture } from 'three'
import { Logo3D } from './Logo3D'
import { GodRays } from './GodRays'
import { BouncyLines } from './BouncyLines'

interface LandingSceneProps {
  onLogoClick?: () => void
  miniMode?: boolean
  bgOpacity?: number
  logoTexture: Texture | null
}

export function LandingScene({ onLogoClick, miniMode = false, bgOpacity = 1, logoTexture }: LandingSceneProps) {
  const logoScale = miniMode ? 0.3 : 3.0

  return (
    <Canvas
      camera={{ position: [0, 0, 5], fov: 45 }}
      gl={{ antialias: true, alpha: false }}
      style={{ position: 'absolute', inset: 0 }}
    >
      {/* God rays = the entire background (sandy floor + logo shadow + sun glow) */}
      {logoTexture && (
        <GodRays logoTexture={logoTexture} opacity={bgOpacity} />
      )}

      {/* Logo rendered with SDF gold tint shader on top */}
      <Logo3D texture={logoTexture} onClick={onLogoClick} miniMode={miniMode} />

      {/* Bouncy lines around logo */}
      <BouncyLines visible={!miniMode} logoScale={logoScale} />

      <EffectComposer>
        <Vignette eskil={false} offset={0.15} darkness={0.3} />
      </EffectComposer>
    </Canvas>
  )
}
