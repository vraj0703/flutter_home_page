interface AboutCardProps {
  title: string
  subtitle: string
  description: string
  index: number
  progress: number
}

export function AboutCard({ title, subtitle, description, index, progress }: AboutCardProps) {
  const peel = Math.min(1, Math.max(0, progress))

  return (
    <div
      className="absolute inset-0 flex items-center justify-center px-6"
      style={{
        perspective: '1200px',
        opacity: peel > 0.92 ? 0 : 1,
        pointerEvents: peel > 0.5 ? 'none' : 'auto',
      }}
    >
      <div
        className="w-full max-w-xl p-10 md:p-14"
        style={{
          background: 'linear-gradient(145deg, rgba(26,26,31,0.85) 0%, rgba(15,15,18,0.95) 100%)',
          backdropFilter: 'blur(24px)',
          border: '1px solid rgba(255,255,255,0.04)',
          borderRadius: '20px',
          boxShadow: '0 24px 48px rgba(0,0,0,0.4), 0 0 1px rgba(200,164,92,0.1)',
          transformOrigin: 'top center',
          transform: `rotateX(${-peel * 85}deg) translateZ(${peel * 30}px)`,
          backfaceVisibility: 'hidden',
        }}
      >
        {/* Number + subtitle */}
        <div className="flex items-center gap-3 mb-6">
          <span
            style={{
              fontFamily: 'InconsolataNerd, monospace',
              fontSize: '0.65rem',
              fontWeight: 300,
              letterSpacing: '0.15em',
              color: '#C8A45C',
            }}
          >
            0{index + 1}
          </span>
          <div className="h-px flex-1" style={{ background: 'rgba(200,164,92,0.15)' }} />
          <span
            style={{
              fontFamily: 'InconsolataNerd, monospace',
              fontSize: '0.6rem',
              fontWeight: 300,
              letterSpacing: '0.15em',
              color: '#55556A',
              textTransform: 'uppercase',
            }}
          >
            {subtitle}
          </span>
        </div>

        {/* Title */}
        <h3
          style={{
            fontFamily: 'ModrntUrban, sans-serif',
            fontSize: 'clamp(1.5rem, 3vw, 2rem)',
            fontWeight: 600,
            color: '#E8E8ED',
            letterSpacing: '-0.02em',
            lineHeight: 1.2,
            marginBottom: '1rem',
          }}
        >
          {title}
        </h3>

        {/* Description */}
        <p
          style={{
            fontFamily: 'ModrntUrban, sans-serif',
            fontSize: 'clamp(0.9rem, 1.2vw, 1.05rem)',
            fontWeight: 300,
            color: '#8888A0',
            lineHeight: 1.7,
          }}
        >
          {description}
        </p>
      </div>
    </div>
  )
}
