import { FRAME_Y, FRAME_MAX_H, FRAME_BORDER } from '../dimensions'

export function TubeLight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
  const fy = FRAME_Y + FRAME_MAX_H / 2 + FRAME_BORDER + 0.3
  const tubeLen = 1.8
  const tubeR = 0.025
  const o = side === 'left' ? 1 : -1
  return (
    <group position={[position[0], fy, position[2]]}>
      {/* Mounting bracket */}
      <mesh position={[0, 0.04, 0]}>
        <boxGeometry args={[0.03, 0.02, tubeLen * 0.6]} />
        <meshStandardMaterial color="#888" roughness={0.4} metalness={0.6} />
      </mesh>
      {/* Glowing tube — emissive only, no spotlight */}
      <mesh position={[o * 0.08, 0, 0]} rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[tubeR, tubeR, tubeLen, 12]} />
        <meshStandardMaterial color="#FFF5E6" emissive="#FFE0B0" emissiveIntensity={3.0} roughness={0.2} metalness={0} />
      </mesh>
    </group>
  )
}
