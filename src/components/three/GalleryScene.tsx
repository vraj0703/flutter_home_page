/**
 * GalleryScene.tsx — Canvas shell for the 3D gallery.
 *
 * All visual, UI, camera, and scene assembly components have been decomposed
 * into the gallery/ subfolder. This file is purely the R3F Canvas + post-
 * processing pipeline + ScrollControls wrapper.
 *
 * Layout:  gallery/GalleryCorridor  (scene graph)
 * Camera:  gallery/camera/CameraRig, KeyboardOrbit, ReverseScroll
 * State:   gallery/galleryStore     (all shared state & event buses)
 */

import { Suspense, useEffect, useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { ScrollControls, AdaptiveDpr } from '@react-three/drei'
import { EffectComposer, Bloom } from '@react-three/postprocessing'
import * as THREE from 'three'

// Scene assembly
import { GalleryCorridor } from './gallery/GalleryCorridor'

// Camera system
import { CameraRig } from './gallery/camera/CameraRig'
import { KeyboardOrbit } from './gallery/camera/KeyboardOrbit'
import { ReverseScroll } from './gallery/camera/ReverseScroll'
import { ShaderWarmup } from './gallery/camera/ShaderWarmup'

// Frameloop gate — paused when user transitions to contact page
import { subscribeGalleryFrameloop } from './gallery/galleryStore'

/* ── Re-exports for backward compatibility ─────────────────── */
export {
  subscribeCTAClick, subscribeBackClick, subscribeConnectClick,
  subscribeKbFocus, setClickTarget,
  resetGalleryScroll,
} from './gallery/galleryStore'
export {
  preloadRadio, stopRadio, startRadioOnGalleryEnter,
  toggleRadioMute, setRadioVolume, nextRadioChannel,
  subscribeRadio, getRadioState,
} from '../../audio/RadioEngine'

export function GalleryScene() {
  // frameloop gate — when the app transitions to the contact phase, App.tsx
  // calls setGalleryFrameloopActive(false), pausing the Canvas so Flutter
  // can use the GPU without contention during its entrance animation.
  const [frameloopActive, setFrameloopActive] = useState(true)
  useEffect(() => subscribeGalleryFrameloop(setFrameloopActive), [])

  return (
    <Canvas
      frameloop={frameloopActive ? 'always' : 'never'}
      // DPR cap lowered from 2 to 1.5 — on a 2880×1800 retina display that
      // drops the fragment-shader pixel count by ~43%, which combined with
      // Bloom's extra pass is the biggest GPU win we can ship cheaply. The
      // visual difference is imperceptible at the gallery's viewing scale.
      dpr={[1, 1.5]}
      camera={{ position: [0, 0.3, 3], fov: 65 }}
      gl={{ antialias: false, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 1.6, preserveDrawingBuffer: false, powerPreference: 'high-performance' }}
      style={{ position: 'absolute', inset: 0 }}
      onCreated={({ gl }) => { gl.setClearColor(new THREE.Color('#C4B496'), 1) }}
    >
      {/* AdaptiveDpr listens to R3F's perf-regression signal and drops DPR
          when FPS tanks (scroll spam, low-end GPUs). `pixelated` keeps the
          downscaled canvas sharp via nearest-neighbor instead of the default
          linear upsample. */}
      <AdaptiveDpr pixelated />

      <color attach="background" args={['#C4B496']} />
      <fog attach="fog" args={['#C4B496', 25, 80]} />

      <ambientLight intensity={0.35} color="#FFF8E8" />
      <hemisphereLight args={['#FFF8E8', '#C4B496', 0.4]} />

      <ShaderWarmup />

      {/* Post-Processing: Bloom only. Tone mapping is applied by the renderer
          (gl.toneMapping = ACESFilmic). mipmapBlur disabled — its downsample
          chain sampled stale render targets during rapid camera motion. */}
      <EffectComposer>
        <Bloom luminanceThreshold={1.0} intensity={1.6} radius={0.7} />
      </EffectComposer>

      <Suspense fallback={null}>
        <ScrollControls pages={16} damping={0.2}>
          <ReverseScroll />
          <CameraRig />
          <KeyboardOrbit />
          <GalleryCorridor />
        </ScrollControls>
      </Suspense>
    </Canvas>
  )
}
