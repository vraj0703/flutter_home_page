import { useState, useCallback, useRef, useEffect } from 'react'
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
  const [name, setName] = useState('')
  const [role, setRole] = useState('')
  const [company, setCompany] = useState('')
  const [relationship, setRelationship] = useState(RELATIONSHIPS[1])
  const [message, setMessage] = useState('')
  const [submitted, setSubmitted] = useState(false)
  const backdropRef = useRef<HTMLDivElement>(null)

  // Reset form when overlay opens
  useEffect(() => {
    if (open) {
      setName('')
      setRole('')
      setCompany('')
      setRelationship(RELATIONSHIPS[1])
      setMessage('')
      setSubmitted(false)
    }
  }, [open])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    if (e.target === backdropRef.current) onClose()
  }, [onClose])

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim() || !message.trim()) return

    // Sanitize inputs — strip HTML tags to prevent XSS if rendered elsewhere
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

    // Store in localStorage
    try {
      const existing = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
      existing.push(testimonial)
      localStorage.setItem(STORAGE_KEY, JSON.stringify(existing))
    } catch { /* ignore */ }

    onSubmit(testimonial)
    setSubmitted(true)
  }, [name, role, company, relationship, message, onSubmit])

  if (!open) return null

  return (
    <div
      ref={backdropRef}
      onClick={handleBackdropClick}
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        background: 'rgba(10, 10, 14, 0.75)',
        backdropFilter: 'blur(8px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        animation: 'recOverlayIn 0.3s ease-out',
      }}
    >
      <div style={{
        width: '100%',
        maxWidth: '480px',
        background: '#1E1C18',
        border: '1px solid #3A3028',
        borderRadius: '16px',
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
            top: '16px',
            right: '16px',
            background: 'none',
            border: 'none',
            color: '#8A7A62',
            fontSize: '1.4rem',
            cursor: 'pointer',
            lineHeight: 1,
            padding: '4px',
          }}
          aria-label="Close"
        >
          &times;
        </button>

        {submitted ? (
          <div style={{ textAlign: 'center', padding: '2rem 0' }}>
            <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>Thank you</div>
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
              style={{
                marginTop: '1.5rem',
                fontFamily: 'JetBrains Mono, monospace',
                fontSize: '0.8rem',
                fontWeight: 500,
                letterSpacing: '0.08em',
                color: '#2A2420',
                background: '#C8A45C',
                border: 'none',
                borderRadius: '8px',
                padding: '10px 28px',
                cursor: 'pointer',
              }}
            >
              CLOSE
            </button>
          </div>
        ) : (
          <>
            <h2 style={{
              fontFamily: 'Syne, sans-serif',
              fontSize: '1.3rem',
              fontWeight: 700,
              color: '#FAF8F2',
              marginBottom: '0.3rem',
            }}>
              Recommend Vishal
            </h2>
            <p style={{
              fontFamily: 'Space Grotesk, sans-serif',
              fontSize: '0.8rem',
              color: '#8A7A62',
              marginBottom: '1.5rem',
            }}>
              Share your experience working together
            </p>

            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <Field label="Name *" value={name} onChange={setName} placeholder="Your name" />
              <Field label="Role" value={role} onChange={setRole} placeholder="e.g. Senior Engineer" />
              <Field label="Company" value={company} onChange={setCompany} placeholder="e.g. Twin Health" />

              <div>
                <label style={labelStyle}>Relationship</label>
                <select
                  value={relationship}
                  onChange={e => setRelationship(e.target.value)}
                  style={{ ...inputStyle, cursor: 'pointer' }}
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
                  style={{ ...inputStyle, resize: 'vertical', minHeight: '100px' }}
                />
              </div>

              <button
                type="submit"
                disabled={!name.trim() || !message.trim()}
                style={{
                  fontFamily: 'JetBrains Mono, monospace',
                  fontSize: '0.8rem',
                  fontWeight: 600,
                  letterSpacing: '0.1em',
                  color: '#2A2420',
                  background: (!name.trim() || !message.trim()) ? '#6A6050' : '#C8A45C',
                  border: 'none',
                  borderRadius: '8px',
                  padding: '12px 28px',
                  cursor: (!name.trim() || !message.trim()) ? 'not-allowed' : 'pointer',
                  marginTop: '0.5rem',
                  transition: 'background 0.2s',
                }}
              >
                SUBMIT RECOMMENDATION
              </button>
            </form>
          </>
        )}
      </div>

      <style>{`
        @keyframes recOverlayIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
      `}</style>
    </div>
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
  marginBottom: '6px',
}

const inputStyle: React.CSSProperties = {
  width: '100%',
  fontFamily: 'Space Grotesk, sans-serif',
  fontSize: '0.9rem',
  color: '#FAF8F2',
  background: '#2A2420',
  border: '1px solid #3A3028',
  borderRadius: '8px',
  padding: '10px 14px',
  outline: 'none',
  boxSizing: 'border-box',
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
        style={inputStyle}
      />
    </div>
  )
}
