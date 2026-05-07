/**
 * LateralControls — bottom-center HTML overlay for the lateral project view.
 *
 * Visible only while a project frame is in focus (clicked). Provides:
 *   • Gallery   — clears focus, returns camera to corridor
 *   • ◀ / ▶     — wrap-carousel through the 7 projects
 *   • Counter   — "P3 / 7 — Twin Health" with aria-live for screen readers
 *   • Open ↗    — emits `fireProjectOpen(projectId)`; per-project route
 *                 handling lives in App.tsx subscriber + RAJ-165..171.
 *
 * Spec: RAJ-84 (locked design comment).
 */

import { useEffect, useRef, useState, useCallback } from 'react'
import { PROJECTS } from '../../config/projects'
import {
  subscribeFocusChange,
  setClickTarget,
  clearFocus,
  fireProjectOpen,
} from '../three/gallery/galleryStore'
import { getAudioEngine } from '../../audio'
import { useReducedMotion } from '../../hooks/useReducedMotion'

const TOTAL = PROJECTS.length // 7

/** Hook for `prefers-reduced-transparency` and `prefers-contrast: more`.
 *  Both are treated identically — drop the blur, use a solid surface. */
function useSolidSurface(): boolean {
  const [solid, setSolid] = useState(() => {
    if (typeof window === 'undefined') return false
    return (
      window.matchMedia('(prefers-reduced-transparency: reduce)').matches ||
      window.matchMedia('(prefers-contrast: more)').matches
    )
  })
  useEffect(() => {
    const mq1 = window.matchMedia('(prefers-reduced-transparency: reduce)')
    const mq2 = window.matchMedia('(prefers-contrast: more)')
    const handler = () => setSolid(mq1.matches || mq2.matches)
    mq1.addEventListener('change', handler)
    mq2.addEventListener('change', handler)
    return () => {
      mq1.removeEventListener('change', handler)
      mq2.removeEventListener('change', handler)
    }
  }, [])
  return solid
}

const COLORS = {
  surfaceBase: 'rgba(20,16,12,0.72)',
  surfaceSolid: '#14100C',
  surfaceHover: 'rgba(255,255,255,0.06)',
  surfaceActive: 'rgba(255,255,255,0.10)',
  border: 'rgba(200,164,92,0.18)',
  borderSolid: 'rgba(200,164,92,0.55)',
  textPrimary: '#F0EAD6',
  textSecondary: '#B8AC95',
  accent: '#C8A45C',
  accentHover: '#D8B470',
  accentTextOn: '#1A140C',
} as const

const ARROW_DEBOUNCE_MS = 120
/** Camera arc takes ~800ms after click to settle; show the panel after that. */
const PANEL_REVEAL_DELAY_MS = 800

interface FocusState {
  index: number
  active: boolean
}

export function LateralControls({ enabled }: { enabled: boolean }) {
  const [focus, setFocus] = useState<FocusState>({ index: -1, active: false })
  const [visible, setVisible] = useState(false)
  const [titleSwapping, setTitleSwapping] = useState(false)
  const [wrapFlash, setWrapFlash] = useState(false)
  const lastArrowAt = useRef(0)
  const reducedMotion = useReducedMotion()
  const solid = useSolidSurface()

  // Subscribe to focus changes from galleryStore. setState inside the
  // subscription callback is the lint-approved pattern for syncing external
  // state into React. Visibility is driven from the same callback so we don't
  // need a second effect that would set state synchronously in its body.
  useEffect(() => {
    let revealTimer: number | undefined
    let swapTimer: number | undefined
    const unsub = subscribeFocusChange((state) => {
      setFocus((prev) => {
        if (state.active && prev.active && prev.index !== state.index && !reducedMotion) {
          if (swapTimer) window.clearTimeout(swapTimer)
          setTitleSwapping(true)
          swapTimer = window.setTimeout(() => setTitleSwapping(false), 250)
        }
        return state
      })

      if (revealTimer) {
        window.clearTimeout(revealTimer)
        revealTimer = undefined
      }
      if (state.active && enabled) {
        // Wait for camera arc to settle before revealing the panel.
        revealTimer = window.setTimeout(
          () => setVisible(true),
          reducedMotion ? 0 : PANEL_REVEAL_DELAY_MS,
        )
      } else {
        setVisible(false)
      }
    })
    return () => {
      if (revealTimer) window.clearTimeout(revealTimer)
      if (swapTimer) window.clearTimeout(swapTimer)
      unsub()
    }
  }, [enabled, reducedMotion])

  const project = focus.index >= 0 ? PROJECTS[focus.index] : null
  const positionLabel = focus.index >= 0 ? `P${focus.index + 1} / ${TOTAL}` : ''

  const goPrev = useCallback(() => {
    const now = performance.now()
    if (now - lastArrowAt.current < ARROW_DEBOUNCE_MS) return
    lastArrowAt.current = now
    if (focus.index < 0) return
    const next = (focus.index - 1 + TOTAL) % TOTAL
    const wrapped = focus.index === 0 // P1 → P7 wraps
    if (wrapped && !reducedMotion) {
      getAudioEngine()?.playWrapChime()
      setWrapFlash(true)
      window.setTimeout(() => setWrapFlash(false), 350)
    }
    setClickTarget(next)
  }, [focus.index, reducedMotion])

  const goNext = useCallback(() => {
    const now = performance.now()
    if (now - lastArrowAt.current < ARROW_DEBOUNCE_MS) return
    lastArrowAt.current = now
    if (focus.index < 0) return
    const next = (focus.index + 1) % TOTAL
    const wrapped = focus.index === TOTAL - 1 // P7 → P1 wraps
    if (wrapped && !reducedMotion) {
      getAudioEngine()?.playWrapChime()
      setWrapFlash(true)
      window.setTimeout(() => setWrapFlash(false), 350)
    }
    setClickTarget(next)
  }, [focus.index, reducedMotion])

  const goGallery = useCallback(() => {
    clearFocus()
  }, [])

  const onOpen = useCallback(() => {
    if (!project) return
    getAudioEngine()?.playShutterClick()
    fireProjectOpen(project.id)
  }, [project])

  // Keyboard shortcuts — Esc / ← / → / Enter (when on Open btn).
  // Active only while panel is visible to avoid clashing with KB scene shortcuts.
  useEffect(() => {
    if (!visible) return
    const handler = (e: KeyboardEvent) => {
      // Don't capture if user is typing in a form field
      const t = e.target as HTMLElement | null
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
      if (e.key === 'Escape') { e.preventDefault(); goGallery() }
      else if (e.key === 'ArrowLeft') { e.preventDefault(); goPrev() }
      else if (e.key === 'ArrowRight') { e.preventDefault(); goNext() }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [visible, goGallery, goPrev, goNext])

  // Don't render at all when not enabled — avoid burning React reconciles
  // while the panel can never be shown (e.g. flutter or contact phase).
  if (!enabled) return null

  const previewPrev = focus.index >= 0 ? PROJECTS[(focus.index - 1 + TOTAL) % TOTAL] : null
  const previewNext = focus.index >= 0 ? PROJECTS[(focus.index + 1) % TOTAL] : null

  return (
    <>
      <style>{LATERAL_CONTROLS_CSS}</style>
      <nav
        role="navigation"
        aria-label="Project navigation"
        aria-hidden={!visible}
        className="raj-lateral-controls"
        data-visible={visible || undefined}
        data-reduced={reducedMotion || undefined}
        data-solid={solid || undefined}
        style={{
          background: solid ? COLORS.surfaceSolid : COLORS.surfaceBase,
          border: `1px solid ${solid ? COLORS.borderSolid : COLORS.border}`,
        }}
      >
        <button
          type="button"
          className="raj-lc-btn raj-lc-btn--ghost"
          onClick={goGallery}
          aria-label="Return to gallery"
          title="Return to gallery (Esc)"
        >
          <IconExpand />
          <span className="raj-lc-label">Gallery</span>
        </button>

        <span className="raj-lc-divider" aria-hidden="true" />

        <button
          type="button"
          className="raj-lc-btn raj-lc-btn--icon"
          onClick={goPrev}
          aria-label={previewPrev ? `Previous project: ${previewPrev.title}` : 'Previous project'}
          title="Previous (←)"
        >
          <IconCaretLeft />
        </button>

        <div
          className="raj-lc-counter"
          aria-live="polite"
          aria-atomic="true"
          data-flash={wrapFlash || undefined}
        >
          <span className="raj-lc-counter-num" style={{ color: COLORS.textSecondary }}>
            {positionLabel}
          </span>
          {project && (
            <>
              <span className="raj-lc-counter-sep" aria-hidden="true" style={{ color: COLORS.textSecondary }}>
                {' — '}
              </span>
              <span
                className="raj-lc-counter-title"
                data-swapping={titleSwapping || undefined}
                style={{ color: COLORS.textPrimary }}
              >
                {project.title}
              </span>
            </>
          )}
        </div>

        <button
          type="button"
          className="raj-lc-btn raj-lc-btn--icon"
          onClick={goNext}
          aria-label={previewNext ? `Next project: ${previewNext.title}` : 'Next project'}
          title="Next (→)"
        >
          <IconCaretRight />
        </button>

        <span className="raj-lc-divider" aria-hidden="true" />

        <button
          type="button"
          className="raj-lc-btn raj-lc-btn--accent"
          onClick={onOpen}
          aria-label={project ? `Open ${project.title} project page` : 'Open project page'}
          title="Open project (Enter)"
        >
          <span className="raj-lc-label">Open</span>
          <IconArrowUpRight />
        </button>
      </nav>
    </>
  )
}

/* ── Icons (16×16, stroke 1.5) ─────────────────────────── */

function IconExpand() {
  return (
    <svg width={16} height={16} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M2 6V2H6M14 6V2H10M2 10V14H6M14 10V14H10" />
    </svg>
  )
}
function IconCaretLeft() {
  return (
    <svg width={16} height={16} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M10 12L6 8l4-4" />
    </svg>
  )
}
function IconCaretRight() {
  return (
    <svg width={16} height={16} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M6 4l4 4-4 4" />
    </svg>
  )
}
function IconArrowUpRight() {
  return (
    <svg width={14} height={14} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M4 10L10 4M5 4h5v5" />
    </svg>
  )
}

/* ── Styles (scoped class names, prefixed `raj-lc-`) ─────
   Inline <style> block keeps the component self-contained. The codebase
   uses inline-style + module-scoped CSS already (see RecommendationOverlay);
   this matches that pattern. */

const LATERAL_CONTROLS_CSS = `
.raj-lateral-controls {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%) translateY(8px);
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 56px;
  padding: 0 12px;
  max-width: 720px;
  border-radius: 12px;
  z-index: 50;
  pointer-events: none;
  opacity: 0;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  contain: layout paint;
  transition: opacity 200ms cubic-bezier(0.2, 0.8, 0.2, 1),
              transform 200ms cubic-bezier(0.2, 0.8, 0.2, 1);
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  color: ${COLORS.textPrimary};
  user-select: none;
}
.raj-lateral-controls[data-visible] {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
  pointer-events: auto;
}
.raj-lateral-controls[data-solid] {
  backdrop-filter: none;
  -webkit-backdrop-filter: none;
}
.raj-lateral-controls[data-reduced] {
  transition: none;
}

.raj-lc-divider {
  width: 1px;
  height: 24px;
  background: rgba(255,255,255,0.08);
  margin: 0 2px;
  flex-shrink: 0;
}

.raj-lc-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 40px;
  min-width: 44px;
  padding: 0 12px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: ${COLORS.textPrimary};
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.02em;
  cursor: pointer;
  transition: background-color 120ms ease-out,
              color 120ms ease-out,
              border-color 120ms ease-out,
              transform 120ms ease-out;
}
.raj-lateral-controls[data-reduced] .raj-lc-btn { transition: none; }

.raj-lc-btn:hover { background: ${COLORS.surfaceHover}; }
.raj-lc-btn:active { transform: scale(0.97); transition-duration: 80ms; background: ${COLORS.surfaceActive}; }
.raj-lc-btn:focus-visible {
  outline: 2px solid ${COLORS.accent};
  outline-offset: 2px;
}

.raj-lc-btn--icon { padding: 0; min-width: 44px; }
.raj-lc-btn--icon:hover { color: ${COLORS.accent}; }
.raj-lc-btn--icon:active { transform: scale(0.94); }

.raj-lc-btn--accent {
  border: 1px solid ${COLORS.accent};
  color: ${COLORS.textPrimary};
}
.raj-lc-btn--accent:hover {
  background: ${COLORS.accent};
  color: ${COLORS.accentTextOn};
  transform: scale(1.02);
}
.raj-lc-btn--accent:active { transform: scale(0.98); }
.raj-lc-btn--accent:focus-visible { outline-offset: 3px; }

.raj-lc-counter {
  display: inline-flex;
  align-items: baseline;
  gap: 0;
  padding: 0 8px;
  font-family: 'JetBrains Mono', 'IBM Plex Mono', 'Inconsolata', monospace;
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.02em;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
  max-width: min(360px, 50vw);
  overflow: hidden;
  text-overflow: ellipsis;
  transition: color 350ms ease-out;
}
.raj-lc-counter[data-flash] { color: ${COLORS.accent}; }

.raj-lc-counter-title {
  font-family: 'Cormorant Garamond', 'Spectral', Georgia, serif;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0;
  transition: opacity 250ms ease-in-out;
}
.raj-lc-counter-title[data-swapping] { opacity: 0; }

@media (max-width: 768px) {
  .raj-lateral-controls {
    bottom: 16px;
    left: 8px;
    right: 8px;
    transform: translateY(8px);
    max-width: none;
    width: calc(100% - 16px);
    justify-content: space-between;
  }
  .raj-lateral-controls[data-visible] {
    transform: translateY(0);
  }
  .raj-lc-label { display: none; }
  .raj-lc-counter { font-size: 12px; }
  .raj-lc-counter-title { font-size: 14px; }
}

@media (max-width: 480px) {
  .raj-lc-counter-sep,
  .raj-lc-counter-title { display: none; }
}
`
