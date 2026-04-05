import type { Testimonial } from '../../config/testimonials'

interface TestimonialCardProps {
  testimonial: Testimonial
  isLinkedIn?: boolean
}

export function TestimonialCard({ testimonial, isLinkedIn }: TestimonialCardProps) {
  
  const styles = (
    <style>{`
      .testimonial-card {
        flex-shrink: 0;
        width: 320px;
        height: 400px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        padding: 2.2rem 2rem;
        border-radius: 20px;
        background: linear-gradient(135deg, #FAF8F2 0%, #F0EBE1 100%);
        border: 1px solid rgba(200, 164, 92, 0.25);
        box-shadow: 0 12px 32px rgba(0,0,0,0.06), inset 0 2px 4px rgba(255,255,255,0.8);
        position: relative;
        overflow: hidden;
        transition: transform 0.4s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.4s cubic-bezier(0.2, 0.8, 0.2, 1), border-color 0.4s;
      }
      .testimonial-card::before {
        content: "";
        position: absolute;
        inset: 0;
        background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
        opacity: 0.04;
        pointer-events: none;
      }
      .testimonial-card:hover {
        transform: translateY(-8px);
        box-shadow: 0 24px 48px rgba(0,0,0,0.12), inset 0 2px 4px rgba(255,255,255,1);
        border-color: rgba(200, 164, 92, 0.6);
      }
      .linkedin-btn {
        padding: 12px 28px;
        background: #C8A45C;
        color: #1E1C18;
        border-radius: 8px;
        font-size: 0.85rem;
        font-weight: 600;
        font-family: 'Space Grotesk', sans-serif;
        text-decoration: none;
        transition: background 0.3s, transform 0.2s, box-shadow 0.3s;
        box-shadow: 0 4px 12px rgba(200, 164, 92, 0.2);
        letter-spacing: 0.02em;
      }
      .linkedin-btn:hover {
        background: #dbb770;
        transform: translateY(-2px);
        box-shadow: 0 8px 24px rgba(200, 164, 92, 0.35);
      }
      .linkedin-card {
        flex-shrink: 0;
        width: 320px;
        height: 400px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        border-radius: 20px;
        background: linear-gradient(145deg, rgba(30, 30, 36, 0.6), rgba(15, 15, 18, 0.8));
        backdrop-filter: blur(12px);
        border: 1px solid rgba(255, 255, 255, 0.08);
        box-shadow: 0 16px 40px rgba(0,0,0,0.4), inset 0 1px 1px rgba(255,255,255,0.05);
        transition: transform 0.4s cubic-bezier(0.2, 0.8, 0.2, 1), border-color 0.4s;
        position: relative;
      }
      .linkedin-card:hover {
        transform: translateY(-8px);
        border-color: rgba(200, 164, 92, 0.4);
      }
    `}</style>
  )

  if (isLinkedIn) {
    return (
      <>
        {styles}
        <div className="linkedin-card">
          <div style={{ color: '#FAF8F2', fontSize: '1.2rem', fontWeight: 600, fontFamily: 'Syne, sans-serif', marginBottom: '1.8rem', letterSpacing: '-0.01em' }}>
            More on LinkedIn
          </div>
          <a
            href="https://linkedin.com/in/vishalraj"
            target="_blank"
            rel="noopener noreferrer"
            className="linkedin-btn"
          >
            View Recommendations
          </a>
        </div>
      </>
    )
  }

  return (
    <>
      {styles}
      <div className="testimonial-card">
        <div style={{ position: 'relative', zIndex: 1 }}>
          <div style={{ 
            color: '#C8A45C', 
            fontSize: '3rem', 
            lineHeight: 0.8, 
            fontFamily: 'Syne, serif', 
            marginBottom: '0.5rem',
            opacity: 0.9
          }}>
            "
          </div>
          <p style={{
            fontFamily: 'Space Grotesk, sans-serif',
            fontSize: '0.95rem',
            fontWeight: 400,
            color: '#2A2420',
            lineHeight: 1.65,
          }}>
            {testimonial.text}
          </p>
        </div>
        <div style={{ 
          borderTop: '1px solid rgba(200, 164, 92, 0.2)', 
          paddingTop: '1.2rem', 
          marginTop: '1.5rem',
          position: 'relative',
          zIndex: 1
        }}>
          <div style={{ 
            fontFamily: 'Syne, sans-serif', 
            fontWeight: 700, 
            color: '#1E1C18', 
            fontSize: '1rem',
            letterSpacing: '-0.01em'
          }}>
            {testimonial.name}
          </div>
          <div style={{
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: '0.7rem',
            color: '#8A7A62',
            letterSpacing: '0.04em',
            marginTop: '6px',
            textTransform: 'uppercase',
            fontWeight: 500
          }}>
            {testimonial.role} · {testimonial.company}
          </div>
        </div>
      </div>
    </>
  )
}
