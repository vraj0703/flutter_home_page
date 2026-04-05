import { useRef, useEffect } from 'react'
import { gsap } from 'gsap'

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
      const half = duration / 2
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

      // 1. Wipe IN (Cascading layers)
      tl.to(layers, {
        xPercent: 0,
        duration: half,
        ease: 'power3.inOut',
        stagger: 0.12,
      })

      // 2. Fire Midpoint when screen is fully covered by the top layer
      tl.add(() => {
        onMidpointRef.current()
      }, `>-0.1`) // Fire slightly before the very end of the stagger to overlap with React rendering

      // 3. Short hold period for async processes (Flutter loading, React DOM settle)
      tl.to({}, { duration: 0.25 })

      // 4. Wipe OUT (Layers slide away in same direction)
      tl.to(layers, {
        xPercent: dir === 1 ? -100 : 100,
        duration: half * 0.9,
        ease: 'power3.inOut',
        stagger: 0.08,
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
        Layers sequence (z-index): 
        1. Base Accent (Gold)
        2. Neutral Shadow (Deep Grey)
        3. Primary Background (Color prop)
      */}
      <div 
        className="transition-layer" 
        style={{ position: 'absolute', inset: 0, background: '#C8A45C', zIndex: 1, willChange: 'transform' }} 
      />
      <div 
        className="transition-layer" 
        style={{ position: 'absolute', inset: 0, background: '#111114', zIndex: 2, willChange: 'transform' }} 
      />
      <div 
        className="transition-layer" 
        style={{ position: 'absolute', inset: 0, background: color, zIndex: 3, willChange: 'transform' }} 
      />
    </div>
  )
}
