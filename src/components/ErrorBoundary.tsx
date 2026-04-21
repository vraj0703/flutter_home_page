import { Component, type ErrorInfo, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
  onError?: (error: Error, info: ErrorInfo) => void
}

interface State {
  hasError: boolean
  error: Error | null
}

/**
 * Catches render-phase errors in its subtree. Primary use: wrapping the R3F
 * Canvas so a texture load failure or material-setup error doesn't crash the
 * entire portfolio.
 *
 * The default fallback is a minimal static screen with a mailto link — it
 * deliberately avoids Three.js, GSAP, or any heavy dependency so it still
 * renders if the primary bundle blew up.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // Surface to console so QA can grab the stack from production DevTools.
    console.error('[ErrorBoundary]', error, info.componentStack)
    this.props.onError?.(error, info)
  }

  render() {
    if (!this.state.hasError) return this.props.children
    if (this.props.fallback) return this.props.fallback

    return (
      <div
        style={{
          position: 'absolute',
          inset: 0,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#0A0A0C',
          color: '#C4B496',
          fontFamily: 'InconsolataNerd, monospace, sans-serif',
          padding: '2rem',
          textAlign: 'center',
          gap: '1rem',
        }}
      >
        <h1 style={{ fontSize: '1.5rem', margin: 0, letterSpacing: '0.1em' }}>
          Something went sideways
        </h1>
        <p style={{ maxWidth: '420px', lineHeight: 1.6, opacity: 0.75 }}>
          The 3D gallery couldn&rsquo;t render on this device. You can still reach
          me the old-fashioned way.
        </p>
        <a
          href="mailto:vraj0703@gmail.com"
          style={{
            color: '#E8C97A',
            textDecoration: 'none',
            border: '1px solid #C8A45C',
            padding: '0.5rem 1.25rem',
            borderRadius: '2px',
            letterSpacing: '0.08em',
          }}
        >
          vraj0703@gmail.com
        </a>
      </div>
    )
  }
}
