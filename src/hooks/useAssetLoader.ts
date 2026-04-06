import { useState, useEffect, useRef } from 'react'
import { Howl } from 'howler'
import { TextureLoader, type Texture } from 'three'

const PRIORITY_AUDIO: Record<string, string> = {
  titleLoaded: '/audio/title_loaded.mp3',
  harpEnter: '/audio/harp_enter.mp3',
  boldText: '/audio/bold_text.mp3',
  enterSound: '/audio/enter_sound.mp3',
  bouncyArrow: '/audio/bouncy_arrow.mp3',
  whoosh: '/audio/whoosh.mp3',
}

const FONT_CHECKS = [
  '400 1em ModrntUrban',
  '400 1em InconsolataNerd',
  '400 1em Poseidon',
]

// Weights: fonts 20%, audio 50%, textures 10%, webgl 20%
const W = { fonts: 0.2, audio: 0.5, textures: 0.1, webgl: 0.2 }

export interface AssetLoaderResult {
  progress: number
  ready: boolean
  logoTexture: Texture | null
  preloadedAudio: Map<string, Howl>
}

export function useAssetLoader(): AssetLoaderResult {
  const [progress, setProgress] = useState(0)
  const [ready, setReady] = useState(false)
  const [logoTexture, setLogoTexture] = useState<Texture | null>(null)
  const audioRef = useRef<Map<string, Howl>>(new Map())
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    started.current = true

    const cat = { fonts: 0, audio: 0, textures: 0, webgl: 0 }

    function updateProgress() {
      const p = cat.fonts * W.fonts + cat.audio * W.audio + cat.textures * W.textures + cat.webgl * W.webgl
      setProgress(Math.min(p, 1))
    }

    // --- Fonts (20%) ---
    const fontPromise = Promise.allSettled(
      FONT_CHECKS.map((f) => document.fonts.load(f))
    ).then(() => {
      cat.fonts = 1
      updateProgress()
    })

    // --- Audio (50%) ---
    const audioKeys = Object.keys(PRIORITY_AUDIO)
    const perAudio = 1 / audioKeys.length
    const audioPromise = Promise.allSettled(
      audioKeys.map(
        (key) =>
          new Promise<void>((resolve) => {
            const howl = new Howl({
              src: [PRIORITY_AUDIO[key]],
              preload: true,
              volume: 0.3,
              onload: () => {
                audioRef.current.set(key, howl)
                cat.audio = Math.min(cat.audio + perAudio, 1)
                updateProgress()
                resolve()
              },
              onloaderror: () => {
                cat.audio = Math.min(cat.audio + perAudio, 1)
                updateProgress()
                resolve()
              },
            })
          })
      )
    )

    // --- Textures (10%) ---
    const texturePromise = new TextureLoader()
      .loadAsync('/textures/logo.png')
      .then((tex) => {
        setLogoTexture(tex)
        cat.textures = 1
        updateProgress()
      })
      .catch(() => {
        cat.textures = 1
        updateProgress()
      })

    // --- WebGL readiness (20%) ---
    // Mark as ready immediately — R3F handles its own context.
    // Don't create competing WebGL contexts (causes Context Lost).
    const webglPromise = new Promise<void>((resolve) => {
      cat.webgl = 1
      updateProgress()
      resolve()
    })

    // Wait for all, then ready
    Promise.allSettled([fontPromise, audioPromise, texturePromise, webglPromise]).then(() => {
      cat.fonts = 1
      cat.audio = 1
      cat.textures = 1
      cat.webgl = 1
      setProgress(1)
      // Debounce so progress bar visually reaches 100%
      setTimeout(() => setReady(true), 400)
    })
  }, [])

  return {
    progress,
    ready,
    logoTexture,
    preloadedAudio: audioRef.current,
  }
}
