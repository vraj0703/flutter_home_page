import { useRef, useEffect } from 'react'
import { gsap } from 'gsap'
import { useReducedMotion } from '../../hooks/useReducedMotion'

interface PreloaderProps {
  progress: number
  phase: 'loading' | 'revealing' | 'done'
  onRevealComplete: () => void
}

export function Preloader({ progress, phase, onRevealComplete }: PreloaderProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const logoRef = useRef<HTMLImageElement>(null)
  const glowRef = useRef<HTMLDivElement>(null)
  const flashRef = useRef<HTMLDivElement>(null)
  const textRef = useRef<HTMLDivElement>(null)
  const textSpanRef = useRef<HTMLSpanElement>(null)
  const hasRevealed = useRef(false)
  const displayPctRef = useRef({ value: 1 })
  const reducedMotion = useReducedMotion()

  // Animate the progress and manually push to DOM refs to avoid React re-renders
  useEffect(() => {
    const target = Math.max(1, Math.round(progress * 100))
    
    gsap.to(displayPctRef.current, {
      value: target,
      duration: 0.3,
      ease: 'power2.out',
      onUpdate: () => {
        const val = Math.round(displayPctRef.current.value)
        const pctText = val < 100 ? String(val).padStart(2, '0') : '100'
        const p = val / 100

        if (textSpanRef.current) {
          textSpanRef.current.innerText = `L O A D I N G...  ${pctText} %`
          textSpanRef.current.style.color = `rgba(255, 255, 255, ${0.35 + p * 0.35})`
        }

        if (glowRef.current) {
          const glowOpacity = p * p * 0.7
          const glowScale = 1 + p * 0.6
          const glowBlur = 40 + p * 80
          glowRef.current.style.opacity = `${glowOpacity}`
          glowRef.current.style.transform = `translate(-50%, -55%) scale(${glowScale})`
          glowRef.current.style.filter = `blur(${glowBlur}px)`
        }

        if (logoRef.current) {
          const logoDropShadow = `drop-shadow(0 0 ${Math.round(p * 30)}px rgba(200, 164, 92, ${p * 0.8}))`
          logoRef.current.style.filter = `invert(1) ${logoDropShadow}`
        }
      }
    })
  }, [progress])

  // Morph reveal animation
  useEffect(() => {
    if (phase !== 'revealing' || hasRevealed.current) return
    hasRevealed.current = true

    const tl = gsap.timeline()

    if (reducedMotion) {
      // Accessibility: skip flash burst, simple crossfade out
      tl.to(containerRef.current, { opacity: 0, duration: 0.3, ease: 'power1.inOut' })
      tl.call(() => onRevealComplete())
      return
    }

    // 1. Radial bloom
    tl.to(flashRef.current, { opacity: 0.4, duration: 0.15, ease: 'power4.in' })

    // 2. Flash fades
    tl.to(flashRef.current, { opacity: 0, duration: 0.5, ease: 'power2.out' })

    // Simultaneously: text fades
    tl.to(textRef.current, { opacity: 0, y: -8, duration: 0.3, ease: 'power2.in' }, '<')

    // Logo scales up and dissolves into the scene
    tl.to(logoRef.current, { scale: 1.15, filter: 'invert(1) blur(6px)', opacity: 0, duration: 0.8, ease: 'power2.out' }, '<+=0.1')

    // Glow expands and dissolves
    tl.to(glowRef.current, { scale: 4, opacity: 0, duration: 0.8, ease: 'power2.out' }, '<')

    // Container fades
    tl.to(containerRef.current, { opacity: 0, duration: 0.5, ease: 'power1.inOut' }, '-=0.3')

    tl.call(() => onRevealComplete())
  }, [phase, onRevealComplete, reducedMotion])

  if (phase === 'done') return null

  // Layer-promotion hint. Applied only during the reveal animation — during
  // loading, the GSAP progress tween is light enough that keeping the three
  // elements permanently on the compositor wastes memory on low-end phones.
  // The @font-face declaration for Broadway lives in src/index.css; it used
  // to be duplicated here as an inline <style>, which meant any page that
  // didn't mount the Preloader was missing Broadway.
  const animatableClass = phase === 'revealing' ? 'preloader-animatable' : ''

  return (
    <div
      ref={containerRef}
      style={{
        position: 'fixed', inset: 0, zIndex: 50, background: '#0A0A0C',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        pointerEvents: phase === 'revealing' ? 'none' : 'auto',
      }}
    >
      {/* Full-screen flash overlay */}
      <div
        ref={flashRef}
        style={{
          position: 'absolute', inset: 0, background: 'radial-gradient(circle at center, rgba(200, 164, 92, 0.6), rgba(255, 255, 255, 0.9))',
          opacity: 0, pointerEvents: 'none', zIndex: 2,
        }}
      />

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative', zIndex: 1 }}>
        {/* Aura glow */}
        <div
          ref={glowRef}
          className={animatableClass}
          style={{
            position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -55%) scale(1)',
            width: 'min(22vw, 340px)', height: 'min(22vw, 340px)', borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(200, 164, 92, 0.5) 0%, rgba(200, 164, 92, 0.1) 50%, transparent 70%)',
            filter: 'blur(40px)', opacity: 0, pointerEvents: 'none',
          }}
        />

        {/* Logo */}
        <img
          ref={logoRef}
          className={animatableClass}
          src="/images/logo.png"
          alt="V"
          style={{
            width: 'min(22vw, 340px)', height: 'auto', aspectRatio: '175 / 150', objectFit: 'contain',
            filter: 'invert(1) drop-shadow(0 0 0px rgba(200, 164, 92, 0))', opacity: 0.95,
            userSelect: 'none', pointerEvents: 'none',
          }}
          draggable={false}
        />

        {/* Loading text */}
        <div ref={textRef} className={animatableClass} style={{ width: 'min(22vw, 340px)', marginTop: '20px', textAlign: 'right' }}>
          <span
            ref={textSpanRef}
            style={{ fontFamily: 'Broadway, serif', fontSize: '14px', letterSpacing: '2px', color: 'rgba(255, 255, 255, 0.35)' }}
          >
            L O A D I N G...  01 %
          </span>
        </div>
      </div>
    </div>
  )
}
