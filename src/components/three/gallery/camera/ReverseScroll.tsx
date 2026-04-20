import { useRef } from 'react'
import { useFrame } from '@react-three/fiber'
import { useScroll } from '@react-three/drei'

import {
  isScrollAnimating,
  isKbFocused,
  setScrollContainer,
} from '../galleryStore'

/* ── Reverse scroll direction — scroll up = walk forward into gallery ── */
export function ReverseScroll() {
  const scroll = useScroll()
  const attached = useRef(false)

  useFrame(() => {
    if (attached.current || !scroll.el) return
    attached.current = true
    const el = scroll.el
    setScrollContainer(el)

    el.addEventListener('wheel', (e: WheelEvent) => {
      e.preventDefault()
      if (isScrollAnimating() || isKbFocused()) return
      el.scrollTop -= e.deltaY
    }, { passive: false })
  })

  return null
}
