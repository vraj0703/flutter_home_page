import type { Testimonial } from '../../config/testimonials'

interface TestimonialCardProps {
  testimonial: Testimonial
  isLinkedIn?: boolean
}

export function TestimonialCard({ testimonial, isLinkedIn }: TestimonialCardProps) {
  if (isLinkedIn) {
    return (
      <div style={{
        flexShrink: 0,
        width: '320px',
        height: '400px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '16px',
        background: '#3A3028',
        border: '2px solid #C8A45C',
      }}>
        <div style={{ color: '#FAF8F2', fontSize: '1.1rem', fontWeight: 600, fontFamily: 'Syne, sans-serif', marginBottom: '1.5rem' }}>
          More on LinkedIn
        </div>
        <a
          href="https://linkedin.com/in/vishalraj"
          target="_blank"
          rel="noopener noreferrer"
          style={{
            padding: '10px 24px',
            background: '#C8A45C',
            color: '#2A2420',
            borderRadius: '8px',
            fontSize: '0.85rem',
            fontWeight: 600,
            fontFamily: 'Space Grotesk, sans-serif',
            textDecoration: 'none',
          }}
        >
          View Recommendations
        </a>
      </div>
    )
  }

  return (
    <div style={{
      flexShrink: 0,
      width: '320px',
      height: '400px',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      padding: '2rem',
      borderRadius: '16px',
      background: '#FAF8F2',
      border: '1px solid #D4C4A0',
      boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
    }}>
      <div>
        <div style={{ color: '#C8A45C', fontSize: '2.5rem', lineHeight: 1, fontFamily: 'Syne, serif', marginBottom: '1rem' }}>"</div>
        <p style={{
          fontFamily: 'Space Grotesk, sans-serif',
          fontSize: '0.95rem',
          fontWeight: 300,
          color: '#3A3028',
          lineHeight: 1.7,
        }}>
          {testimonial.text}
        </p>
      </div>
      <div style={{ borderTop: '1px solid #D4C4A0', paddingTop: '1rem', marginTop: '1rem' }}>
        <div style={{ fontFamily: 'Syne, sans-serif', fontWeight: 600, color: '#3A3028', fontSize: '0.9rem' }}>
          {testimonial.name}
        </div>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace',
          fontSize: '0.65rem',
          color: '#8A7A62',
          letterSpacing: '0.05em',
          marginTop: '4px',
        }}>
          {testimonial.role} · {testimonial.company}
        </div>
      </div>
    </div>
  )
}
