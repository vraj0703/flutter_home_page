/**
 * Unified motion token system — single source of truth for all animation parameters.
 * Consumed by GSAP, Three.js useFrame, and Spring simulations across the site.
 */
export const MOTION = {
  /** Core durations in seconds */
  duration: {
    instant:   0.08,  // micro-feedback (hover glow)
    fast:      0.2,   // button clicks, cursor changes
    medium:    0.45,  // element entrances, frame hovers
    slow:      0.7,   // section reveals
    cinematic: 1.6,   // full-screen transitions
  },

  /** GSAP easing strings */
  ease: {
    enter:  'power3.out',     // things arriving
    exit:   'power2.in',      // things leaving
    inOut:  'power3.inOut',   // full-screen wipes
    spring: 'back.out(1.2)',  // playful land (keyboard boot, logo reveal)
    linear: 'none',           // scrub/progress
  },

  /** Per-frame exponential damp() speed values */
  spring: {
    snappy: 12,  // gallery frame glow, locked camera
    medium:  8,  // camera walk
    floaty:  3,  // floating keyboard
  },

  /** Stagger units in seconds */
  stagger: {
    tight:  0.05,
    normal: 0.10,
    loose:  0.18,
  },

  /** SectionTransition derived timings */
  transition: {
    wipeIn:       0.8,   // half of cinematic
    wipeStagger:  0.10,  // layer cascade
    midpoint:     0.5,   // fire midpoint EARLY for React settle time
    hold:         0.2,   // screen-full hold
    wipeOut:      0.72,  // exit slightly faster than enter
    exitStagger:  0.06,  // exit tighter than enter
  },

  /** FlutterEmbed animation */
  flutter: {
    showDuration: 0.4,  // opacity fade (no y-slide)
    hideDuration: 0.3,
  },
} as const

/** Device quality tier detection */
export type QualityTier = 'high' | 'low'

export function detectQualityTier(): QualityTier {
  const memory = (navigator as any).deviceMemory
  const cores = navigator.hardwareConcurrency
  const isMobile = window.matchMedia('(hover: none)').matches

  if (isMobile) return 'low'
  if (memory && memory < 4) return 'low'
  if (cores && cores < 4) return 'low'
  return 'high'
}
