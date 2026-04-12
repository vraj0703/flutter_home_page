import { useRef, useEffect } from 'react'
import { gsap } from 'gsap'
import { MOTION } from '../config/motion'

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
 * GSAP-based transition overlay with high-end multi-layer masking.
 * No text, just a slick cinematic geometric wipe.
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
  onMidpointRef.current = onMidpoint
  onCompleteRef.current = onComplete

  useEffect(() => {
    const el = overlayRef.current
    if (!el) return

    const layers = el.querySelectorAll('.transition-layer')
    
    gsap.killTweensOf(el)
    gsap.killTweensOf(layers)

    if (active) {
      const t = MOTION.transition
      const dir = direction === 'forward' ? 1 : -1

      // Enable container
      gsap.set(el, { pointerEvents: 'auto', display: 'block' })

      // Move layers off-screen
      gsap.set(layers, {
        xPercent: dir === 1 ? 100 : -100,
      })

      const tl = gsap.timeline({
        onComplete: () => {
          gsap.set(el, { pointerEvents: 'none', display: 'none' })
          onCompleteRef.current()
        }
      })

      // 1. Wipe IN (Cascading layers — gold is z:3, last to cover = first face you see)
      tl.to(layers, {
        xPercent: 0,
        duration: t.wipeIn,
        ease: MOTION.ease.inOut,
        stagger: t.wipeStagger,
      })

      // 2. Fire Midpoint EARLY for React settle time (at ~T+0.5s, not T+0.8s)
      tl.add(() => {
        onMidpointRef.current()
      }, t.midpoint)

      // 3. Short hold period for async processes (Flutter loading, React DOM settle)
      tl.to({}, { duration: t.hold })

      // 4. Wipe OUT (Layers slide away — tighter stagger for immediate reveal feel)
      tl.to(layers, {
        xPercent: dir === 1 ? -100 : 100,
        duration: t.wipeOut,
        ease: MOTION.ease.inOut,
        stagger: t.exitStagger,
      })

    } else {
      // Force hidden instantly
      gsap.set(el, { pointerEvents: 'none', display: 'none' })
    }

    return () => {
      gsap.killTweensOf(el)
      gsap.killTweensOf(layers)
    }
  }, [active, duration, direction])

  return (
    <div
      ref={overlayRef}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        pointerEvents: 'none',
        display: 'none',
      }}
    >
      {/*
        Layers sequence (z-index) — INVERTED from original:
        1. Primary Background (enters first = deepest)
        2. Neutral Shadow (middle depth)
        3. Base Accent Gold (enters last = threshold face, first to peel back on reveal)
      */}
      <div
        className="transition-layer"
        style={{ position: 'absolute', inset: 0, background: color, zIndex: 1, willChange: 'transform' }}
      />
      <div
        className="transition-layer"
        style={{ position: 'absolute', inset: 0, background: '#111114', zIndex: 2, willChange: 'transform' }}
      />
      <div
        className="transition-layer"
        style={{ position: 'absolute', inset: 0, background: '#C8A45C', zIndex: 3, willChange: 'transform' }}
      />
    </div>
  )
}
