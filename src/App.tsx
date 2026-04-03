import { useState, useCallback, useRef, useEffect, useMemo } from 'react'
import { FlutterEmbed, type FlutterEmbedHandle } from './components/FlutterEmbed'
import { S3_Gallery } from './components/sections/S3_Gallery'
import { SectionTransition } from './components/SectionTransition'
import { Preloader } from './components/preloader/Preloader'
import { useAssetLoader } from './hooks/useAssetLoader'
import { AudioProvider, useAudio } from './audio/AudioProvider'
import { preloadRadio, startRadioOnGalleryEnter, stopRadio, resetGalleryScroll } from './components/three/GalleryScene'

type Phase = 'flutter' | 'react' | 'contact'
type TransitionDirection = 'forward' | 'reverse'
type PreloaderPhase = 'loading' | 'revealing' | 'done'

function AppInner() {
  const [phase, setPhase] = useState<Phase>('flutter')
  const [transitioning, setTransitioning] = useState(false)
  const [transitionDirection, setTransitionDirection] = useState<TransitionDirection>('forward')
  const pendingPhase = useRef<Phase | null>(null)
  const flutterRef = useRef<FlutterEmbedHandle>(null)
  const audio = useAudio()

  // --- Unified loading state ---
  const [flutterProgress, setFlutterProgress] = useState(0)
  const [flutterReady, setFlutterReady] = useState(false)
  const { progress: reactProgress, ready: reactReady } = useAssetLoader()
  const [preloaderPhase, setPreloaderPhase] = useState<PreloaderPhase>('loading')

  // Flutter is 80% of perceived load, React assets are 20%
  const totalProgress = useMemo(() => {
    const fp = flutterReady ? 1 : flutterProgress
    const rp = reactReady ? 1 : reactProgress
    return Math.min(fp * 0.8 + rp * 0.2, 1)
  }, [flutterProgress, flutterReady, reactProgress, reactReady])

  // Preload radio stream during loading phase
  useEffect(() => { preloadRadio() }, [])

  // Trigger reveal when both are ready
  useEffect(() => {
    if (flutterReady && reactReady && preloaderPhase === 'loading') {
      setPreloaderPhase('revealing')
    }
  }, [flutterReady, reactReady, preloaderPhase])

  // Start radio when entering React, stop + reset scroll when leaving
  useEffect(() => {
    if (phase === 'react') {
      startRadioOnGalleryEnter()
    } else {
      stopRadio()
      resetGalleryScroll()
    }
  }, [phase])

  const handleFlutterLoadingProgress = useCallback((progress: number) => {
    setFlutterProgress(progress)
  }, [])

  const handleFlutterReady = useCallback(() => {
    setFlutterReady(true)
    setFlutterProgress(1)
  }, [])

  const handlePreloaderRevealComplete = useCallback(() => {
    setPreloaderPhase('done')
  }, [])

  const { setSection } = audio
  useEffect(() => {
    setSection(phase === 'react' ? 'gallery' : 'none')
  }, [phase, setSection])

  const transitionToPhase = useCallback((targetPhase: Phase) => {
    if (transitioning) return
    pendingPhase.current = targetPhase
    // Flutter→React = forward (left-to-right wipe), React→Flutter/contact = reverse (right-to-left)
    const dir: TransitionDirection = targetPhase === 'react' ? 'forward' : 'reverse'
    setTransitionDirection(dir)
    audio.playTransitionWhoosh(targetPhase === 'flutter' ? 'reverse' : 'forward')
    setTransitioning(true)
  }, [transitioning, audio])

  const handleMidpoint = useCallback(() => {
    if (!pendingPhase.current) return
    const p = pendingPhase.current; setPhase(p)
    if (p === 'react') { flutterRef.current?.hide() }
    else if (p === 'flutter') { flutterRef.current?.show(); flutterRef.current?.sendMessage({ type: 'goto-home' }) }
    else if (p === 'contact') { flutterRef.current?.show(); flutterRef.current?.sendMessage({ type: 'goto-contact' }) }
  }, [])

  const handleComplete = useCallback(() => { pendingPhase.current = null; setTransitioning(false) }, [])
  const handleFlutterHandoff = useCallback(() => { transitionToPhase('react') }, [transitionToPhase])
  const handleNavigateToContact = useCallback(() => { transitionToPhase('contact') }, [transitionToPhase])
  const handleNavigateBack = useCallback(() => { transitionToPhase('flutter') }, [transitionToPhase])

  return (
    <div style={{ width: '100vw', height: '100vh', background: '#C4B496', position: 'relative', overflow: 'hidden', userSelect: 'none' }}>
      <FlutterEmbed ref={flutterRef} src="/flutter/index.html" onReady={handleFlutterReady} onHandoff={handleFlutterHandoff} onLoadingProgress={handleFlutterLoadingProgress} />
      <div style={{ position: 'absolute', inset: 0, zIndex: 30, opacity: phase === 'react' ? 1 : 0, pointerEvents: phase === 'react' ? 'auto' : 'none' }}>
        <S3_Gallery onNavigateToContact={handleNavigateToContact} onNavigateBack={handleNavigateBack} />
      </div>
      <SectionTransition active={transitioning} onMidpoint={handleMidpoint} onComplete={handleComplete} duration={1.6} direction={transitionDirection} />
      <Preloader progress={totalProgress} phase={preloaderPhase} onRevealComplete={handlePreloaderRevealComplete} />
    </div>
  )
}

export default function App() {
  return <AudioProvider><AppInner /></AudioProvider>
}
