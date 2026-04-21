import { useState, useEffect, useRef } from 'react'
import { Howl } from 'howler'
import { TextureLoader, type Texture } from 'three'

/**
 * Essential audio — blocks the preloader's `ready` flag. Keep this list tiny:
 * only sounds that would be noticeably absent if the user hits the gallery
 * before they finish loading.
 */
const ESSENTIAL_AUDIO: Record<string, string> = {
  titleLoaded: '/audio/title_loaded.mp3',
  whoosh: '/audio/whoosh.mp3',
}

/**
 * Deferred audio — loads in the background. If these aren't ready by first
 * use, the corresponding SFX is silent (acceptable). Kept out of the progress
 * calculation entirely to avoid gating reveal on a slow connection.
 */
const DEFERRED_AUDIO: Record<string, string> = {
  harpEnter: '/audio/harp_enter.mp3',
  boldText: '/audio/bold_text.mp3',
  enterSound: '/audio/enter_sound.mp3',
}

const FONT_CHECKS = [
  '400 1em ModrntUrban',
  '400 1em InconsolataNerd',
  '400 1em Poseidon',
]

// Weights sum to 1.0. The old WebGL bucket (20%) was removed — it resolved
// synchronously and was never a real gate. Redistributed: fonts 30%,
// essential audio 50%, textures 20%.
const W = { fonts: 0.3, audio: 0.5, textures: 0.2 }

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
  // Stable Map — `useState` lazy-initializer creates it exactly once. Avoids
  // the react-hooks/refs lint rule triggered by `audioRef.current` reads
  // during render. The Map is mutated by the async Howl onload callbacks;
  // consumers see the same Map instance across renders.
  const [audioMap] = useState<Map<string, Howl>>(() => new Map())
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    started.current = true

    const cat = { fonts: 0, audio: 0, textures: 0 }

    function updateProgress() {
      const p = cat.fonts * W.fonts + cat.audio * W.audio + cat.textures * W.textures
      setProgress(Math.min(p, 1))
    }

    // --- Fonts (30%) ---
    const fontPromise = Promise.allSettled(
      FONT_CHECKS.map((f) => document.fonts.load(f))
    ).then(() => {
      cat.fonts = 1
      updateProgress()
    })

    // --- Essential audio (50%) — gates ready ---
    const essentialKeys = Object.keys(ESSENTIAL_AUDIO)
    const perAudio = 1 / essentialKeys.length
    const audioPromise = Promise.allSettled(
      essentialKeys.map(
        (key) =>
          new Promise<void>((resolve) => {
            const howl = new Howl({
              src: [ESSENTIAL_AUDIO[key]],
              preload: true,
              volume: 0.3,
              onload: () => {
                audioMap.set(key, howl)
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

    // --- Deferred audio — fire-and-forget, does NOT gate ready ---
    // Kicked off in parallel so these files are (likely) cached by the time
    // the user triggers the first section transition.
    Object.keys(DEFERRED_AUDIO).forEach((key) => {
      const howl = new Howl({
        src: [DEFERRED_AUDIO[key]],
        preload: true,
        volume: 0.3,
        onload: () => { audioMap.set(key, howl) },
      })
    })

    // --- Textures (20%) ---
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

    // Wait for all essential buckets, then ready. No artificial delay — if
    // the bar is at 100% we don't pad it before the reveal.
    Promise.allSettled([fontPromise, audioPromise, texturePromise]).then(() => {
      cat.fonts = 1
      cat.audio = 1
      cat.textures = 1
      setProgress(1)
      setReady(true)
    })
    // `audioMap` is from useState's lazy init — identity is stable for the
    // component's lifetime, so including it here is cosmetic (satisfies
    // exhaustive-deps). The effect body still runs exactly once via the
    // `started` ref guard at the top.
  }, [audioMap])

  return {
    progress,
    ready,
    logoTexture,
    preloadedAudio: audioMap,
  }
}
