import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text } from '@react-three/drei'
import * as THREE from 'three'
import { type Project } from '../../../../config/projects'
import { trackProjectClicked } from '../../../../analytics/posthog'
import { getAudioEngine } from '../../../../audio'
import { FRAME_DEPTH, FRAME_BORDER } from '../dimensions'
import { damp, tmpVec3, useFrameSize } from '../utils'
import { type useMaterials } from '../materials'
import { useProjectTexture } from '../textures'
import { getScrollProgress, setClickTarget } from '../galleryStore'

export function WallFrame({ project, position, side, projectIndex, mats }: {
  project: Project; position: [number, number, number]; side: 'left' | 'right'; projectIndex: number; mats: ReturnType<typeof useMaterials>
}) {
  const tex = useProjectTexture(project)
  const artMat = useMemo(() => new THREE.MeshStandardMaterial({ map: tex, roughness: 0.5, metalness: 0, emissive: '#ffffff', emissiveMap: tex, emissiveIntensity: 0.08 }), [tex])
  const grp = useRef<THREE.Group>(null), hov = useRef(false), pop = useRef(0)
  const glowRef = useRef<THREE.Mesh>(null)
  const entry = useRef({ t: -1, delay: projectIndex * 0.15 })
  const frame = useFrameSize(), rotY = side === 'left' ? Math.PI / 2 : -Math.PI / 2
  const labelY = -(frame.h / 2 + FRAME_BORDER + 0.35), mw = 0.12
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0, transparent: true, opacity: 0,
    roughness: 0.2, metalness: 0.4, side: THREE.BackSide,
  }), [])

  useEffect(() => () => { artMat.dispose(); glowMat.dispose() }, [artMat, glowMat])

  useFrame(({ camera }, delta) => {
    if (!grp.current) return
    const t = hov.current ? 0.08 : 0; pop.current = damp(pop.current, t, 10, delta); grp.current.position.z = pop.current
    // Entry settle — one-shot damped scale pulse when gallery first entered
    if (entry.current.t < 0 && getScrollProgress() > 0.001) entry.current.t = 0
    if (entry.current.t >= 0 && entry.current.t < entry.current.delay + 2) {
      entry.current.t += delta
      const localT = entry.current.t - entry.current.delay
      if (localT > 0 && localT < 2) {
        grp.current.scale.setScalar(1 + Math.sin(localT * 4) * 0.06 * Math.exp(-localT * 2.0))
      } else if (localT >= 2) {
        grp.current.scale.setScalar(1)
      }
    }
    // Proximity glow — subtle emissive border when camera is within 8 units
    if (glowRef.current) {
      grp.current.getWorldPosition(tmpVec3)
      const dist = camera.position.distanceTo(tmpVec3)
      const proximity = Math.max(0, 1 - dist / 8) // 0 at 8+ units, 1 at 0
      const targetGlow = (hov.current ? 0.6 : proximity * 0.25)
      const targetOpacity = (hov.current ? 0.4 : proximity * 0.15)
      glowMat.emissiveIntensity = damp(glowMat.emissiveIntensity, targetGlow, 10, delta)
      glowMat.opacity = damp(glowMat.opacity, targetOpacity, 10, delta)
    }
  })
  return (
    <group position={position} rotation={[0, rotY, 0]}>
      <group ref={grp}>
        <mesh onClick={() => { setClickTarget(projectIndex); trackProjectClicked(project.id, project.title); getAudioEngine()?.playShutterClick() }} onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer'; getAudioEngine()?.playHoverPing() }} onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }} material={mats.frameOuter}><boxGeometry args={[frame.w + FRAME_BORDER * 2 + mw * 2, frame.h + FRAME_BORDER * 2 + mw * 2, FRAME_DEPTH]} /></mesh>
        {/* Proximity glow border */}
        <mesh ref={glowRef} material={glowMat}><boxGeometry args={[frame.w + FRAME_BORDER * 2 + mw * 2 + 0.08, frame.h + FRAME_BORDER * 2 + mw * 2 + 0.08, FRAME_DEPTH + 0.04]} /></mesh>
        <mesh position={[0, 0, 0.01]} material={mats.frameInner}><boxGeometry args={[frame.w + mw * 2 + 0.02, frame.h + mw * 2 + 0.02, FRAME_DEPTH - 0.02]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 - 0.01]} material={mats.mat}><planeGeometry args={[frame.w + mw * 2, frame.h + mw * 2]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.001]} material={mats.artBg}><planeGeometry args={[frame.w, frame.h]} /></mesh>
        <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.005]} material={artMat}><planeGeometry args={[frame.w, frame.h]} /></mesh>
        <group position={[0, labelY + 0.05, FRAME_DEPTH / 2]}>
          <mesh position={[0, -0.08, 0]}><planeGeometry args={[1.2, 0.35]} /><meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.6} /></mesh>
          <Text position={[0, 0, 0.005]} fontSize={0.1} color="#2A2420" anchorX="center" anchorY="top" letterSpacing={-0.01}>{project.title}</Text>
          <Text position={[0, -0.16, 0.005]} fontSize={0.055} color="#5C4A30" anchorX="center" anchorY="top" letterSpacing={0.04}>{project.description}</Text>
        </group>
      </group>
    </group>
  )
}
