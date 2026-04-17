/**
 * GalleryCorridor — scene layout assembling all gallery components.
 *
 * This is the "scene graph" file: corridor geometry, project frames,
 * testimonial frames, lights, walls, keyboard room, back wall, and UI.
 */
import * as THREE from 'three'
import { Text } from '@react-three/drei'
import { LEFT_PROJECTS, RIGHT_PROJECTS } from '../../../config/projects'
import { Particles as KBParticles } from '../KeyboardScene'

import {
  CW, CH, FRAME_Y, SPACING,
  WALL_X, FLOOR_Y, CEIL_Y,
  CORRIDOR_LEN, BACK_WALL_Z, RIGHT_WALL_LEN,
  ALL_TEST_CARDS, TEST_CARDS, TEST_SPACING, TEST_START_X,
  KB_ROOM, KB_X, KB_Z, KB_ENTRY_X, KB_END_X,
} from './dimensions'

import { useMaterials } from './materials'

// Frames
import { WallFrame } from './frames/WallFrame'
import { TestimonialFrame } from './frames/TestimonialFrame'
import { TubeLight } from './frames/TubeLight'
import { FrameSpotlight } from './frames/FrameSpotlight'
import { BackWallSpotlight, TestimonialSpotlight } from './frames/Spotlights'

// UI
import { ThresholdCue } from './ui/ThresholdCue'
import { GraffitiBackButton } from './ui/GraffitiBackButton'
import { WallRadio } from './ui/WallRadio'
import { LetsConnectFrame } from './ui/LetsConnectFrame'

// Keyboard
import { FloatingKB } from './FloatingKB'

export function GalleryCorridor() {
  const mats = useMaterials()

  return (
    <group>
      {/* ── PROJECT CORRIDOR ─────────────────────────────── */}

      {/* Floor — Polished museum concrete */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[KB_X / 2, FLOOR_Y, KB_Z]}>
        <planeGeometry args={[200, 200]} />
        <meshStandardMaterial color="#8A7A62" roughness={0.85} metalness={0.05} />
      </mesh>

      {/* Ceiling — warm ceramic, bright */}
      <mesh rotation={[Math.PI / 2, 0, 0]} position={[KB_X / 2, CEIL_Y, KB_Z]}>
        <planeGeometry args={[200, 200]} />
        <meshStandardMaterial color={[0.85, 0.78, 0.72]} roughness={0.5} metalness={0.0} side={THREE.DoubleSide} />
      </mesh>

      {/* Left wall — full corridor length */}
      <mesh position={[-WALL_X, 0.5, -CORRIDOR_LEN / 2 + 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wall}>
        <planeGeometry args={[CORRIDOR_LEN + 4, CH + 2]} />
      </mesh>

      {/* Right wall — stops after 3 project pairs, creates L-opening */}
      <mesh position={[WALL_X, 0.5, (-RIGHT_WALL_LEN) / 2 + 2]} rotation={[0, -Math.PI / 2, 0]} material={mats.wall}>
        <planeGeometry args={[RIGHT_WALL_LEN, CH + 2]} />
      </mesh>

      {/* Entrance wall */}
      <group position={[0, 0, 4]}>
        <mesh material={mats.wall}><planeGeometry args={[CW, CH + 2]} /></mesh>
      </group>

      {/* Threshold cue — suspended light line at corridor entrance */}
      <ThresholdCue />

      {/* ── BACK WALL — About Me + Testimonials ────────── */}
      <mesh position={[(KB_ENTRY_X) / 2 - WALL_X, 0.5, BACK_WALL_Z]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X + CW, CH + 2]} />
      </mesh>

      {/* Front wall of testimonial wing */}
      <mesh position={[(KB_ENTRY_X + WALL_X) / 2, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X - WALL_X, CH + 2]} />
      </mesh>

      {/* About Me — center of corridor (x=0) */}
      <group position={[0, 0, BACK_WALL_Z + 0.02]}>
        <mesh position={[0, 1.8, -0.02]}>
          <planeGeometry args={[5, 1.2]} />
          <meshBasicMaterial color="#C8A45C" transparent opacity={0.02} />
        </mesh>
        <Text position={[0, 1.75, 0]} fontSize={0.8} color="#FFE0B0" anchorX="center" anchorY="bottom" letterSpacing={0.05} font="/fonts/poseidon.otf">
          VISHAL RAJ
        </Text>
        <mesh position={[0, 1.65, 0]}><planeGeometry args={[2.5, 0.003]} /><meshBasicMaterial color="#C8A45C" /></mesh>
        <Text position={[0, 1.5, 0]} fontSize={0.11} color="#C4B496" anchorX="center" anchorY="top" maxWidth={4.2} textAlign="center" lineHeight={1.5} letterSpacing={0.02} font="/flutter/assets/fonts/inconsolata_nerd_mono_regular.ttf">
          I make software that works quietly and well. For a decade, I've been building mobile apps,
          developer tools, and lately, AI systems that can think for themselves. I believe good
          engineering is invisible — you only notice it when it's missing.
        </Text>
      </group>

      {/* ── BACK WALL LIGHTING ── */}
      <BackWallSpotlight />
      <pointLight position={[TEST_START_X, CEIL_Y - 1, BACK_WALL_Z + 2]} intensity={1.0} color="#FFE8C8" distance={15} decay={2} />
      <pointLight position={[TEST_START_X + TEST_CARDS.length * TEST_SPACING / 2, CEIL_Y - 0.5, BACK_WALL_Z + 1.5]} intensity={0.8} color="#FFF0D8" distance={20} decay={2} />

      {/* Testimonial frames on the back wall */}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialFrame key={t.id} testimonial={t} position={[TEST_START_X + i * TEST_SPACING, FRAME_Y, BACK_WALL_Z + 0.08]} mats={mats} />
      ))}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialSpotlight key={`tspot-${t.id}`} x={TEST_START_X + i * TEST_SPACING} />
      ))}

      <GraffitiBackButton />
      <WallRadio />

      {/* Left wall frames */}
      {LEFT_PROJECTS.map((proj, i) => {
        const z = -(i + 1) * SPACING
        return (
          <group key={proj.id}>
            <WallFrame project={proj} position={[-WALL_X + 0.08, FRAME_Y, z]} side="left" projectIndex={i} mats={mats} />
            <TubeLight position={[-WALL_X + 0.08, CEIL_Y, z]} side="left" />
            <FrameSpotlight position={[-WALL_X + 0.08, FRAME_Y, z]} side="left" />
          </group>
        )
      })}

      {/* Right wall frames */}
      {RIGHT_PROJECTS.map((proj, i) => {
        const z = -(i + 1) * SPACING
        return (
          <group key={proj.id}>
            <WallFrame project={proj} position={[WALL_X - 0.08, FRAME_Y, z]} side="right" projectIndex={LEFT_PROJECTS.length + i} mats={mats} />
            <TubeLight position={[WALL_X - 0.08, CEIL_Y, z]} side="right" />
            <FrameSpotlight position={[WALL_X - 0.08, FRAME_Y, z]} side="right" />
          </group>
        )
      })}

      {/* ── KEYBOARD EXHIBITION HALL ── */}
      <mesh position={[KB_X, 1.5, KB_Z + KB_ROOM / 2]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_X, 1.5, KB_Z - KB_ROOM / 2]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_END_X, 1.5, KB_Z]} rotation={[0, -Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X, 1, (KB_Z + KB_ROOM / 2 + BACK_WALL_Z + CW) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X, 1, (BACK_WALL_Z + KB_Z - KB_ROOM / 2) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>

      <LetsConnectFrame />

      {/* Keyboard room fill lights */}
      <pointLight position={[KB_X, CEIL_Y - 0.5, KB_Z]} intensity={1.8} color="#FFE8C8" distance={18} decay={1.5} />
      <pointLight position={[KB_X, 1.5, KB_Z + 6]} intensity={0.8} color="#FFF0D8" distance={12} decay={2} />
      <pointLight position={[KB_X, 1.5, KB_Z - 6]} intensity={0.8} color="#FFF0D8" distance={12} decay={2} />
      <pointLight position={[KB_X - 6, 1.5, KB_Z]} intensity={0.6} color="#FFF0D8" distance={12} decay={2} />
      <pointLight position={[KB_X + 6, 1.5, KB_Z]} intensity={0.6} color="#FFF0D8" distance={12} decay={2} />

      <FloatingKB position={[KB_X, 0.6, KB_Z]} />

      <group position={[KB_X, 1.5, KB_Z]}>
        <KBParticles count={25} />
      </group>
    </group>
  )
}
