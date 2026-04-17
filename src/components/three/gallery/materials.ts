/**
 * Gallery shared materials — procedural textures and material palette.
 * Memory fix: dispose() added via useEffect cleanup.
 */
import { useMemo, useEffect } from 'react'
import * as THREE from 'three'

/* ── Procedural textures ─────────────────────────────── */
function makeWallNormalMap(): THREE.CanvasTexture {
  const S = 512, c = document.createElement('canvas'); c.width = c.height = S
  const x = c.getContext('2d')!, img = x.createImageData(S, S)
  for (let y = 0; y < S; y++) for (let xx = 0; xx < S; xx++) {
    const i = (y * S + xx) * 4
    img.data[i] = 128 + Math.floor(Math.sin(xx * 0.08) * Math.cos(y * 0.05) * 15 + (Math.random() - 0.5) * 12)
    img.data[i + 1] = 128 + Math.floor(Math.cos(xx * 0.06) * Math.sin(y * 0.09) * 15 + (Math.random() - 0.5) * 12)
    img.data[i + 2] = 230 + Math.floor(Math.random() * 25); img.data[i + 3] = 255
  }
  x.putImageData(img, 0, 0)
  const t = new THREE.CanvasTexture(c); t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(16, 16); return t
}

function makeWallRoughnessMap(): THREE.CanvasTexture {
  const S = 256, c = document.createElement('canvas'); c.width = c.height = S
  const x = c.getContext('2d')!, img = x.createImageData(S, S)
  for (let i = 0; i < img.data.length; i += 4) {
    const v = 180 + Math.floor(Math.random() * 50)
    img.data[i] = img.data[i + 1] = img.data[i + 2] = v; img.data[i + 3] = 255
  }
  x.putImageData(img, 0, 0)
  const t = new THREE.CanvasTexture(c); t.wrapS = t.wrapT = THREE.RepeatWrapping; t.repeat.set(16, 16); return t
}

// Lazy-init: defer 512x512 + 256x256 canvas pixel loops until first useMaterials()
// call instead of blocking the main thread at module import time.
let _wallNormal: THREE.CanvasTexture | null = null
let _wallRoughness: THREE.CanvasTexture | null = null
function getWallNormal() { return _wallNormal ?? (_wallNormal = makeWallNormalMap()) }
function getWallRoughness() { return _wallRoughness ?? (_wallRoughness = makeWallRoughnessMap()) }

export type MaterialPalette = ReturnType<typeof useMaterials>

export function useMaterials() {
  const mats = useMemo(() => ({
    wall: new THREE.MeshStandardMaterial({
      color: new THREE.Color('#D4A97E'), roughness: 0.75, metalness: 0.08,
      normalMap: getWallNormal(), normalScale: new THREE.Vector2(0.3, 0.3), roughnessMap: getWallRoughness(),
    }),
    wallDouble: new THREE.MeshStandardMaterial({
      color: new THREE.Color('#D4A97E'), roughness: 0.75, metalness: 0.08,
      side: THREE.DoubleSide,
    }),
    frameOuter: new THREE.MeshPhysicalMaterial({ color: '#111111', roughness: 0.15, metalness: 0.8, clearcoat: 1.0, clearcoatRoughness: 0.1 }),
    frameInner: new THREE.MeshPhysicalMaterial({ color: '#050505', roughness: 0.3, metalness: 0.6 }),
    mat: new THREE.MeshStandardMaterial({ color: '#E8E0D0', roughness: 0.95, metalness: 0 }),
    artBg: new THREE.MeshBasicMaterial({ color: '#FAF8F2' }),
  }), [])

  // Memory fix: dispose all materials on unmount
  useEffect(() => {
    return () => {
      Object.values(mats).forEach(m => m.dispose())
    }
  }, [mats])

  return mats
}
