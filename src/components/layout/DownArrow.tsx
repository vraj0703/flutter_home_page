export function DownArrow({ visible }: { visible: boolean }) {
  return (
    <div
      className={`absolute bottom-10 left-1/2 -translate-x-1/2 z-20 transition-all duration-1000 ${
        visible ? 'opacity-40' : 'opacity-0 pointer-events-none'
      }`}
    >
      <svg
        width="20"
        height="20"
        viewBox="0 0 24 24"
        fill="none"
        stroke="#C8A45C"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="animate-bounce"
      >
        <path d="M12 5v14M19 12l-7 7-7-7" />
      </svg>
    </div>
  )
}
