import { useRef, useEffect, useState } from 'react'
import { KeyboardScene, resetBoot } from '../three/KeyboardScene'
import { getAudioEngine } from '../../audio'

interface Props {
  visible: boolean
  onScrollBack?: () => void
  onReachEnd?: () => void
}

export function S_Skills({ visible, onScrollBack, onReachEnd }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const backScrollCount = useRef(0)
  const scrollBackFired = useRef(false)
  const [showButton, setShowButton] = useState(false)

  // Reset on visibility change — trigger boot-up animation
  useEffect(() => {
    if (visible) {
      resetBoot() // trigger keyboard power-on sequence
      setTimeout(() => getAudioEngine()?.playBootSweep(), 300) // delayed to sync with board float-up
      backScrollCount.current = 0
      scrollBackFired.current = false
      setShowButton(false)
      const timer = setTimeout(() => setShowButton(true), 2000) // delay for boot to complete
      return () => clearTimeout(timer)
    }
  }, [visible])

  // Stable ref for onScrollBack to avoid re-registering wheel listener
  const onScrollBackRef = useRef(onScrollBack)
  onScrollBackRef.current = onScrollBack

  // Wheel handler — detect back-scroll to return to previous section
  useEffect(() => {
    if (!visible || !containerRef.current) return
    const el = containerRef.current

    const onWheel = (e: WheelEvent) => {
      e.preventDefault()

      if (e.deltaY < 0 && onScrollBackRef.current) {
        backScrollCount.current++
        if (backScrollCount.current >= 2 && !scrollBackFired.current) {
          scrollBackFired.current = true
          onScrollBackRef.current()
        }
      } else if (e.deltaY > 0) {
        backScrollCount.current = 0
      }
    }

    el.addEventListener('wheel', onWheel, { passive: false })
    return () => el.removeEventListener('wheel', onWheel)
  }, [visible]) // only re-register when visibility changes

  if (!visible) return null

  return (
    <div
      ref={containerRef}
      style={{
        position: 'absolute',
        inset: 0,
        zIndex: 30,
        overflow: 'hidden',
      }}
    >
      <KeyboardScene />

      {/* Contact Me → button */}
      <div style={{
        position: 'absolute',
        bottom: '4%',
        right: '40px',
        zIndex: 10,
        opacity: showButton ? 1 : 0,
        pointerEvents: showButton ? 'auto' : 'none',
        transition: 'opacity 0.8s ease',
      }}>
        <button
          onClick={() => onReachEnd?.()}
          style={{
            background: 'rgba(255,255,255,0.10)',
            backdropFilter: 'blur(12px)',
            border: '1px solid rgba(255,255,255,0.18)',
            color: '#fff',
            padding: '14px 32px',
            borderRadius: '40px',
            fontSize: '15px',
            fontFamily: "'ModrntUrban', sans-serif",
            letterSpacing: '1.5px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            transition: 'background 0.3s ease, transform 0.3s ease',
          }}
          onMouseEnter={e => {
            e.currentTarget.style.background = 'rgba(255,255,255,0.18)'
            e.currentTarget.style.transform = 'scale(1.05)'
          }}
          onMouseLeave={e => {
            e.currentTarget.style.background = 'rgba(255,255,255,0.10)'
            e.currentTarget.style.transform = 'scale(1)'
          }}
        >
          Contact Me
          <span style={{ fontSize: '18px' }}>→</span>
        </button>
      </div>
    </div>
  )
}
