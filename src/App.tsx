import { useState, useCallback, useRef, useEffect, useMemo } from 'react'
import { FlutterEmbed, type FlutterEmbedHandle } from './components/FlutterEmbed'
// FlutterHost is ready for iframe elimination — swap after Flutter rebuild
// import { FlutterHost, type FlutterEmbedHandle } from './components/FlutterHost'
import { S3_Gallery } from './components/sections/S3_Gallery'
import { SectionTransition } from './components/SectionTransition'
import { Preloader } from './components/preloader/Preloader'
import { ErrorBoundary } from './components/ErrorBoundary'
import { useAssetLoader } from './hooks/useAssetLoader'
import { AudioProvider, useAudio } from './audio/AudioProvider'
import { preloadRadio, startRadioOnGalleryEnter, stopRadio } from './audio/RadioEngine'
import { resetGalleryScroll, setGalleryFrameloopActive } from './components/three/gallery/galleryStore'
import { initAnalytics, trackLandingViewed, trackGalleryEntered, trackContactViewed } from './analytics/posthog'

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

  // Initialize analytics + preload radio during loading phase
  useEffect(() => { initAnalytics(); preloadRadio() }, [])

  // Trigger reveal when both are ready
  useEffect(() => {
    if (flutterReady && reactReady && preloaderPhase === 'loading') {
      setPreloaderPhase('revealing')
    }
  }, [flutterReady, reactReady, preloaderPhase])

  // Start radio + reset scroll when entering React, stop when leaving.
  // Analytics: only track phase transitions TRIGGERED by the user, not the
  // initial 'flutter' mount — that's tracked post-reveal in
  // handlePreloaderRevealComplete so the event fires when the user actually
  // sees something, not while still behind the preloader.
  const firstPhaseEffect = useRef(true)
  useEffect(() => {
    const isInitialMount = firstPhaseEffect.current
    firstPhaseEffect.current = false

    if (phase === 'react') {
      resetGalleryScroll()
      startRadioOnGalleryEnter()
      trackGalleryEntered()
    } else if (phase === 'flutter') {
      // Skip analytics on first mount — fired from reveal-complete instead.
      if (!isInitialMount) trackLandingViewed()
      stopRadio()
    } else if (phase === 'contact') {
      trackContactViewed()
      stopRadio()
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
    // Fire landing analytics now — the user is actually seeing the scene
    // for the first time. Previously this fired on initial mount while the
    // preloader was still up, inflating impression counts.
    trackLandingViewed()
  }, [])

  const { setSection } = audio
  useEffect(() => {
    setSection(phase === 'react' ? 'gallery' : 'none')
  }, [phase, setSection])

  const transitionToPhase = useCallback((targetPhase: Phase) => {
    if (transitioning) return
    pendingPhase.current = targetPhase

    // PRE-ROUTE: Awaken and navigate Flutter in the background
    // This gives it ~800ms to process the heavy layout before the overlay reveals it.
    // GPU contention fix: when leaving the gallery, pause R3F immediately so
    // Flutter's beach shader + reflection capture has the GPU to itself.
    if (targetPhase === 'contact') {
      setGalleryFrameloopActive(false)
      flutterRef.current?.sendMessage({ type: 'flutter-resume' })
      flutterRef.current?.sendMessage({ type: 'goto-contact' })
    } else if (targetPhase === 'flutter') {
      setGalleryFrameloopActive(false)
      flutterRef.current?.sendMessage({ type: 'flutter-resume' })
      flutterRef.current?.sendMessage({ type: 'goto-home' })
    } else if (targetPhase === 'react') {
      // Returning to the gallery — resume R3F rendering.
      setGalleryFrameloopActive(true)
    }

    // Flutter→React = forward (left-to-right wipe), React→Flutter/contact = reverse (right-to-left)
    const dir: TransitionDirection = targetPhase === 'react' ? 'forward' : 'reverse'
    setTransitionDirection(dir)
    audio.playTransitionWhoosh(targetPhase === 'flutter' ? 'reverse' : 'forward')
    setTransitioning(true)
  }, [transitioning, audio])

  const handleMidpoint = useCallback(() => {
    if (!pendingPhase.current) return
    const p = pendingPhase.current; 
    setPhase(p)
    
    if (p === 'react') { 
      flutterRef.current?.hide()
      flutterRef.current?.sendMessage({ type: 'flutter-pause' }) 
    }
    else if (p === 'flutter' || p === 'contact') { 
      flutterRef.current?.show()
      // Already resumed and routed at transition start
    }
  }, [])

  const handleComplete = useCallback(() => { pendingPhase.current = null; setTransitioning(false) }, [])
  const handleFlutterHandoff = useCallback(() => { transitionToPhase('react') }, [transitionToPhase])
  const handleNavigateToContact = useCallback(() => { transitionToPhase('contact') }, [transitionToPhase])
  const handleNavigateBack = useCallback(() => { transitionToPhase('flutter') }, [transitionToPhase])

  return (
    <div style={{ width: '100vw', height: '100vh', background: '#C4B496', position: 'relative', overflow: 'hidden', userSelect: 'none' }}>
      <FlutterEmbed ref={flutterRef} src="/flutter/index.html" onReady={handleFlutterReady} onHandoff={handleFlutterHandoff} onLoadingProgress={handleFlutterLoadingProgress} />
      {/* Gallery wrapper. Opacity + pointerEvents gate visibility/interaction.
          `display: none` was tried as a belt-and-suspenders paint-release, but
          it broke Canvas lifecycle: when the wrapper flipped back to `display:
          block` on return to gallery, the Canvas would show just its clearColor
          for a frame while R3F re-established size/WebGL state. R3F
          `frameloop="never"` (see GalleryScene) is the GPU defense — we don't
          need the display hack. */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          zIndex: 30,
          opacity: phase === 'react' ? 1 : 0,
          pointerEvents: phase === 'react' ? 'auto' : 'none',
        }}
      >
        {/* ErrorBoundary: an uncaught error in R3F (texture load, material,
            shader) would otherwise crash the entire app. Fallback is a
            static contact card so the user still has a path forward. */}
        <ErrorBoundary>
          <S3_Gallery onNavigateToContact={handleNavigateToContact} onNavigateBack={handleNavigateBack} />
        </ErrorBoundary>
      </div>
      <SectionTransition active={transitioning} onMidpoint={handleMidpoint} onComplete={handleComplete} duration={1.6} direction={transitionDirection} />
      <Preloader progress={totalProgress} phase={preloaderPhase} onRevealComplete={handlePreloaderRevealComplete} />
    </div>
  )
}

export default function App() {
  return <AudioProvider><AppInner /></AudioProvider>
}
