import { useRef, useEffect } from 'react'
import { gsap } from 'gsap'

interface PreloaderProps {
  progress: number
  phase: 'loading' | 'revealing' | 'done'
  onRevealComplete: () => void
  statusText?: string
}

export function Preloader({ progress, phase, onRevealComplete, statusText }: PreloaderProps) {
  const contentRef = useRef<HTMLDivElement>(null)
  const topRef = useRef<HTMLDivElement>(null)
  const bottomRef = useRef<HTMLDivElement>(null)
  const hasRevealed = useRef(false)

  useEffect(() => {
    if (phase !== 'revealing' || hasRevealed.current) return
    hasRevealed.current = true

    const tl = gsap.timeline()

    // 1. Fade out loading text + bar
    tl.to(contentRef.current, {
      opacity: 0,
      y: -30,
      duration: 0.4,
      ease: 'power2.in',
    })

    // 2. Pause
    tl.addLabel('curtain', '+=0.15')

    // 3. Split curtain — top slides up, bottom slides down
    tl.to(topRef.current, {
      yPercent: -100,
      duration: 0.9,
      ease: 'power3.inOut',
    }, 'curtain')

    tl.to(bottomRef.current, {
      yPercent: 100,
      duration: 0.9,
      ease: 'power3.inOut',
    }, 'curtain')

    // 4. Signal complete
    tl.call(() => onRevealComplete())
  }, [phase, onRevealComplete])

  if (phase === 'done') return null

  return (
    <div className="fixed inset-0 z-50" style={{ pointerEvents: phase === 'revealing' ? 'none' : 'auto' }}>
      {/* Top curtain half */}
      <div
        ref={topRef}
        className="absolute top-0 left-0 w-full h-1/2"
        style={{ background: '#0A0A0C' }}
      />

      {/* Bottom curtain half */}
      <div
        ref={bottomRef}
        className="absolute bottom-0 left-0 w-full h-1/2"
        style={{ background: '#0A0A0C' }}
      />

      {/* Loading content — centered over both halves */}
      <div
        ref={contentRef}
        className="absolute inset-0 flex flex-col items-center justify-center z-10"
      >
        {/* LOADING text — bold */}
        <div
          style={{
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: '0.85rem',
            fontWeight: 700,
            letterSpacing: '0.35em',
            color: '#E8E8ED',
            textTransform: 'uppercase',
            marginBottom: '2rem',
          }}
        >
          Loading
        </div>

        {/* Progress bar */}
        <div
          className="w-48 overflow-hidden"
          style={{
            height: '2px',
            background: 'rgba(255,255,255,0.06)',
            borderRadius: '1px',
          }}
        >
          <div
            style={{
              height: '100%',
              width: `${progress * 100}%`,
              background: 'linear-gradient(90deg, transparent, #C8A45C)',
              borderRadius: '1px',
              transition: 'width 0.2s ease-out',
            }}
          />
        </div>

        {/* Percentage */}
        <div
          style={{
            fontFamily: '"JetBrains Mono", monospace',
            fontSize: '1.6rem',
            fontWeight: 600,
            color: '#C8A45C',
            marginTop: '1.2rem',
            letterSpacing: '0.05em',
          }}
        >
          {Math.round(progress * 100)}%
        </div>

        {/* Status text */}
        {statusText && (
          <div
            style={{
              fontFamily: '"JetBrains Mono", monospace',
              fontSize: '0.55rem',
              fontWeight: 400,
              color: '#55556A',
              marginTop: '0.75rem',
              letterSpacing: '0.15em',
              textTransform: 'uppercase',
              transition: 'opacity 0.3s ease',
            }}
          >
            {statusText}
          </div>
        )}
      </div>
    </div>
  )
}
