/**
 * Gallery shared utilities — damp function, reusable vectors, frame size hooks.
 */
import { useMemo } from 'react'
import { useThree } from '@react-three/fiber'
import * as THREE from 'three'
import { FRAME_MAX_H, FRAME_BORDER, WALL_X, FOV_RAD, FOCUS_MARGIN } from './dimensions'

/** Reusable vector — avoid per-frame allocations */
export const tmpVec3 = new THREE.Vector3()

/**
 * Frame-rate independent exponential smoothing.
 * Replaces `value += (target - value) * CONSTANT` which is frame-rate dependent.
 */
export function damp(current: number, target: number, speed: number, delta: number): number {
  return current + (target - current) * (1 - Math.exp(-speed * delta))
}

/** Compute frame dimensions based on viewport aspect ratio */
export function useFrameSize() {
  const { size } = useThree()
  return useMemo(() => {
    const a = size.width / size.height, h = FRAME_MAX_H, w = Math.min(h * a, WALL_X - 0.8)
    return { w, h: w / a }
  }, [size.width, size.height])
}

/** Compute focus distance for click-to-zoom */
export function useFocusDistance() {
  const { size } = useThree()
  const f = useFrameSize()
  return useMemo(() => {
    const a = size.width / size.height
    const dH = ((f.h + FRAME_BORDER * 2 + 0.84) * FOCUS_MARGIN / 2) / Math.tan(FOV_RAD / 2)
    const hFov = 2 * Math.atan(Math.tan(FOV_RAD / 2) * a)
    const dW = ((f.w + FRAME_BORDER * 2 + 0.24) * FOCUS_MARGIN / 2) / Math.tan(hFov / 2)
    return Math.max(dH, dW)
  }, [size.width, size.height, f.w, f.h])
}
