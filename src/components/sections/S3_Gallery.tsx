import { useEffect, useState, useCallback } from 'react'
import { GalleryScene } from '../three/GalleryScene'
import { subscribeCTAClick, subscribeBackClick, subscribeConnectClick } from '../three/gallery/galleryStore'
import { RecommendationOverlay } from '../ui/RecommendationOverlay'
import type { Testimonial } from '../../config/testimonials'

interface Props {
  onNavigateToContact?: () => void
  onNavigateBack?: () => void
}

export function S3_Gallery({ onNavigateToContact, onNavigateBack }: Props) {
  const [recOpen, setRecOpen] = useState(false)

  useEffect(() => subscribeCTAClick(() => setRecOpen(true)), [])
  useEffect(() => subscribeBackClick(() => onNavigateBack?.()), [onNavigateBack])
  useEffect(() => subscribeConnectClick(() => onNavigateToContact?.()), [onNavigateToContact])

  const handleRecSubmit = useCallback((_t: Testimonial) => {}, [])

  return (
    <div style={{ width: '100%', height: '100%', position: 'relative', userSelect: 'none' }}>
      <GalleryScene />
      <RecommendationOverlay open={recOpen} onClose={() => setRecOpen(false)} onSubmit={handleRecSubmit} />
    </div>
  )
}
