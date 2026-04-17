import { Text } from '@react-three/drei'
import { FRAME_DEPTH, FRAME_BORDER } from '../dimensions'
import { useFrameSize } from '../utils'
import { type useMaterials } from '../materials'
import { type Testimonial } from '../../../../config/testimonials'
import { fireCTAClick } from '../galleryStore'

export function TestimonialFrame({ testimonial, position, mats }: {
  testimonial: Testimonial; position: [number, number, number]; mats: ReturnType<typeof useMaterials>
}) {
  const frame = useFrameSize()
  const fw = Math.min(frame.w, 3.2), fh = Math.min(frame.h, 2.8)
  const mw = 0.10
  const isCTA = !!testimonial.isCTA

  return (
    <group position={position}>
      <mesh material={mats.frameOuter}>
        <boxGeometry args={[fw + FRAME_BORDER * 2 + mw * 2, fh + FRAME_BORDER * 2 + mw * 2, FRAME_DEPTH]} />
      </mesh>
      <mesh position={[0, 0, 0.01]} material={mats.frameInner}>
        <boxGeometry args={[fw + mw * 2 + 0.02, fh + mw * 2 + 0.02, FRAME_DEPTH - 0.02]} />
      </mesh>
      <mesh position={[0, 0, FRAME_DEPTH / 2 - 0.01]} material={mats.mat}>
        <planeGeometry args={[fw + mw * 2, fh + mw * 2]} />
      </mesh>
      <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.001]}>
        <planeGeometry args={[fw, fh]} />
        <meshStandardMaterial color={isCTA ? '#2A2420' : '#F5F0E8'} emissive={isCTA ? '#2A2420' : '#F5F0E8'} emissiveIntensity={0.05} roughness={0.9} />
      </mesh>

      {isCTA ? (
        /* ── CTA card: "Recommend Vishal" ── */
        <group>
          <Text position={[0, 0.5, FRAME_DEPTH / 2 + 0.005]} fontSize={0.18} color="#C8A45C" anchorX="center" anchorY="middle" font="/fonts/modrnt_urban.otf">
            Recommend Vishal
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.085} color="#A09880" anchorX="center" anchorY="middle" maxWidth={fw - 0.6} lineHeight={1.6}>
            Share your experience working together
          </Text>
          <mesh position={[0, -0.4, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.4, 0.003]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -0.7, FRAME_DEPTH / 2 + 0.005]} fontSize={0.07} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.12} font="/fonts/inconsolata_nerd_mono_regular.ttf">
            CLICK TO WRITE
          </Text>
          {/* Invisible click target */}
          <mesh position={[0, 0, FRAME_DEPTH / 2 + 0.01]} onClick={() => fireCTAClick()}>
            <planeGeometry args={[fw, fh]} />
            <meshBasicMaterial transparent opacity={0} />
          </mesh>
        </group>
      ) : (
        /* ── Regular testimonial card ── */
        <group>
          <Text position={[-fw / 2 + 0.2, fh / 2 - 0.25, FRAME_DEPTH / 2 + 0.005]} fontSize={0.4} color="#C8A45C" anchorX="left" anchorY="top" font="/fonts/poseidon.otf">
            "
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" maxWidth={fw - 0.5} lineHeight={1.7}>
            {testimonial.text}
          </Text>
          <mesh position={[0, -fh / 2 + 0.7, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.5, 0.004]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -fh / 2 + 0.48, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" font="/fonts/modrnt_urban.otf">
            {testimonial.name}
          </Text>
          <Text position={[0, -fh / 2 + 0.28, FRAME_DEPTH / 2 + 0.005]} fontSize={0.055} color="#9A8A6E" anchorX="center" anchorY="middle" letterSpacing={0.08} font="/fonts/inconsolata_nerd_mono_regular.ttf">
            {testimonial.role} · {testimonial.company}
          </Text>
        </group>
      )}

      <group position={[0, -(fh / 2 + FRAME_BORDER + 0.25), FRAME_DEPTH / 2]}>
        <mesh position={[0, -0.05, 0]}>
          <planeGeometry args={[1.0, 0.25]} />
          <meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.6} />
        </mesh>
        <Text position={[0, 0, 0.005]} fontSize={0.06} color="#2A2420" anchorX="center" anchorY="middle" letterSpacing={0.1} font="/fonts/inconsolata_nerd_mono_regular.ttf">
          {isCTA ? 'RECOMMEND' : 'TESTIMONIAL'}
        </Text>
      </group>
    </group>
  )
}
