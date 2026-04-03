import { useEffect, useState, useCallback } from 'react'
import { GalleryScene, subscribeKbFocus, subscribeCTAClick, subscribeBackClick, subscribeConnectClick } from '../three/GalleryScene'
import { RecommendationOverlay } from '../ui/RecommendationOverlay'
import type { Testimonial } from '../../config/testimonials'

interface Props {
  onNavigateToContact?: () => void
  onNavigateBack?: () => void
}

export function S3_Gallery({ onNavigateToContact, onNavigateBack }: Props) {
  const [kbActive, setKbActive] = useState(false)
  const [recOpen, setRecOpen] = useState(false)

  useEffect(() => subscribeKbFocus(setKbActive), [])
  useEffect(() => subscribeCTAClick(() => setRecOpen(true)), [])
  useEffect(() => subscribeBackClick(() => onNavigateBack?.()), [onNavigateBack])
  useEffect(() => subscribeConnectClick(() => onNavigateToContact?.()), [onNavigateToContact])

  const handleRecSubmit = useCallback((_t: Testimonial) => {
    // Testimonial saved to localStorage by the overlay component
    // Could also push to a live array here if needed
  }, [])

  const handleForward = useCallback(() => {
    onNavigateToContact?.()
  }, [onNavigateToContact])

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', userSelect: 'none' }}>
      <GalleryScene />
      <RecommendationOverlay open={recOpen} onClose={() => setRecOpen(false)} onSubmit={handleRecSubmit} />
      {kbActive && (
        <div style={{
          position: 'fixed',
          bottom: '5%',
          left: '50%',
          transform: 'translateX(-50%)',
          display: 'flex',
          gap: '16px',
          zIndex: 50,
          animation: 'kbNavFadeIn 0.4s ease-out',
        }}>
          <button
            onClick={handleForward}
            style={{
              fontFamily: 'JetBrains Mono, monospace',
              fontSize: '0.8rem',
              fontWeight: 500,
              letterSpacing: '0.08em',
              color: '#C8A45C',
              background: 'rgba(10, 10, 14, 0.65)',
              border: '1px solid #C8A45C',
              borderRadius: '6px',
              padding: '10px 24px',
              cursor: 'pointer',
              backdropFilter: 'blur(8px)',
              transition: 'all 0.25s ease',
            }}
            onMouseEnter={e => {
              e.currentTarget.style.background = '#C8A45C'
              e.currentTarget.style.color = '#0A0A0E'
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = 'rgba(10, 10, 14, 0.65)'
              e.currentTarget.style.color = '#C8A45C'
            }}
          >
            Forward →
          </button>
          <style>{`
            @keyframes kbNavFadeIn {
              from { opacity: 0; transform: translateX(-50%) translateY(12px); }
              to   { opacity: 1; transform: translateX(-50%) translateY(0); }
            }
          `}</style>
        </div>
      )}
    </div>
  )
}
