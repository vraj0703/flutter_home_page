import { useRef, useState, useMemo, useCallback } from 'react'
import { useFrame } from '@react-three/fiber'
import { Text, RoundedBox } from '@react-three/drei'
import * as THREE from 'three'
import { SKILLS, type Skill } from '../../config/skills'
import { getAudioEngine } from '../../audio'
import { isKbVisible, isReducedMotion } from './gallery/galleryStore'
import { bootState, BOOT_DURATION, BOOT_FLASH_DURATION } from './gallery/keyboardStore'

/* ── Keyboard dimensions ──────────────────────────────────── */
const KEY_UNIT = 0.9
const KEY_H = 0.35
const KEY_GAP = 0.1
const KEY_STEP = KEY_UNIT + KEY_GAP
const BOARD_PAD = 0.5
const BOARD_H = 0.18
const ROW_STAGGER = [0, 0.15, 0.3, 0.1]

/* ── Boot state ────────────────────────────────────────────
   Moved out of module-level let bindings into ./gallery/keyboardStore so
   the state file-of-record is explicit. Consumers read/write bootState.*
   directly from their useFrame callbacks — per-frame getter calls would
   be wasted overhead for a mutable cache. CameraRig imports resetBoot
   from the store directly; this file no longer re-exports it.
*/

function backOut(t: number): number {
  const s = 1.70158
  const t1 = t - 1
  return 1 + t1 * t1 * ((s + 1) * t1 + s)
}

/* ── Category row tint colors ────────────────────────────── */
const ROW_TINTS: [number, number, number][] = [
  [0.15, 0.25, 0.6],   // Row 0 Languages: blue
  [0.1, 0.5, 0.2],     // Row 1 Frameworks: green
  [0.6, 0.35, 0.1],    // Row 2 Tools: orange
  [0.4, 0.15, 0.55],   // Row 3 AI/Platforms: purple
]

/* ── RGB wave: sweeps diagonally across the keyboard ──────── */
function rgbWave(t: number, x: number, z: number): [number, number, number] {
  const phase = t * 2.2 - x * 0.4 + z * 0.25
  return [
    0.5 + 0.5 * Math.sin(phase),
    0.5 + 0.5 * Math.sin(phase + Math.PI * 2 / 3),
    0.5 + 0.5 * Math.sin(phase - Math.PI * 2 / 3),
  ]
}

/* ── Skill display names for tooltip ─────────────────────── */
const SKILL_DISPLAY_NAMES: Record<string, string> = {
  dart: 'Dart', typescript: 'TypeScript', javascript: 'JavaScript',
  python: 'Python', glsl: 'GLSL Shaders', sql: 'SQL', html: 'HTML5', css: 'CSS3',
  flutter: 'Flutter', react: 'React', threejs: 'Three.js', nodejs: 'Node.js',
  gsap: 'GSAP', tailwind: 'Tailwind CSS', vite: 'Vite',
  git: 'Git', docker: 'Docker', postgres: 'PostgreSQL',
  firebase: 'Firebase', linux: 'Linux', figma: 'Figma',
  claude: 'Claude AI', ollama: 'Ollama', tailscale: 'Tailscale',
  cloudflare: 'Cloudflare', rpi: 'Raspberry Pi',
}

/* ── Single keycap with boot-up power-on ──────────────────── */
function Keycap({ skill, position, bootDelay, rowIdx }: {
  skill: Skill
  position: [number, number, number]
  bootDelay: number
  rowIdx: number
}) {
  const groupRef = useRef<THREE.Group>(null)
  const capRef = useRef<THREE.Mesh>(null)
  const [hovered, setHovered] = useState(false)
  const pressY = useRef(0)
  const baseY = position[1]
  const tint = ROW_TINTS[rowIdx] || ROW_TINTS[0]

  useFrame(({ clock }, delta) => {
    if (!capRef.current) return
    // Early-out while the keyboard is parked below the scene. Skips per-keycap
    // trig (rgbWave, hover spring) × 27 keys that the user can't see anyway.
    if (!isKbVisible()) return
    const dt = Math.min(delta, 0.05)
    const t = clock.elapsedTime
    // Reduced motion: freeze the rgb wave to a static phase. We use t=0
    // rather than the live clock so every key shares the same deterministic
    // color with no motion between frames. Hover/press remain active —
    // those are interaction feedback, not ambient motion.
    const waveT = isReducedMotion() ? 0 : t
    const [r, g, b] = rgbWave(waveT, position[0], position[2])

    // Power-on: each key lights up based on boot delay
    const localBoot = Math.max(0, Math.min(1, (bootState.phase * BOOT_DURATION - bootDelay) / 0.3))

    // Boot flash: bright pulse when wave completes
    let flashMult = 0
    if (bootState.flashTime > 0) {
      const flashElapsed = t - bootState.flashTime
      if (flashElapsed >= 0 && flashElapsed < BOOT_FLASH_DURATION) {
        flashMult = 1.0 - (flashElapsed / BOOT_FLASH_DURATION)
        flashMult = flashMult * flashMult // quadratic falloff
      }
    }

    const capMat = capRef.current.material as THREE.MeshPhysicalMaterial
    if (hovered && localBoot >= 1) {
      capMat.emissive.setRGB(r * 1.5, g * 1.5, b * 1.5)
      capMat.emissiveIntensity = 2.5
    } else {
      const mult = 0.15 * localBoot
      const tr = (r * 0.6 + tint[0] * 0.4) * mult + flashMult * 0.8
      const tg = (g * 0.6 + tint[1] * 0.4) * mult + flashMult * 0.8
      const tb = (b * 0.6 + tint[2] * 0.4) * mult + flashMult * 0.8
      capMat.emissive.setRGB(tr, tg, tb)
      capMat.emissiveIntensity = localBoot * 1.5 + flashMult * 3.0
    }

    // Spring press — frame-rate independent (was 0.12 fixed lerp → inconsistent on 60 vs 144Hz)
    const target = hovered ? -0.06 : 0
    pressY.current += (target - pressY.current) * (1 - Math.exp(-10 * dt))
    if (groupRef.current) {
      groupRef.current.position.y = baseY + pressY.current
    }
  })

  const onOver = useCallback(() => { setHovered(true); document.body.style.cursor = 'pointer'; getAudioEngine()?.playKeyClack() }, [])
  const onOut = useCallback(() => { setHovered(false); document.body.style.cursor = 'default' }, [])

  const capW = KEY_UNIT - KEY_GAP
  const capD = KEY_UNIT - KEY_GAP

  const displayName = SKILL_DISPLAY_NAMES[skill.id] || skill.id
  const tooltipWidth = Math.max(displayName.length * 0.1 + 0.4, 1.0)

  return (
    <group ref={groupRef} position={position}>
      <RoundedBox
        ref={capRef}
        args={[capW, KEY_H, capD]}
        radius={0.06}
        smoothness={4}
        onPointerOver={onOver}
        onPointerOut={onOut}
      >
        {/*
          Keycap material — stripped down from the original 8-flag Physical
          stack. Removed: transmission (was the black-flash root cause),
          iridescence/iridescenceIOR (invisible under Bloom + emissive RGB
          wave), sheen/sheenColor (gold on gold = invisible), specularIntensity
          /specularColor/reflectivity (overlapping with metalness+envMap).
          Kept: clearcoat for the wet-plastic cap shine. Result: ~30% GPU
          frame-time win on the Keycap shader pass with zero perceived loss.
        */}
        <meshPhysicalMaterial
          color={new THREE.Color(0.08 + tint[0] * 0.15, 0.10 + tint[1] * 0.15, 0.16 + tint[2] * 0.15)}
          roughness={0.15}
          metalness={0.3}
          envMapIntensity={1.5}
          clearcoat={1.0}
          clearcoatRoughness={0.05}
        />
      </RoundedBox>

      {/* Key legend — larger, bolder, with outline for contrast */}
      <Text
        position={[0, KEY_H / 2 + 0.006, 0]}
        rotation={[-Math.PI / 2, 0, 0]}
        fontSize={skill.label.length > 5 ? 0.18 : skill.label.length > 3 ? 0.22 : 0.26}
        color={hovered ? '#FFFFFF' : skill.color}
        anchorX="center"
        anchorY="middle"
        letterSpacing={-0.02}
        fontWeight={700}
      >
        {skill.label}
      </Text>

      {hovered && (
        <group position={[0, KEY_H + 0.65, 0]}>
          {/* Tooltip background */}
          <RoundedBox args={[tooltipWidth, 0.38, 0.02]} radius={0.05} smoothness={2}>
            <meshBasicMaterial color="#101018" transparent opacity={0.92} />
          </RoundedBox>
          {/* Tooltip border glow */}
          <RoundedBox args={[tooltipWidth + 0.04, 0.42, 0.015]} radius={0.06} smoothness={2}>
            <meshBasicMaterial color={skill.color} transparent opacity={0.15} />
          </RoundedBox>
          {/* Full skill name */}
          <Text position={[0, 0.04, 0.015]} fontSize={0.14} color="#F0F0F5" anchorX="center" anchorY="middle" fontWeight={600}>
            {displayName}
          </Text>
          {/* Category label */}
          <Text position={[0, -0.14, 0.015]} fontSize={0.075} color={skill.color} anchorX="center" anchorY="middle" letterSpacing={0.1}>
            {skill.category.toUpperCase()}
          </Text>
          {/* Pointer triangle (small box as indicator) */}
          <mesh position={[0, -0.22, 0.01]} rotation={[0, 0, Math.PI / 4]}>
            <boxGeometry args={[0.06, 0.06, 0.015]} />
            <meshBasicMaterial color="#101018" transparent opacity={0.92} />
          </mesh>
        </group>
      )}
    </group>
  )
}

/* ── Board case ──────────────────────────────────────────── */
function BoardCase({ width, depth }: { width: number; depth: number }) {
  const w = width + BOARD_PAD * 2
  const d = depth + BOARD_PAD * 2
  return (
    <group position={[0, -KEY_H / 2 - BOARD_H / 2 + 0.02, 0]}>
      {/* Main board body — downgraded from MeshPhysical to MeshStandard.
          Clearcoat was invisible under the keycaps anyway; reflectivity is
          implicit in metalness. Saves ~3× the fragment-shader cost. */}
      <RoundedBox args={[w, BOARD_H, d]} radius={0.1} smoothness={4} receiveShadow>
        <meshStandardMaterial
          color="#8A7040"
          roughness={0.2}
          metalness={0.7}
          envMapIntensity={1.5}
        />
      </RoundedBox>
      {/* Top plate — same material downgrade. Visible only as a thin rim;
          the clearcoat pass had no perceptible contribution there. */}
      <RoundedBox args={[w + 0.04, 0.03, d + 0.04]} radius={0.08} smoothness={3} position={[0, BOARD_H / 2, 0]}>
        <meshStandardMaterial
          color="#A08050"
          roughness={0.15}
          metalness={0.8}
          envMapIntensity={2.0}
        />
      </RoundedBox>
      {/* Crystal edge accent glow */}
      <mesh position={[0, BOARD_H / 2 + 0.018, 0]}>
        <boxGeometry args={[w - 0.1, 0.005, d - 0.1]} />
        <meshBasicMaterial color="#ffffff" transparent opacity={0.04} />
      </mesh>
    </group>
  )
}

/* ── LED underglow — fades in with boot ──────────────────── */
function Underglow({ width, depth }: { width: number; depth: number }) {
  const ref = useRef<THREE.Mesh>(null)
  const w = width + BOARD_PAD * 2 + 0.2
  const d = depth + BOARD_PAD * 2 + 0.2

  useFrame(({ clock }) => {
    if (!ref.current) return
    // Skip RGB wave recompute while the keyboard is hidden below scene.
    if (!isKbVisible()) return
    // Reduced motion: freeze wave phase (static color, no strobe).
    const t = isReducedMotion() ? 0 : clock.elapsedTime
    const [r, g, b] = rgbWave(t, 0, 0)
    const mat = ref.current.material as THREE.MeshBasicMaterial
    mat.color.setRGB(r, g, b)
    // Fade in with boot phase
    const bootOpacity = Math.max(0, (bootState.phase - 0.3) / 0.7) // starts fading in at 30% boot
    mat.opacity = 0.15 * bootOpacity
  })

  return (
    <mesh ref={ref} position={[0, -KEY_H / 2 - BOARD_H + 0.01, 0]} rotation={[-Math.PI / 2, 0, 0]}>
      <planeGeometry args={[w, d]} />
      <meshBasicMaterial color="#ff0000" transparent opacity={0} />
    </mesh>
  )
}

/* ── Category label ──────────────────────────────────────── */
function RowLabel({ position, label, color }: { position: [number, number, number]; label: string; color: string }) {
  return (
    <group position={position}>
      <Text rotation={[-Math.PI / 2, 0, 0]} fontSize={0.08} color={color} anchorX="right" anchorY="middle" letterSpacing={0.12}>
        {label}
      </Text>
    </group>
  )
}

/* ── Particles ───────────────────────────────────────────── */
export function Particles({ count = 40 }: { count?: number }) {
  const ref = useRef<THREE.InstancedMesh>(null)
  const dummy = useMemo(() => new THREE.Object3D(), [])
  const data = useMemo(() =>
    Array.from({ length: count }, () => ({
      x: (Math.random() - 0.5) * 12, y: Math.random() * 4 - 0.5, z: (Math.random() - 0.5) * 8,
      s: 0.003 + Math.random() * 0.006, speed: 0.01 + Math.random() * 0.03, phase: Math.random() * Math.PI * 2,
    })),
  [count])

  // Track whether we've painted the reduced-motion static snapshot once.
  // After one write nothing changes per frame, so subsequent frames skip.
  const rmSnapshotDone = useRef(false)

  useFrame(({ clock }) => {
    if (!ref.current) return
    // No point updating 40 instance matrices while the particles cluster
    // sits below the floor with the rest of the keyboard room.
    if (!isKbVisible()) return
    // Reduced motion: paint a single static snapshot of all particles at
    // their base positions, then stop writing — no drift, no waste.
    if (isReducedMotion()) {
      if (rmSnapshotDone.current) return
      data.forEach((p, i) => {
        dummy.position.set(p.x, p.y, p.z)
        dummy.scale.setScalar(p.s)
        dummy.updateMatrix()
        ref.current!.setMatrixAt(i, dummy.matrix)
      })
      ref.current.instanceMatrix.needsUpdate = true
      rmSnapshotDone.current = true
      return
    }
    // Normal path: drift each particle every frame.
    rmSnapshotDone.current = false
    const t = clock.elapsedTime
    data.forEach((p, i) => {
      dummy.position.set(
        p.x + Math.sin(t * p.speed + p.phase) * 0.5,
        p.y + Math.sin(t * p.speed * 0.7 + p.phase) * 0.3,
        p.z + Math.cos(t * p.speed * 0.5 + p.phase) * 0.4,
      )
      dummy.scale.setScalar(p.s + Math.sin(t + i) * 0.002)
      dummy.updateMatrix()
      ref.current!.setMatrixAt(i, dummy.matrix)
    })
    ref.current.instanceMatrix.needsUpdate = true
  })

  return (
    <instancedMesh ref={ref} args={[undefined, undefined, count]}>
      <sphereGeometry args={[1, 6, 6]} />
      <meshBasicMaterial color="#C8A45C" transparent opacity={0.15} />
    </instancedMesh>
  )
}

/* ── Full keyboard assembly with boot-up entrance ─────────── */
const CATEGORY_LABELS = ['LANGUAGES', 'FRAMEWORKS', 'TOOLS', 'PLATFORMS']
const CATEGORY_COLORS = ['#E8C97A', '#C8A45C', '#D4A055', '#B8956A']

// Final positions
const FINAL_POS = new THREE.Vector3(0, -0.3, 0.5)
const FINAL_ROT = new THREE.Euler(0.35, 0, 0)
// Start positions (below + tilted back)
const START_POS = new THREE.Vector3(0, -2.5, 2.0)
const START_ROT = new THREE.Euler(0.6, 0, 0)

export function Keyboard() {
  const groupRef = useRef<THREE.Group>(null)
  const maxCols = Math.max(...SKILLS.map(r => r.length))
  const totalWidth = maxCols * KEY_STEP
  const totalDepth = SKILLS.length * KEY_STEP

  const flashTriggered = useRef(false)

  // Boot-up animation: ramp bootState.phase 0→1
  useFrame(({ clock }) => {
    if (bootState.startTime < 0) bootState.startTime = clock.elapsedTime
    const elapsed = clock.elapsedTime - bootState.startTime
    bootState.phase = Math.min(1, elapsed / BOOT_DURATION)

    // Trigger flash when boot wave completes
    if (bootState.phase >= 0.95 && !flashTriggered.current) {
      flashTriggered.current = true
      bootState.flashTime = clock.elapsedTime
    }

    // Animate group position/rotation with backOut easing
    if (groupRef.current) {
      const t = backOut(Math.min(1, bootState.phase))
      groupRef.current.position.lerpVectors(START_POS, FINAL_POS, t)
      groupRef.current.rotation.x = START_ROT.x + (FINAL_ROT.x - START_ROT.x) * t
    }
  })

  return (
    <group ref={groupRef} rotation={[START_ROT.x, 0, 0]} position={[START_POS.x, START_POS.y, START_POS.z]}>
      <BoardCase width={totalWidth} depth={totalDepth} />
      <Underglow width={totalWidth} depth={totalDepth} />

      {SKILLS.map((row, rowIdx) => {
        const rowWidth = row.length * KEY_STEP
        const stagger = ROW_STAGGER[rowIdx] || 0
        const xStart = -rowWidth / 2 + KEY_STEP / 2 + stagger
        const zPos = (SKILLS.length / 2 - rowIdx - 0.5) * KEY_STEP

        return (
          <group key={`row-${rowIdx}`}>
            <RowLabel
              position={[totalWidth / 2 + BOARD_PAD - 0.1, KEY_H / 2 + 0.01, zPos]}
              label={CATEGORY_LABELS[rowIdx]}
              color={CATEGORY_COLORS[rowIdx]}
            />
            {row.map((skill, colIdx) => {
              const bootDelay = (rowIdx + colIdx) * 0.05 // faster diagonal sweep
              return (
                <Keycap
                  key={skill.id}
                  skill={skill}
                  position={[xStart + colIdx * KEY_STEP, 0, zPos]}
                  bootDelay={bootDelay}
                  rowIdx={rowIdx}
                />
              )
            })}
          </group>
        )
      })}
    </group>
  )
}

/* ── End of exports ──────────────────────────────────────────
   Prior versions of this file included a standalone <KeyboardScene />
   component plus <TitleOverlay>, <HintOverlay>, and <MuseumRoom> — a
   self-contained preview of the keyboard room. None were ever mounted;
   the gallery's FloatingKB uses <Keyboard> directly. Deleted 2026-04
   to cut dead weight. Consumers still reach <Keyboard> and <Particles>
   via the named exports above.
*/
