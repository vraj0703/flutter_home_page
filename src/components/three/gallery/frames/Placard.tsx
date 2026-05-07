/**
 * Placard — museum-style brushed-aluminum signage mounted to the wall
 * beside each project frame at hip height.
 *
 * Replaces the dim gold plate that previously sat below the artwork.
 * Spec: RAJ-172.
 *
 * Geometry: 0.55w × 0.32h × 0.018d, two bolt heads at top corners.
 * Material: brushed-aluminum PBR with a subtle emissive lift so the
 * placard catches even when off the spotlight cone.
 *
 * Per-project copy (title / role / dates / stats) is the responsibility
 * of RAJ-165..171; this component renders whatever Project.title and
 * Project.description provide today as a sensible default.
 */

import { useMemo, useEffect } from 'react'
import { Text } from '@react-three/drei'
import * as THREE from 'three'
import { type Project } from '../../../../config/projects'
import { useFrameSize } from '../utils'
import { FRAME_BORDER, FRAME_Y } from '../dimensions'

const PLACARD_W = 0.55
const PLACARD_H = 0.32
const PLACARD_D = 0.018
const BOLT_R = 0.012
/** Hip height for a viewer at standing eye-level (FRAME_Y is the frame
 *  center; subtracting 0.6 puts the placard about 60cm below it). */
const PLACARD_Y_OFFSET = -0.6
/** Gap between frame outer edge and placard inner edge. */
const PLACARD_GAP = 0.18
/** Mat-line width inside the frame (must match WallFrame's `mw`). */
const MAT_W = 0.12

/** Desaturate an RGB color toward gray by `t` ∈ [0,1]. */
function desaturate(hex: string, t: number): string {
  const c = new THREE.Color(hex)
  const hsl = { h: 0, s: 0, l: 0 }
  c.getHSL(hsl)
  c.setHSL(hsl.h, hsl.s * (1 - t), hsl.l)
  return `#${c.getHexString()}`
}

export function Placard({ project, side }: { project: Project; side: 'left' | 'right' }) {
  const frame = useFrameSize()

  // Placard sits beside the frame. We mount it on the corridor-facing side
  // of each frame: the offset is along the parent's local +X for left-wall
  // frames and -X for right-wall frames. Both end up further along the
  // corridor (toward the back wall), giving a consistent "read left→right
  // as you walk in" direction.
  const dx = (side === 'left' ? 1 : -1) * (
    (frame.w + FRAME_BORDER * 2 + MAT_W * 2) / 2 +
    PLACARD_GAP +
    PLACARD_W / 2
  )
  // FRAME_Y is the frame *center* in world space, but the parent group's
  // origin is also at FRAME_Y (see WallFrame position). So the placard's
  // y offset relative to the parent is just PLACARD_Y_OFFSET; we don't add
  // FRAME_Y here.
  void FRAME_Y // referenced for documentation; not needed in math

  // Brushed-aluminum PBR. Slight emissive so the placard reads in shadow.
  const placardMat = useMemo(
    () => new THREE.MeshStandardMaterial({
      color: '#9CA09F',
      roughness: 0.45,
      metalness: 0.85,
      emissive: '#5A5854',
      emissiveIntensity: 0.06,
    }),
    [],
  )

  // Bezel — slightly darker, sharper. Gives the placard an "engraved" rim.
  const bezelMat = useMemo(
    () => new THREE.MeshStandardMaterial({
      color: '#5A5C5B',
      roughness: 0.35,
      metalness: 0.9,
    }),
    [],
  )

  // Bolt heads — mounting realism cue.
  const boltMat = useMemo(
    () => new THREE.MeshStandardMaterial({
      color: '#3A3937',
      roughness: 0.55,
      metalness: 0.85,
    }),
    [],
  )

  useEffect(() => () => {
    placardMat.dispose()
    bezelMat.dispose()
    boltMat.dispose()
  }, [placardMat, bezelMat, boltMat])

  const statsColor = useMemo(
    () => desaturate(project.colors[0], 0.5),
    [project.colors],
  )

  const titleY = PLACARD_H / 2 - 0.07
  const subtitleY = titleY - 0.10
  const statsY = -PLACARD_H / 2 + 0.06
  const boltX = PLACARD_W / 2 - 0.035
  const boltY = PLACARD_H / 2 - 0.035

  return (
    <group position={[dx, PLACARD_Y_OFFSET, 0]}>
      {/* Bezel (slightly larger, behind) */}
      <mesh position={[0, 0, -0.001]} material={bezelMat}>
        <boxGeometry args={[PLACARD_W + 0.02, PLACARD_H + 0.02, PLACARD_D]} />
      </mesh>
      {/* Front face */}
      <mesh material={placardMat}>
        <boxGeometry args={[PLACARD_W, PLACARD_H, PLACARD_D + 0.002]} />
      </mesh>
      {/* Bolts — top corners */}
      <mesh position={[-boltX, boltY, PLACARD_D / 2 + 0.002]} material={boltMat}>
        <cylinderGeometry args={[BOLT_R, BOLT_R, 0.005, 12]} />
      </mesh>
      <mesh position={[boltX, boltY, PLACARD_D / 2 + 0.002]} material={boltMat}>
        <cylinderGeometry args={[BOLT_R, BOLT_R, 0.005, 12]} />
      </mesh>
      {/* Title — serif, cream */}
      <Text
        position={[0, titleY, PLACARD_D / 2 + 0.005]}
        fontSize={0.085}
        color="#F0EAD6"
        anchorX="center"
        anchorY="top"
        letterSpacing={0}
        maxWidth={PLACARD_W - 0.04}
      >
        {project.title}
      </Text>
      {/* Description / role line — muted */}
      <Text
        position={[0, subtitleY, PLACARD_D / 2 + 0.005]}
        fontSize={0.045}
        color="#B8AC95"
        anchorX="center"
        anchorY="top"
        letterSpacing={0.02}
        maxWidth={PLACARD_W - 0.04}
      >
        {project.description}
      </Text>
      {/* Stats — single line, accent-tinted */}
      <Text
        position={[0, statsY, PLACARD_D / 2 + 0.005]}
        fontSize={0.038}
        color={statsColor}
        anchorX="center"
        anchorY="bottom"
        letterSpacing={0.04}
        maxWidth={PLACARD_W - 0.04}
      >
        {project.stats.join(' · ')}
      </Text>
    </group>
  )
}
