import { useRef, useEffect, useState } from 'react'
import { gsap } from 'gsap'

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
  const hasRevealed = useRef(false)
  const [displayPct, setDisplayPct] = useState(1)

  // Smooth percentage counter — starts at 01, counts to 100
  useEffect(() => {
    const target = Math.max(1, Math.round(progress * 100))
    if (target <= displayPct) return
    const step = () => {
      setDisplayPct(prev => {
        if (prev >= target) return target
        return prev + 1
      })
    }
    const id = setInterval(step, 20)
    return () => clearInterval(id)
  }, [progress, displayPct])

  // Zero-padded: 01–99, then 100
  const pctText = displayPct < 100 ? String(displayPct).padStart(2, '0') : '100'

  // Energy buildup — glow intensifies with progress
  const p = progress
  const glowOpacity = p * p * 0.7          // quadratic ramp: subtle early, intense late
  const glowScale = 1 + p * 0.6            // grows from 1.0 → 1.6
  const glowBlur = 40 + p * 80             // blur: 40px → 120px
  const logoDropShadow = `drop-shadow(0 0 ${Math.round(p * 30)}px rgba(200, 164, 92, ${p * 0.8}))`

  // Morph reveal animation
  useEffect(() => {
    if (phase !== 'revealing' || hasRevealed.current) return
    hasRevealed.current = true

    const tl = gsap.timeline()

    // 1. Flash burst at 100% — the energy peaks
    tl.to(flashRef.current, {
      opacity: 0.9,
      duration: 0.15,
      ease: 'power4.in',
    })

    // 2. Flash fades + logo scales up — energy releases
    tl.to(flashRef.current, {
      opacity: 0,
      duration: 0.5,
      ease: 'power2.out',
    })

    // Simultaneously: text fades
    tl.to(textRef.current, {
      opacity: 0,
      y: -8,
      duration: 0.3,
      ease: 'power2.in',
    }, '<')

    // Logo scales up and dissolves into the scene
    tl.to(logoRef.current, {
      scale: 1.15,
      filter: 'invert(1) blur(6px)',
      opacity: 0,
      duration: 0.8,
      ease: 'power2.out',
    }, '<+=0.1')

    // Glow expands and dissolves
    tl.to(glowRef.current, {
      scale: 3,
      opacity: 0,
      duration: 0.8,
      ease: 'power2.out',
    }, '<')

    // Container fades — Flutter scene bleeds through
    tl.to(containerRef.current, {
      opacity: 0,
      duration: 0.5,
      ease: 'power1.inOut',
    }, '-=0.3')

    tl.call(() => onRevealComplete())
  }, [phase, onRevealComplete])

  if (phase === 'done') return null

  return (
    <div
      ref={containerRef}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 50,
        background: '#0A0A0C',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        pointerEvents: phase === 'revealing' ? 'none' : 'auto',
      }}
    >
      {/* Full-screen flash overlay */}
      <div
        ref={flashRef}
        style={{
          position: 'absolute',
          inset: 0,
          background: 'radial-gradient(circle at center, rgba(200, 164, 92, 0.6), rgba(255, 255, 255, 0.9))',
          opacity: 0,
          pointerEvents: 'none',
          zIndex: 2,
        }}
      />

      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        position: 'relative',
        zIndex: 1,
      }}>
        {/* Aura glow — intensifies with progress */}
        <div
          ref={glowRef}
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: `translate(-50%, -55%) scale(${glowScale})`,
            width: 'min(22vw, 340px)',
            height: 'min(22vw, 340px)',
            borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(200, 164, 92, 0.5) 0%, rgba(200, 164, 92, 0.1) 50%, transparent 70%)',
            filter: `blur(${glowBlur}px)`,
            opacity: glowOpacity,
            pointerEvents: 'none',
            willChange: 'transform, opacity, filter',
            transition: 'opacity 0.3s ease, transform 0.3s ease, filter 0.3s ease',
          }}
        />

        {/* Logo — with progressive drop-shadow glow */}
        <img
          ref={logoRef}
          src="/images/logo.png"
          alt="V"
          style={{
            width: 'min(22vw, 340px)',
            height: 'auto',
            aspectRatio: '175 / 150',
            objectFit: 'contain',
            filter: `invert(1) ${logoDropShadow}`,
            opacity: 0.95,
            userSelect: 'none',
            pointerEvents: 'none',
            willChange: 'transform, filter, opacity',
            transition: 'filter 0.3s ease',
          }}
          draggable={false}
        />

        {/* "loading...  XX %" */}
        <div
          ref={textRef}
          style={{
            width: 'min(22vw, 340px)',
            marginTop: '20px',
            textAlign: 'right',
            willChange: 'opacity, transform',
          }}
        >
          <span
            style={{
              fontFamily: 'Broadway, serif',
              fontSize: '14px',
              letterSpacing: '2px',
              color: `rgba(255, 255, 255, ${0.35 + p * 0.35})`,
              transition: 'color 0.3s ease',
            }}
          >
            L O A D I N G...{'  '}{pctText} %
          </span>
        </div>
      </div>

      <style>{`
        @font-face {
          font-family: 'Broadway';
          src: url('/fonts/broadway.ttf') format('truetype');
          font-weight: normal;
          font-style: normal;
          font-display: swap;
        }
      `}</style>
    </div>
  )
}
