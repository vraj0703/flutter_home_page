import { useRef, useEffect } from 'react'

type TransitionDirection = 'forward' | 'reverse'

interface Props {
  active: boolean
  onMidpoint: () => void
  onComplete: () => void
  color?: string
  duration?: number
  /** forward = left-to-right wipe, reverse = right-to-left wipe */
  direction?: TransitionDirection
}

/**
 * CSS-based transition overlay with directional wipe + blur.
 *
 * - Forward (Flutter→React): wipes left-to-right with slight translateX slide
 * - Reverse (React→Flutter): wipes right-to-left
 * - At midpoint: 200ms blur pulse before fade-out for smoother handoff
 */
export function SectionTransition({
  active,
  onMidpoint,
  onComplete,
  color = '#0A0A0C',
  duration = 1.6,
  direction = 'forward',
}: Props) {
  const overlayRef = useRef<HTMLDivElement>(null)
  const onMidpointRef = useRef(onMidpoint)
  const onCompleteRef = useRef(onComplete)
  const colorRef = useRef(color)
  const directionRef = useRef(direction)
  const timerRef = useRef<number>(0)
  const timersRef = useRef<number[]>([])
  onMidpointRef.current = onMidpoint
  onCompleteRef.current = onComplete
  colorRef.current = color
  directionRef.current = direction

  const clearAllTimers = () => {
    clearTimeout(timerRef.current)
    timersRef.current.forEach(t => clearTimeout(t))
    timersRef.current = []
  }

  const scheduleTimer = (fn: () => void, ms: number): number => {
    const id = window.setTimeout(fn, ms)
    timersRef.current.push(id)
    return id
  }

  useEffect(() => {
    const el = overlayRef.current
    if (!el) return

    clearAllTimers()

    if (active) {
      const half = (duration / 2) * 1000
      const dir = directionRef.current
      // Wipe direction: forward slides overlay from right, reverse from left
      const translateStart = dir === 'forward' ? 'translateX(5%)' : 'translateX(-5%)'
      const translateMid = 'translateX(0%)'
      const translateEnd = dir === 'forward' ? 'translateX(-5%)' : 'translateX(5%)'

      // Reset state for fade IN
      el.style.background = colorRef.current
      el.style.opacity = '0'
      el.style.transform = translateStart
      el.style.filter = 'blur(0px)'
      el.style.transition = `opacity ${half}ms ease-in-out, transform ${half}ms ease-in-out, filter 200ms ease`
      el.style.pointerEvents = 'auto'

      // Force reflow
      void el.offsetHeight

      // Fade IN + slide to center
      el.style.opacity = '1'
      el.style.transform = translateMid

      // At peak: fire midpoint, apply blur pulse, then fade OUT
      timerRef.current = scheduleTimer(() => {
        onMidpointRef.current()

        // Brief blur pulse at midpoint for smoother handoff feel
        el.style.filter = 'blur(6px)'

        // Hold for mount + blur, then begin fade out
        scheduleTimer(() => {
          // Remove blur before fading out
          el.style.filter = 'blur(0px)'

          scheduleTimer(() => {
            el.style.transition = `opacity ${half}ms ease-in-out, transform ${half}ms ease-in-out, filter 200ms ease`
            el.style.opacity = '0'
            el.style.transform = translateEnd

            // Complete after fade out
            scheduleTimer(() => {
              el.style.pointerEvents = 'none'
              el.style.transform = 'translateX(0%)'
              onCompleteRef.current()
            }, half + 50)
          }, 200) // blur hold duration
        }, 150) // mount hold
      }, half + 50)
    } else {
      // Force hidden
      el.style.opacity = '0'
      el.style.pointerEvents = 'none'
      el.style.transition = 'none'
      el.style.transform = 'translateX(0%)'
      el.style.filter = 'blur(0px)'
    }

    return () => clearAllTimers()
  }, [active, duration])

  return (
    <div
      ref={overlayRef}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        opacity: 0,
        pointerEvents: 'none',
        willChange: 'opacity, transform, filter',
      }}
    />
  )
}
