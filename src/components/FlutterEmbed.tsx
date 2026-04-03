import { useEffect, useRef, useImperativeHandle, forwardRef } from 'react'
import { gsap } from 'gsap'

export interface FlutterEmbedHandle {
  show: () => void
  hide: () => void
  sendMessage: (msg: Record<string, string>) => void
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
    const handoffTriggered = useRef(false)

    useImperativeHandle(ref, () => ({
      show() {
        if (!iframeRef.current) return
        handoffTriggered.current = false
        gsap.fromTo(iframeRef.current,
          { opacity: 0, y: 30 },
          { opacity: 1, y: 0, duration: 0.6, ease: 'power2.out', onStart: () => { iframeRef.current!.style.pointerEvents = 'auto' } }
        )
      },
      hide() {
        if (!iframeRef.current) return
        gsap.to(iframeRef.current, { opacity: 0, duration: 0.3, onComplete: () => { iframeRef.current!.style.pointerEvents = 'none' } })
      },
      sendMessage(msg: Record<string, string>) {
        iframeRef.current?.contentWindow?.postMessage(msg, '*')
        if (msg.type === 'goto-philosophy' && iframeRef.current?.contentWindow) {
          iframeRef.current.contentWindow.scrollTo(0, 0)
        }
      },
    }))

    // Use refs for callbacks to avoid re-registering the listener on every prop change
    const onReadyRef = useRef(onReady)
    const onHandoffRef = useRef(onHandoff)
    const onLoadingProgressRef = useRef(onLoadingProgress)
    onReadyRef.current = onReady
    onHandoffRef.current = onHandoff
    onLoadingProgressRef.current = onLoadingProgress

    useEffect(() => {
      function handleMessage(event: MessageEvent) {
        const data = event.data
        if (!data || typeof data !== 'object') return

        // Only handle known flutter-* message types to filter out noise
        const type = data.type || data['type']
        if (!type || typeof type !== 'string' || !type.startsWith('flutter-')) return

        if (type === 'flutter-loading' && typeof data.progress === 'number') {
          const clamped = Math.max(0, Math.min(1, data.progress))
          onLoadingProgressRef.current?.(clamped)
        }

        if (type === 'flutter-ready') {
          onReadyRef.current?.()
        }

        if (type === 'flutter-handoff' && !handoffTriggered.current) {
          handoffTriggered.current = true
          onHandoffRef.current?.()
        }
      }

      window.addEventListener('message', handleMessage)
      return () => window.removeEventListener('message', handleMessage)
    }, []) // stable — reads refs

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
