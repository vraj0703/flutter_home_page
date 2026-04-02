import { useCallback, useRef } from 'react'
import { Howl } from 'howler'
import { AUDIO, type AudioId } from '../config/audio-map'

const sounds: Partial<Record<AudioId, Howl>> = {}
let initialized = false

// Accept preloaded sounds from the asset loader to avoid double-loading
let preloadedMap: Map<string, Howl> | null = null

export function setPreloadedAudio(map: Map<string, Howl>) {
  preloadedMap = map
}

function initSounds() {
  if (initialized) return
  initialized = true

  for (const [key, src] of Object.entries(AUDIO)) {
    const id = key as AudioId
    // Use preloaded instance if available
    if (preloadedMap?.has(key)) {
      sounds[id] = preloadedMap.get(key)!
    } else {
      sounds[id] = new Howl({ src: [src], preload: true, volume: 0.3 })
    }
  }
}

export function useAudioEngine() {
  const enabledRef = useRef(false)

  const enable = useCallback(() => {
    if (!enabledRef.current) {
      enabledRef.current = true
      initSounds()
    }
  }, [])

  const play = useCallback((id: AudioId) => {
    if (!enabledRef.current) return
    sounds[id]?.play()
  }, [])

  const setVolume = useCallback((id: AudioId, vol: number) => {
    sounds[id]?.volume(vol)
  }, [])

  const loop = useCallback((id: AudioId, on: boolean) => {
    sounds[id]?.loop(on)
  }, [])

  const stop = useCallback((id: AudioId) => {
    sounds[id]?.stop()
  }, [])

  return { enable, play, setVolume, loop, stop, isEnabled: () => enabledRef.current }
}
