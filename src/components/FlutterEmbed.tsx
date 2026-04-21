import { useEffect, useRef, useImperativeHandle, forwardRef } from 'react'
import { gsap } from 'gsap'
import { MOTION } from '../config/motion'
import { flutterBridge } from '../bridge/flutterBridge'

/**
 * The handle callers get from the ref. Previously included `sendMessage`; that
 * moved to `flutterBridge` so there's a single message surface. Consumers
 * who need to send should import `flutterBridge` directly.
 */
export interface FlutterEmbedHandle {
  show: () => void
  hide: () => void
}

interface FlutterEmbedProps {
  src: string
  onReady?: () => void
  onHandoff?: () => void
  onLoadingProgress?: (progress: number) => void
}

export const FlutterEmbed = forwardRef<FlutterEmbedHandle, FlutterEmbedProps>(
  ({ src, onReady, onHandoff, onLoadingProgress }, ref) => {
    const iframeRef = useRef<HTMLIFrameElement>(null)

    useImperativeHandle(ref, () => ({
      show() {
        if (!iframeRef.current) return
        // Pure opacity fade — no y-slide (the flutter frame is already in place)
        gsap.fromTo(iframeRef.current,
          { opacity: 0 },
          { opacity: 1, duration: MOTION.flutter.showDuration, ease: MOTION.ease.enter, onStart: () => { iframeRef.current!.style.pointerEvents = 'auto' } }
        )
      },
      hide() {
        if (!iframeRef.current) return
        iframeRef.current.style.pointerEvents = 'none'
        gsap.to(iframeRef.current, { opacity: 0, duration: MOTION.flutter.hideDuration })
      },
    }))

    // Callback refs — the bridge subscription is registered once (empty-deps
    // effect) but should always call the latest prop callbacks. Sync via a
    // post-commit effect so we don't write refs during render.
    const onReadyRef = useRef(onReady)
    const onHandoffRef = useRef(onHandoff)
    const onLoadingProgressRef = useRef(onLoadingProgress)
    useEffect(() => {
      onReadyRef.current = onReady
      onHandoffRef.current = onHandoff
      onLoadingProgressRef.current = onLoadingProgress
    })

    // Wire to the singleton FlutterBridge. The bridge owns all inbound
    // message handling (origin-checked, type-switched, queue-drained).
    useEffect(() => {
      if (!iframeRef.current) return
      flutterBridge.attach(iframeRef.current)

      const unsubReady = flutterBridge.onReady(() => onReadyRef.current?.())
      const unsubHandoff = flutterBridge.onHandoff(() => onHandoffRef.current?.())
      const unsubLoading = flutterBridge.onLoading((p) => onLoadingProgressRef.current?.(p))

      return () => {
        unsubReady()
        unsubHandoff()
        unsubLoading()
      }
    }, [])

    return (
      <iframe
        ref={iframeRef}
        src={src}
        title="Portfolio Landing"
        style={{
          position: 'fixed',
          inset: 0,
          width: '100vw',
          height: '100vh',
          border: 'none',
          zIndex: 40,
          background: '#0a0a0a',
        }}
        allow="autoplay"
      />
    )
  }
)

FlutterEmbed.displayName = 'FlutterEmbed'
