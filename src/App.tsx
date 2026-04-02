import { useState, useCallback, useRef, useEffect, useMemo } from 'react'
import { FlutterEmbed, type FlutterEmbedHandle } from './components/FlutterEmbed'
import { S3_Gallery } from './components/sections/S3_Gallery'
import { SectionTransition } from './components/SectionTransition'
import { Preloader } from './components/preloader/Preloader'
import { useAssetLoader } from './hooks/useAssetLoader'
import { AudioProvider, useAudio } from './audio/AudioProvider'
import { AudioToggle } from './audio/AudioToggle'

type Phase = 'flutter' | 'react' | 'contact'
type TransitionDirection = 'forward' | 'reverse'
type PreloaderPhase = 'loading' | 'revealing' | 'done'

function getStatusText(progress: number): string {
  if (progress < 0.3) return 'Loading engine...'
  if (progress < 0.7) return 'Preparing gallery...'
  if (progress < 0.95) return 'Almost ready...'
  return 'Launching...'
}

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

  const statusText = useMemo(() => getStatusText(totalProgress), [totalProgress])

  // Trigger reveal when both are ready
  useEffect(() => {
    if (flutterReady && reactReady && preloaderPhase === 'loading') {
      setPreloaderPhase('revealing')
    }
  }, [flutterReady, reactReady, preloaderPhase])

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

  useEffect(() => {
    audio.setSection(phase === 'react' ? 'gallery' : 'none')
  }, [phase, audio])

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
    else if (p === 'contact') { flutterRef.current?.show(); flutterRef.current?.sendMessage({ type: 'goto-philosophy' }) }
  }, [])

  const handleComplete = useCallback(() => { pendingPhase.current = null; setTransitioning(false) }, [])
  const handleFlutterHandoff = useCallback(() => { transitionToPhase('react') }, [transitionToPhase])
  const handleNavigateToContact = useCallback(() => { transitionToPhase('contact') }, [transitionToPhase])

  return (
    <div style={{ width: '100vw', height: '100vh', background: '#C4B496', position: 'relative', overflow: 'hidden', userSelect: 'none' }}>
      <FlutterEmbed ref={flutterRef} src="/flutter/index.html" onReady={handleFlutterReady} onHandoff={handleFlutterHandoff} onLoadingProgress={handleFlutterLoadingProgress} />
      <div style={{ position: 'absolute', inset: 0, zIndex: 30, opacity: phase === 'react' ? 1 : 0, pointerEvents: phase === 'react' ? 'auto' : 'none' }}>
        <S3_Gallery onNavigateToContact={handleNavigateToContact} />
      </div>
      <SectionTransition active={transitioning} onMidpoint={handleMidpoint} onComplete={handleComplete} duration={1.6} direction={transitionDirection} />
      <AudioToggle />
      <Preloader progress={totalProgress} phase={preloaderPhase} onRevealComplete={handlePreloaderRevealComplete} statusText={statusText} />
    </div>
  )
}

export default function App() {
  return <AudioProvider><AppInner /></AudioProvider>
}
