interface SocialButtonProps {
  label: string
  href: string
  svgPath: string
  delay: number
  visible: boolean
}

export function SocialButton({ label, href, svgPath, delay, visible }: SocialButtonProps) {
  return (
    <a
      href={href}
      target={href.startsWith('mailto:') ? undefined : '_blank'}
      rel="noopener noreferrer"
      className="group flex items-center gap-3 px-5 py-3 rounded-xl transition-all duration-500"
      style={{
        border: '1px solid rgba(255,255,255,0.04)',
        background: 'rgba(26,26,31,0.5)',
        opacity: visible ? 1 : 0,
        transform: visible ? 'translateY(0)' : 'translateY(16px)',
        transition: `all 0.7s cubic-bezier(0.16, 1, 0.3, 1) ${delay}s`,
      }}
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
        className="text-text-muted group-hover:text-accent transition-colors duration-300"
        style={{ color: '#55556A' }}
      >
        <path d={svgPath} />
      </svg>
      <span style={{
        fontFamily: 'Space Grotesk, sans-serif',
        fontSize: '0.85rem',
        fontWeight: 400,
        color: '#8888A0',
        transition: 'color 0.3s',
      }}
        className="group-hover:!text-[#E8E8ED]"
      >
        {label}
      </span>
    </a>
  )
}
