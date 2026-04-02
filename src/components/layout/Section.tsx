import { forwardRef, type ReactNode } from 'react'

interface SectionProps {
  id: string
  height: string
  children: ReactNode
  className?: string
}

export const Section = forwardRef<HTMLElement, SectionProps>(
  ({ id, height, children, className = '' }, ref) => (
    <section
      ref={ref}
      id={id}
      className={`relative w-full ${className}`}
      style={{ height }}
    >
      {children}
    </section>
  )
)

Section.displayName = 'Section'
