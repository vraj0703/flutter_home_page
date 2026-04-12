import { useRef, useMemo, useEffect } from 'react'
import { useFrame, useThree } from '@react-three/fiber'
import type { Group, ShaderMaterial } from 'three'
import logoVert from '../../shaders/logo.vert?raw'
import lineFrag from '../../shaders/bouncyLine.frag?raw'

// Spring simulation
function springStep(
  pos: number, target: number, vel: number,
  mass: number, stiffness: number, damping: number, dt: number
): [number, number] {
  const force = -stiffness * (pos - target) - damping * vel
  const accel = force / mass
  const nv = vel + accel * dt
  return [pos + nv * dt, nv]
}

import { MOTION } from '../../config/motion'
import { prefersReducedMotion } from '../../hooks/useReducedMotion'

const SP = MOTION.bouncyLines
const H_THRESHOLD = 300 // px
const V_THRESHOLD = 150 // px

interface BouncyLinesProps {
  visible: boolean
  logoScale: number
}

// Single line data
interface LineState {
  displacement: number
  velocity: number
}

export function BouncyLines({ visible, logoScale }: BouncyLinesProps) {
  const groupRef = useRef<Group>(null)
  const matRefs = useRef<(ShaderMaterial | null)[]>([null, null, null, null])
  const { size } = useThree()

  // 4 lines: right, left, top, bottom
  const states = useRef<LineState[]>([
    { displacement: 0, velocity: 0 },
    { displacement: 0, velocity: 0 },
    { displacement: 0, velocity: 0 },
    { displacement: 0, velocity: 0 },
  ])

  const opacityRef = useRef(visible ? 1 : 0)

  const lineUniforms = useMemo(() =>
    Array.from({ length: 4 }, () => ({
      uColor: { value: [0.78, 0.557, 0.325] }, // #C78E53
      uOpacity: { value: 1.0 },
    })), [])

  // Line dimensions in world units (at FOV 45, Z=5)
  const lineLength = 0.2 // ~80px
  const lineThickness = 0.006 // ~2.5px
  const gap = 0.28 // gap from logo edge

  useFrame(({ pointer }, delta) => {
    if (!groupRef.current) return
    // Accessibility: freeze lines when reduced motion is preferred
    if (prefersReducedMotion()) return
    const dt = Math.min(delta, 1 / 30)

    // Fade opacity
    const targetOpacity = visible ? 1 : 0
    opacityRef.current += (targetOpacity - opacityRef.current) * 0.08

    // Cursor in pixels from center
    const cursorPx = pointer.x * size.width * 0.5
    const cursorPy = pointer.y * size.height * 0.5

    // Proportional displacement
    const hProp = Math.max(-1, Math.min(1, cursorPx / H_THRESHOLD))
    const vProp = Math.max(-1, Math.min(1, cursorPy / V_THRESHOLD))

    const maxDisp = 0.08 // world units

    // Targets: right/left respond to vertical cursor, top/bottom to horizontal
    const targets = [
      vProp * maxDisp,  // right line: vertical displacement
      -vProp * maxDisp, // left line: opposite
      hProp * maxDisp,  // top line: horizontal displacement
      -hProp * maxDisp, // bottom line: opposite
    ]

    // Spring integrate each line
    const s = states.current
    for (let i = 0; i < 4; i++) {
      ;[s[i].displacement, s[i].velocity] = springStep(
        s[i].displacement, targets[i], s[i].velocity,
        SP.mass, SP.stiffness, SP.damping, dt
      )

      // Update material opacity
      const mat = matRefs.current[i]
      if (mat) {
        mat.uniforms.uOpacity.value = opacityRef.current
      }
    }

    // Position lines based on current logo scale
    const sc = logoScale * 0.4 // approximate half-size in world
    const children = groupRef.current.children

    // Right line (horizontal, offset right)
    if (children[0]) {
      children[0].position.set(sc + gap, s[0].displacement, 0)
    }
    // Left line (horizontal, offset left)
    if (children[1]) {
      children[1].position.set(-(sc + gap), s[1].displacement, 0)
      children[1].rotation.z = Math.PI
    }
    // Top line (vertical, offset top)
    if (children[2]) {
      children[2].position.set(s[2].displacement, sc * 0.8 + gap, 0)
      children[2].rotation.z = Math.PI / 2
    }
    // Bottom line (vertical, offset bottom)
    if (children[3]) {
      children[3].position.set(s[3].displacement, -(sc * 0.8 + gap), 0)
      children[3].rotation.z = -Math.PI / 2
    }
  })

  return (
    <group ref={groupRef} position={[0, 0.2, 0.1]}>
      {[0, 1, 2, 3].map((i) => (
        <mesh key={i}>
          <planeGeometry args={[lineLength, lineThickness]} />
          <shaderMaterial
            ref={(el) => { matRefs.current[i] = el }}
            vertexShader={logoVert}
            fragmentShader={lineFrag}
            uniforms={lineUniforms[i]}
            transparent
            depthWrite={false}
          />
        </mesh>
      ))}
    </group>
  )
}
