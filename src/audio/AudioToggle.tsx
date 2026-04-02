import { useAudio } from './AudioProvider'

/** Speaker toggle — bottom-left corner, always visible */
export function AudioToggle() {
  const { muted, toggleMute } = useAudio()

  return (
    <button
      onClick={toggleMute}
      aria-label={muted ? 'Unmute audio' : 'Mute audio'}
      style={{
        position: 'fixed',
        bottom: '20px',
        left: '20px',
        zIndex: 200,
        width: '40px',
        height: '40px',
        borderRadius: '50%',
        border: '1px solid rgba(255,255,255,0.15)',
        background: 'rgba(10,10,12,0.6)',
        backdropFilter: 'blur(8px)',
        WebkitBackdropFilter: 'blur(8px)',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: muted ? '#55556A' : '#C8A45C',
        fontSize: '16px',
        transition: 'color 0.2s, border-color 0.2s, transform 0.2s',
        padding: 0,
      }}
      onMouseEnter={e => {
        e.currentTarget.style.borderColor = 'rgba(200,164,92,0.4)'
        e.currentTarget.style.transform = 'scale(1.1)'
      }}
      onMouseLeave={e => {
        e.currentTarget.style.borderColor = 'rgba(255,255,255,0.15)'
        e.currentTarget.style.transform = 'scale(1)'
      }}
    >
      {/* SVG speaker icon */}
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
        {muted ? (
          <>
            <line x1="23" y1="9" x2="17" y2="15" />
            <line x1="17" y1="9" x2="23" y2="15" />
          </>
        ) : (
          <>
            <path d="M15.54 8.46a5 5 0 0 1 0 7.07" />
            <path d="M19.07 4.93a10 10 0 0 1 0 14.14" />
          </>
        )}
      </svg>
    </button>
  )
}
