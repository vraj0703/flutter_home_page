import { useLayoutEffect, useRef, type ReactNode } from 'react'
import Lenis from 'lenis'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

gsap.registerPlugin(ScrollTrigger)

interface ScrollContainerProps {
  children: ReactNode
  onScrollBackAtTop?: () => void
}

export function ScrollContainer({ children, onScrollBackAtTop }: ScrollContainerProps) {
  const scrollBackFired = useRef(false)

  useLayoutEffect(() => {
    const lenis = new Lenis({
      lerp: 0.08,
      smoothWheel: true,
    })

    lenis.on('scroll', ScrollTrigger.update)

    // Detect scroll-back-at-top for Flutter return
    if (onScrollBackAtTop) {
      let consecutiveUpAtTop = 0

      lenis.on('scroll', ({ scroll, direction }: { scroll: number; direction: number }) => {
        if (scroll <= 2 && direction === -1) {
          consecutiveUpAtTop++
          // Require a few consecutive up-scrolls at top to avoid accidental triggers
          if (consecutiveUpAtTop >= 3 && !scrollBackFired.current) {
            scrollBackFired.current = true
            onScrollBackAtTop()
          }
        } else {
          consecutiveUpAtTop = 0
          scrollBackFired.current = false
        }
      })
    }

    const rafCallback = (time: number) => lenis.raf(time * 1000)
    gsap.ticker.add(rafCallback)
    gsap.ticker.lagSmoothing(0)

    requestAnimationFrame(() => {
      ScrollTrigger.refresh()
    })

    return () => {
      lenis.destroy()
      gsap.ticker.remove(rafCallback)
      ScrollTrigger.getAll().forEach(t => t.kill())
    }
  }, [onScrollBackAtTop])

  return <div id="scroll-container">{children}</div>
}
