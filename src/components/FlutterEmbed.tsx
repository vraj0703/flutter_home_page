import { useEffect, useRef, useImperativeHandle, forwardRef } from 'react'
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

// CSS transitions replace GSAP for the fade in/out. The two durations come
// from MOTION.flutter so the tuning surface is still shared with everything
// else (SectionTransition etc. still uses GSAP). The ease approximation:
// `power3.out` ≈ cubic-bezier(0.33, 1, 0.68, 1), which is the canonical
// "ease-out-cubic" and visually matches the previous GSAP tween within a
// frame or two.
const SHOW_TRANSITION = `opacity ${MOTION.flutter.showDuration}s cubic-bezier(0.33, 1, 0.68, 1)`
const HIDE_TRANSITION = `opacity ${MOTION.flutter.hideDuration}s ease-in`

export const FlutterEmbed = forwardRef<FlutterEmbedHandle, FlutterEmbedProps>(
  ({ src, onReady, onHandoff, onLoadingProgress }, ref) => {
    const iframeRef = useRef<HTMLIFrameElement>(null)

    useImperativeHandle(ref, () => ({
      show() {
        const el = iframeRef.current
        if (!el) return
        el.style.transition = SHOW_TRANSITION
        el.style.opacity = '0'
        // Force a reflow so the 0 opacity takes effect as a starting state
        // before the transition kicks in. Without this, assigning '0' then
        // '1' in the same synchronous block coalesces to just '1' with no
        // animation.
        void el.offsetHeight
        el.style.opacity = '1'
        el.style.pointerEvents = 'auto'
      },
      hide() {
        const el = iframeRef.current
        if (!el) return
        el.style.transition = HIDE_TRANSITION
        el.style.pointerEvents = 'none'
        el.style.opacity = '0'
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
