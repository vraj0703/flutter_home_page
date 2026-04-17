import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useScroll } from '@react-three/drei'

import {
  isScrollAnimating,
  isKbFocused,
  requestScrollUnlock,
  requestGateRelease,
  setScrollContainer,
} from '../galleryStore'

/* ── Reverse scroll direction — scroll up = walk forward into gallery ── */
export function ReverseScroll() {
  const scroll = useScroll()
  const attached = useRef(false)
  // Wheel force accumulator for gate release — resets on backward/stop
  const forwardForce = useRef(0)
  const lastWheelTime = useRef(0)

  useFrame(() => {
    if (attached.current || !scroll.el) return
    attached.current = true
    const el = scroll.el
    setScrollContainer(el)

    el.addEventListener('wheel', (e: WheelEvent) => {
      e.preventDefault()

      // Decay accumulator if wheel has been idle > 250ms
      const now = performance.now()
      if (now - lastWheelTime.current > 250) {
        forwardForce.current = 0
      }
      lastWheelTime.current = now

      if (isScrollAnimating()) return

      if (isKbFocused()) {
        if (e.deltaY > 0) {
          requestScrollUnlock()
        } else {
          const range = el.scrollHeight - el.clientHeight
          if (range > 0) el.scrollTop = range * 0.97
        }
        return
      }

      // Check gate state BEFORE moving scroll
      const range = el.scrollHeight - el.clientHeight
      if (range > 0) {
        const currentFrac = el.scrollTop / range
        // If we're at/near the gate and user is pushing forward, accumulate force
        if (currentFrac >= 0.855 && e.deltaY < 0) {
          forwardForce.current += Math.abs(e.deltaY)
          // Release threshold: 400 units of wheel force (~4 clicks of 100)
          if (forwardForce.current > 400) {
            forwardForce.current = 0
            requestGateRelease()
          }
          // Block the scroll movement — clamp to gate
          el.scrollTop = range * 0.86
          return
        }
        // Reset accumulator on backward scroll
        if (e.deltaY > 0) {
          forwardForce.current = 0
        }
      }

      // Normal scroll (reversed): wheel down (deltaY>0) = walk backward
      el.scrollTop -= e.deltaY
    }, { passive: false })
  })

  return null
}
