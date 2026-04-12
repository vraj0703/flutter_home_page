/**
 * FlutterHost — Renders Flutter directly into a React-managed div.
 *
 * Replaces FlutterEmbed (iframe-based) with Flutter's hostElement API.
 * Flutter renders into a <div> in the same browsing context as React.
 *
 * Benefits over iframe:
 * - Single service worker scope
 * - No postMessage serialization overhead
 * - Shared font loading (React loads fonts, Flutter inherits)
 * - No cross-origin focus traps
 * - Same-origin JS interop (no postMessage needed)
 */
import { useEffect, useRef, useImperativeHandle, forwardRef, useCallback } from 'react'
import { gsap } from 'gsap'
import { MOTION } from '../config/motion'

export interface FlutterHostHandle {
  show: () => void
  hide: () => void
  sendMessage: (msg: Record<string, string>) => void
}

interface FlutterHostProps {
  onReady?: () => void
  onHandoff?: () => void
  onLoadingProgress?: (progress: number) => void
}

// Declare Flutter global types
declare global {
  interface Window {
    _flutter?: {
      loader: {
        load: (config: {
          serviceWorkerSettings?: { serviceWorkerVersion: string | null } | null
          onEntrypointLoaded: (engineInitializer: {
            initializeEngine: (config: {
              hostElement?: HTMLElement
              assetBase?: string
              renderer?: string
            }) => Promise<{ runApp: () => Promise<void> }>
          }) => Promise<void>
        }) => Promise<void>
      }
    }
    _flutterToReact: {
      onLoading: (progress: number) => void
      onReady: () => void
      onHandoff: () => void
      onError: (msg: string) => void
    }
    _registerFlutterCallback: (type: string, payload: string) => void
  }
}

export const FlutterHost = forwardRef<FlutterHostHandle, FlutterHostProps>(
  ({ onReady, onHandoff, onLoadingProgress }, ref) => {
    const hostRef = useRef<HTMLDivElement>(null)
    const handoffTriggered = useRef(false)
    const flutterLoaded = useRef(false)

    // Use refs for callbacks to avoid re-registering
    const onReadyRef = useRef(onReady)
    const onHandoffRef = useRef(onHandoff)
    const onLoadingProgressRef = useRef(onLoadingProgress)
    onReadyRef.current = onReady
    onHandoffRef.current = onHandoff
    onLoadingProgressRef.current = onLoadingProgress

    useImperativeHandle(ref, () => ({
      show() {
        if (!hostRef.current) return
        handoffTriggered.current = false
        gsap.fromTo(hostRef.current,
          { opacity: 0 },
          { opacity: 1, duration: MOTION.flutter.showDuration, ease: MOTION.ease.enter,
            onStart: () => { hostRef.current!.style.pointerEvents = 'auto' } }
        )
      },
      hide() {
        if (!hostRef.current) return
        hostRef.current.style.pointerEvents = 'none'
        gsap.to(hostRef.current, { opacity: 0, duration: MOTION.flutter.hideDuration })
      },
      sendMessage(msg: Record<string, string>) {
        // Direct JS interop — call into Dart's registered callback
        try {
          if (typeof window._registerFlutterCallback === 'function') {
            window._registerFlutterCallback(msg.type, JSON.stringify(msg))
          }
        } catch (e) {
          console.warn('[FlutterHost] sendMessage failed:', e)
        }
      },
    }))

    // Wire up the Flutter → React bridge callbacks
    const setupBridge = useCallback(() => {
      window._flutterToReact = {
        onLoading: (progress: number) => {
          const clamped = Math.max(0, Math.min(1, progress))
          onLoadingProgressRef.current?.(clamped)
        },
        onReady: () => {
          onReadyRef.current?.()
        },
        onHandoff: () => {
          if (!handoffTriggered.current) {
            handoffTriggered.current = true
            onHandoffRef.current?.()
          }
        },
        onError: (msg: string) => {
          console.error('[FlutterHost] Flutter error:', msg)
        },
      }
    }, [])

    // Initialize Flutter into the host div
    useEffect(() => {
      if (flutterLoaded.current || !hostRef.current) return
      flutterLoaded.current = true

      setupBridge()

      // Also listen for legacy postMessage events (backward compatibility
      // during transition — Dart code may still send postMessage before
      // CanvasLifecyclePort is switched to useDirectInterop=true)
      const handleLegacyMessage = (event: MessageEvent) => {
        const data = event.data
        if (!data || typeof data !== 'object') return
        const type = data.type as string
        if (!type || typeof type !== 'string' || !type.startsWith('flutter-')) return

        if (type === 'flutter-loading' && typeof data.progress === 'number') {
          onLoadingProgressRef.current?.(Math.max(0, Math.min(1, data.progress)))
        }
        if (type === 'flutter-ready') {
          onReadyRef.current?.()
        }
        if (type === 'flutter-handoff' && !handoffTriggered.current) {
          handoffTriggered.current = true
          onHandoffRef.current?.()
        }
      }
      window.addEventListener('message', handleLegacyMessage)

      // Wait for flutter.js to load (deferred script)
      const tryLoad = () => {
        if (!window._flutter?.loader) {
          setTimeout(tryLoad, 50)
          return
        }

        // buildConfig is set in index.html <script> block before flutter.js loads
        window._flutter.loader.load({
          serviceWorkerSettings: null,
          onEntrypointLoaded: async (engineInitializer) => {
            const appRunner = await engineInitializer.initializeEngine({
              hostElement: hostRef.current!,
              assetBase: '/flutter/',
              renderer: 'canvaskit',
            })
            await appRunner.runApp()
          },
        }).catch((err: unknown) => {
          console.error('[FlutterHost] Flutter load failed:', err)
        })
      }

      tryLoad()

      return () => {
        window.removeEventListener('message', handleLegacyMessage)
      }
    }, [setupBridge])

    return (
      <div
        ref={hostRef}
        id="flutter-host"
        style={{
          position: 'fixed',
          inset: 0,
          width: '100vw',
          height: '100vh',
          border: 'none',
          zIndex: 40,
          background: '#0a0a0a',
        }}
      />
    )
  }
)

FlutterHost.displayName = 'FlutterHost'
