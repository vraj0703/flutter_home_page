import { createContext, useContext, useRef, useState, useCallback, useEffect, type ReactNode } from 'react'
import { AudioEngine, type SectionName } from './AudioEngine'
import { setSharedAudioEngine } from './index'

interface AudioContextValue {
  engine: AudioEngine
  muted: boolean
  toggleMute: () => void
  setSection: (section: SectionName) => void
  // Convenience UI sound methods
  playHoverPing: () => void
  playShutterClick: () => void
  playScrollTick: () => void
  playTransitionWhoosh: (dir?: 'forward' | 'reverse') => void
  playKeyClack: () => void
  playBootSweep: () => void
  playButtonClick: () => void
}

const AudioCtx = createContext<AudioContextValue | null>(null)

export function AudioProvider({ children }: { children: ReactNode }) {
  const engineRef = useRef<AudioEngine | null>(null)
  const [muted, setMuted] = useState(false) // unmuted by default

  // Lazy init engine
  if (!engineRef.current) {
    engineRef.current = new AudioEngine()
    setSharedAudioEngine(engineRef.current)
  }
  const engine = engineRef.current

  // Initialize audio context on first user interaction
  useEffect(() => {
    const initOnInteraction = () => {
      engine.init()
      engine.setMuted(false) // unmuted by default
      window.removeEventListener('click', initOnInteraction)
      window.removeEventListener('keydown', initOnInteraction)
      window.removeEventListener('wheel', initOnInteraction)
      window.removeEventListener('touchstart', initOnInteraction)
    }

    // Try to init immediately — succeeds if user already interacted (e.g. via Flutter)
    // AudioContext creation is safe here (inside useEffect, not during render)
    engine.init()

    window.addEventListener('click', initOnInteraction, { once: false })
    window.addEventListener('keydown', initOnInteraction, { once: false })
    window.addEventListener('wheel', initOnInteraction, { once: false })
    window.addEventListener('touchstart', initOnInteraction, { once: false })

    return () => {
      window.removeEventListener('click', initOnInteraction)
      window.removeEventListener('keydown', initOnInteraction)
      window.removeEventListener('wheel', initOnInteraction)
      window.removeEventListener('touchstart', initOnInteraction)
      engine.dispose()
    }
  }, [engine])

  const toggleMute = useCallback(() => {
    engine.init() // ensure init
    const nowMuted = engine.toggleMute()
    setMuted(nowMuted)
  }, [engine])

  const setSection = useCallback((section: SectionName) => {
    engine.init()
    engine.setSection(section)
  }, [engine])

  // Stable sound method refs — no re-renders on call
  const playHoverPing = useCallback(() => engine.playHoverPing(), [engine])
  const playShutterClick = useCallback(() => engine.playShutterClick(), [engine])
  const playScrollTick = useCallback(() => engine.playScrollTick(), [engine])
  const playTransitionWhoosh = useCallback((dir: 'forward' | 'reverse' = 'forward') => engine.playTransitionWhoosh(dir), [engine])
  const playKeyClack = useCallback(() => engine.playKeyClack(), [engine])
  const playBootSweep = useCallback(() => engine.playBootSweep(), [engine])
  const playButtonClick = useCallback(() => engine.playButtonClick(), [engine])

  const value: AudioContextValue = {
    engine, muted, toggleMute, setSection,
    playHoverPing, playShutterClick, playScrollTick,
    playTransitionWhoosh, playKeyClack, playBootSweep, playButtonClick,
  }

  return <AudioCtx.Provider value={value}>{children}</AudioCtx.Provider>
}

/** Hook to access audio engine and methods */
export function useAudio(): AudioContextValue {
  const ctx = useContext(AudioCtx)
  if (!ctx) throw new Error('useAudio must be used within AudioProvider')
  return ctx
}
