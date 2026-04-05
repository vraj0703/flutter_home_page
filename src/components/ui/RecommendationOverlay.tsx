import { useState, useCallback, useRef, useEffect } from 'react'
import { gsap } from 'gsap'
import type { Testimonial } from '../../config/testimonials'

const STORAGE_KEY = 'raj_sadan_recommendations'

interface Props {
  open: boolean
  onClose: () => void
  onSubmit: (testimonial: Testimonial) => void
}

const RELATIONSHIPS = [
  'Managed Vishal',
  'Worked with Vishal',
  'Reported to Vishal',
]

export function RecommendationOverlay({ open, onClose, onSubmit }: Props) {
  const [renderOpen, setRenderOpen] = useState(false)
  const [isClosing, setIsClosing] = useState(false)

  const [name, setName] = useState('')
  const [role, setRole] = useState('')
  const [company, setCompany] = useState('')
  const [relationship, setRelationship] = useState(RELATIONSHIPS[1])
  const [message, setMessage] = useState('')
  const [submitted, setSubmitted] = useState(false)
  
  const backdropRef = useRef<HTMLDivElement>(null)
  const modalRef = useRef<HTMLDivElement>(null)

  // Manage deferred unmount state for exit animations
  useEffect(() => {
    if (open) {
      setRenderOpen(true)
      setIsClosing(false)
      // Reset form
      setName('')
      setRole('')
      setCompany('')
      setRelationship(RELATIONSHIPS[1])
      setMessage('')
      setSubmitted(false)
    } else if (renderOpen) {
      setIsClosing(true)
    }
  }, [open, renderOpen])

  // GSAP animation
  useEffect(() => {
    if (renderOpen && !isClosing) {
      // Entrance
      gsap.fromTo(backdropRef.current, { opacity: 0 }, { opacity: 1, duration: 0.4, ease: 'power2.out' })
      gsap.fromTo(modalRef.current, { opacity: 0, y: 30, scale: 0.95 }, { opacity: 1, y: 0, scale: 1, duration: 0.6, ease: 'back.out(1.2)' })
    } else if (isClosing) {
      // Exit
      const tl = gsap.timeline({ onComplete: () => setRenderOpen(false) })
      tl.to(modalRef.current, { opacity: 0, y: 20, scale: 0.95, duration: 0.3, ease: 'power2.in' })
      tl.to(backdropRef.current, { opacity: 0, duration: 0.3, ease: 'power2.in' }, '<0.1')
    }
  }, [renderOpen, isClosing])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    if (e.target === backdropRef.current) onClose()
  }, [onClose])

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim() || !message.trim()) return

    // Sanitize 
    const strip = (s: string) => s.trim().replace(/<[^>]*>/g, '')

    const testimonial: Testimonial = {
      id: `user-${Date.now()}`,
      name: strip(name),
      role: strip(role),
      company: strip(company),
      text: strip(message),
      relationship,
      date: new Date().toISOString().slice(0, 7),
    }

    try {
      const existing = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      existing.push(testimonial)
      localStorage.setItem(STORAGE_KEY, JSON.stringify(existing))
    } catch { /* ignore */ }

    onSubmit(testimonial)
    setSubmitted(true)
  }, [name, role, company, relationship, message, onSubmit])

  if (!renderOpen) return null

  return (
    <>
      <style>{`
        .glass-input {
          width: 100%;
          font-family: 'Space Grotesk', sans-serif;
          font-size: 0.9rem;
          color: #FAF8F2;
          background: rgba(10, 10, 12, 0.4);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 8px;
          padding: 10px 14px;
          outline: none;
          box-sizing: border-box;
          transition: border-color 0.3s, box-shadow 0.3s, background 0.3s;
        }
        .glass-input::placeholder {
          color: rgba(255, 255, 255, 0.3);
        }
        .glass-input:focus {
          border-color: rgba(200, 164, 92, 0.6);
          box-shadow: 0 0 12px rgba(200, 164, 92, 0.15), inset 0 0 8px rgba(200, 164, 92, 0.05);
          background: rgba(20, 20, 24, 0.6);
        }
        .submit-btn {
          font-family: 'JetBrains Mono', monospace;
          font-size: 0.8rem;
          font-weight: 600;
          letter-spacing: 0.1em;
          color: #2A2420;
          background: #C8A45C;
          border: none;
          border-radius: 8px;
          padding: 12px 28px;
          cursor: pointer;
          margin-top: 0.5rem;
          transition: background 0.3s, box-shadow 0.3s, transform 0.1s;
          box-shadow: 0 4px 12px rgba(200, 164, 92, 0.2);
        }
        .submit-btn:hover:not(:disabled) {
          background: #dbb770;
          box-shadow: 0 6px 20px rgba(200, 164, 92, 0.3);
          transform: translateY(-1px);
        }
        .submit-btn:disabled {
          background: rgba(255,255,255,0.1);
          color: rgba(255,255,255,0.3);
          box-shadow: none;
          cursor: not-allowed;
        }
      `}</style>

      <div
        ref={backdropRef}
        onClick={handleBackdropClick}
        style={{
          position: 'fixed',
          inset: 0,
          zIndex: 100,
          background: 'rgba(5, 5, 8, 0.75)',
          backdropFilter: 'blur(12px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        <div 
          ref={modalRef}
          style={{
          width: '100%',
          maxWidth: '480px',
          background: 'linear-gradient(145deg, rgba(30, 30, 36, 0.7), rgba(20, 20, 24, 0.85))',
          backdropFilter: 'blur(24px)',
          border: '1px solid rgba(255, 255, 255, 0.08)',
          boxShadow: '0 24px 64px rgba(0,0,0,0.6), inset 0 1px 1px rgba(255,255,255,0.1)',
          borderRadius: '20px',
          padding: '2.5rem',
          position: 'relative',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}>
          {/* Close button */}
          <button
            onClick={onClose}
            style={{
              position: 'absolute',
              top: '20px',
              right: '20px',
              background: 'rgba(255,255,255,0.05)',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '50%',
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#A09880',
              cursor: 'pointer',
              transition: 'background 0.2s, color 0.2s',
            }}
            aria-label="Close"
            onMouseEnter={e => {
              (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.1)';
              (e.currentTarget as HTMLButtonElement).style.color = '#FFF';
            }}
            onMouseLeave={e => {
              (e.currentTarget as HTMLButtonElement).style.background = 'rgba(255,255,255,0.05)';
              (e.currentTarget as HTMLButtonElement).style.color = '#A09880';
            }}
          >
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M1 1L13 13M1 13L13 1" strokeLinecap="round"/>
            </svg>
          </button>

          {submitted ? (
            <div style={{ textAlign: 'center', padding: '2rem 0' }}>
              <div style={{ fontSize: '2rem', marginBottom: '1rem', fontFamily: 'Syne, sans-serif', color: '#FAF8F2' }}>Thank you</div>
              <p style={{
                fontFamily: 'Space Grotesk, sans-serif',
                fontSize: '0.95rem',
                color: '#A09880',
                lineHeight: 1.7,
              }}>
                Your recommendation has been saved. It will be reviewed and published soon.
              </p>
              <button
                onClick={onClose}
                className="submit-btn"
                style={{ marginTop: '1.5rem' }}
              >
                CLOSE
              </button>
            </div>
          ) : (
            <>
              <h2 style={{
                fontFamily: 'Syne, sans-serif',
                fontSize: '1.4rem',
                fontWeight: 700,
                color: '#FAF8F2',
                marginBottom: '0.3rem',
                letterSpacing: '-0.02em',
              }}>
                Recommend Vishal
              </h2>
              <p style={{
                fontFamily: 'Space Grotesk, sans-serif',
                fontSize: '0.85rem',
                color: '#8A7A62',
                marginBottom: '1.8rem',
              }}>
                Share your experience working together
              </p>

              <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.2rem' }}>
                <Field label="Name *" value={name} onChange={setName} placeholder="Your name" />
                <Field label="Role" value={role} onChange={setRole} placeholder="e.g. Senior Engineer" />
                <Field label="Company" value={company} onChange={setCompany} placeholder="e.g. Twin Health" />

                <div>
                  <label style={labelStyle}>Relationship</label>
                  <select
                    value={relationship}
                    onChange={e => setRelationship(e.target.value)}
                    className="glass-input"
                    style={{ cursor: 'pointer' }}
                  >
                    {RELATIONSHIPS.map(r => <option key={r} value={r}>{r}</option>)}
                  </select>
                </div>

                <div>
                  <label style={labelStyle}>Message *</label>
                  <textarea
                    value={message}
                    onChange={e => setMessage(e.target.value)}
                    placeholder="What was it like working with Vishal?"
                    rows={4}
                    className="glass-input"
                    style={{ resize: 'vertical', minHeight: '100px' }}
                  />
                </div>

                <button
                  type="submit"
                  disabled={!name.trim() || !message.trim()}
                  className="submit-btn"
                >
                  SUBMIT RECOMMENDATION
                </button>
              </form>
            </>
          )}
        </div>
      </div>
    </>
  )
}

/* ── Shared styles ──────────────────────────────────────── */

const labelStyle: React.CSSProperties = {
  fontFamily: 'JetBrains Mono, monospace',
  fontSize: '0.7rem',
  fontWeight: 500,
  letterSpacing: '0.08em',
  color: '#A09880',
  display: 'block',
  marginBottom: '8px',
  textTransform: 'uppercase',
}

function Field({ label, value, onChange, placeholder }: {
  label: string; value: string; onChange: (v: string) => void; placeholder: string
}) {
  return (
    <div>
      <label style={labelStyle}>{label}</label>
      <input
        type="text"
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        className="glass-input"
      />
    </div>
  )
}
