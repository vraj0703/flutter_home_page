/**
 * GalleryScene.tsx — Unified 3D Gallery
 *
 * Sections:
 *   1. Constants & dimensions (corridor, testimonials, keyboard room)
 *   2. Procedural textures (wall normal/roughness maps)
 *   3. Frame sizing hooks (useFrameSize, useFocusDistance)
 *   4. Project artwork draw functions (canvas-based generative art)
 *   5. Shared materials (useMaterials)
 *   6. WallFrame / TestimonialFrame components
 *   7. CanopyLight / CeilingBeam / FloatingKB
 *   8. CameraRig — walk forward, lock on wall, pan right, keyboard orbit
 *   9. GalleryCorridor — walls, floors, ceiling, frames, lights
 *  10. GalleryScene (exported) — Canvas wrapper with scroll + orbit
 */

import { Suspense, useRef, useMemo, useEffect, useState, useCallback } from 'react'
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { ScrollControls, useScroll, Text, OrbitControls } from '@react-three/drei'
import * as THREE from 'three'
import { LEFT_PROJECTS, RIGHT_PROJECTS, type Project } from '../../config/projects'
import { TESTIMONIALS, type Testimonial } from '../../config/testimonials'
import { Keyboard as SkillKeyboard, resetBoot, Particles as KBParticles } from '../three/KeyboardScene'
import { getAudioEngine } from '../../audio'

/* ── Dimensions ──────────────────────────────────────────── */
const CW = 8, CH = 5
const FRAME_MAX_H = 3.0, FRAME_DEPTH = 0.2, FRAME_BORDER = 0.15, FRAME_Y = 0.8, SPACING = 5
const WALL_X = CW / 2, FLOOR_Y = -(CH / 2 - 1), CEIL_Y = CH / 2 + 1.5
const FOV_RAD = (65 * Math.PI) / 180, FOCUS_MARGIN = 1.5

// Project corridor — 4 rows deep, extra room after last frames
const CORRIDOR_LEN = LEFT_PROJECTS.length * SPACING + 8
const BACK_WALL_Z = -(CORRIDOR_LEN - 3)

// Right wall stops after 3 pairs — opening starts at row 4 (P7)
const RIGHT_WALL_LEN = RIGHT_PROJECTS.length * SPACING + 6

// Testimonial frames on back wall — spaced horizontally (exclude CTA for layout math)
const TEST_CARDS = TESTIMONIALS.filter(t => !t.isCTA)
const ALL_TEST_CARDS = TESTIMONIALS // includes CTA as last entry
const TEST_SPACING = 5
const TEST_START_X = 7
const TEST_PAN_END = TEST_START_X + (TEST_CARDS.length - 1) * TEST_SPACING

// Shared scroll progress
let _scrollProgress = 0

// CTA click state — observable from outside Three.js
let _ctaClickListeners: Array<() => void> = []
export function subscribeCTAClick(fn: () => void) {
  _ctaClickListeners.push(fn)
  return () => { _ctaClickListeners = _ctaClickListeners.filter(f => f !== fn) }
}
function fireCTAClick() { _ctaClickListeners.forEach(fn => fn()) }

// Keyboard focus state — observable from outside Three.js
let _kbFocused = false
let _kbFocusListeners: Array<(focused: boolean) => void> = []
function setKbFocused(v: boolean) {
  if (v === _kbFocused) return
  _kbFocused = v
  _kbFocusListeners.forEach(fn => fn(v))
}
export function subscribeKbFocus(fn: (focused: boolean) => void) {
  _kbFocusListeners.push(fn)
  fn(_kbFocused) // fire initial
  return () => { _kbFocusListeners = _kbFocusListeners.filter(f => f !== fn) }
}

// Scroll unlock request — set by Back button, consumed by CameraRig
let _scrollUnlockRequested = false
export function requestScrollUnlock() { _scrollUnlockRequested = true }

// Back navigation — observable from outside Three.js
let _backClickListeners: Array<() => void> = []
export function subscribeBackClick(fn: () => void) {
  _backClickListeners.push(fn)
  return () => { _backClickListeners = _backClickListeners.filter(f => f !== fn) }
}
function fireBackClick() { _backClickListeners.forEach(fn => fn()) }

// Connect click — navigate to Flutter contact section
let _connectClickListeners: Array<() => void> = []
export function subscribeConnectClick(fn: () => void) {
  _connectClickListeners.push(fn)
  return () => { _connectClickListeners = _connectClickListeners.filter(f => f !== fn) }
}
function fireConnectClick() { _connectClickListeners.forEach(fn => fn()) }

// Keyboard exhibition hall — center past all testimonials + breathing room
const KB_ROOM = 24
// KB_ENTRY_X must clear the last testimonial card (CTA at index 6)
const LAST_CARD_X = TEST_START_X + 6 * TEST_SPACING // 37
const KB_X = LAST_CARD_X + 3 + KB_ROOM / 2 // 37 + 3 + 12 = 52
const KB_Z = BACK_WALL_Z + CW / 2
const KB_ENTRY_X = KB_X - KB_ROOM / 2 // 40
const KB_END_X = KB_X + KB_ROOM / 2

// Camera lock distance from back wall
const WALL_LOCK_DIST = 4
const WALL_LOCK_Z = BACK_WALL_Z + WALL_LOCK_DIST

/* ── Procedural textures ─────────────────────────────────── */
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
const _wallNormal = makeWallNormalMap()
const _wallRoughness = makeWallRoughnessMap()

/* ── Frame size hooks ────────────────────────────────────── */
function useFrameSize() {
  const { size } = useThree()
  return useMemo(() => {
    const a = size.width / size.height, h = FRAME_MAX_H, w = Math.min(h * a, WALL_X - 0.8)
    return { w, h: w / a }
  }, [size.width, size.height])
}
function useFocusDistance() {
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

/* ── Project artwork textures (canvas draw functions) ────── */
function drawBase(ctx: CanvasRenderingContext2D, S: number, c: [string, string]) {
  const g = ctx.createLinearGradient(0, 0, S, S); g.addColorStop(0, c[0]); g.addColorStop(1, c[1]); ctx.fillStyle = g; ctx.fillRect(0, 0, S, S)
  const r = ctx.createRadialGradient(S * .4, S * .35, 0, S * .4, S * .35, S * .6); r.addColorStop(0, 'rgba(255,255,255,0.06)'); r.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = r; ctx.fillRect(0, 0, S, S)
}
function drawStats(ctx: CanvasRenderingContext2D, S: number, stats: string[]) {
  ctx.font = 'bold 28px monospace'; ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.textAlign = 'center'
  const y = S - 60; stats.forEach((s, i) => ctx.fillText(s, S / 2 + (i - (stats.length - 1) / 2) * 180, y))
  ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(S * .15, y - 25); ctx.lineTo(S * .85, y - 25); ctx.stroke()
}
function drawTitle(ctx: CanvasRenderingContext2D, S: number, t: string) { ctx.font = 'bold 56px sans-serif'; ctx.fillStyle = 'rgba(255,255,255,0.12)'; ctx.textAlign = 'left'; ctx.fillText(t, 50, 70) }
function drawMesh(c: CanvasRenderingContext2D, S: number) { const ns = [{x:S*.5,y:S*.3,r:35,l:'PC'},{x:S*.25,y:S*.6,r:28,l:'Pi'},{x:S*.75,y:S*.6,r:24,l:'Phone'}]; c.strokeStyle='rgba(255,255,255,0.25)';c.lineWidth=2;ns.forEach((a,i)=>ns.forEach((b,j)=>{if(j>i){c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke()}}));for(let i=1;i<=4;i++){c.strokeStyle=`rgba(255,255,255,${.08-i*.015})`;c.lineWidth=1;c.beginPath();c.arc(S*.5,S*.45,60+i*40,0,Math.PI*2);c.stroke()}ns.forEach(n=>{c.fillStyle='rgba(255,255,255,0.2)';c.beginPath();c.arc(n.x,n.y,n.r,0,Math.PI*2);c.fill();c.fillStyle='rgba(255,255,255,0.7)';c.font='bold 22px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(n.l,n.x,n.y)}) }
function drawPipeline(c: CanvasRenderingContext2D, S: number) { const st=['Script','TTS','Footage','Edit','Upload'],y=S*.45;st.forEach((s,i)=>{const x=S*.12+i*(S*.19);c.fillStyle='rgba(255,255,255,0.1)';c.fillRect(x-35,y-22,70,44);c.strokeStyle='rgba(255,255,255,0.3)';c.lineWidth=1;c.strokeRect(x-35,y-22,70,44);c.fillStyle='rgba(255,255,255,0.7)';c.font='18px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(s,x,y);if(i<st.length-1){c.strokeStyle='rgba(255,255,255,0.3)';c.beginPath();c.moveTo(x+38,y);c.lineTo(x+58,y);c.stroke()}}) }
function drawTimeline(c: CanvasRenderingContext2D, S: number) { const js=[{l:'PayU',y2:'2016',s:'Fintech'},{l:'FieldAssist',y2:'2018',s:'FMCG'},{l:'Twin Health',y2:'2022',s:'Health'}],y=S*.48;c.strokeStyle='rgba(255,255,255,0.2)';c.lineWidth=2;c.beginPath();c.moveTo(S*.12,y);c.lineTo(S*.88,y);c.stroke();js.forEach((j,i)=>{const x=S*.2+i*(S*.3);c.fillStyle='rgba(255,255,255,0.5)';c.beginPath();c.arc(x,y,8,0,Math.PI*2);c.fill();c.fillStyle='rgba(255,255,255,0.7)';c.font='bold 22px sans-serif';c.textAlign='center';c.fillText(j.l,x,y+35);c.fillStyle='rgba(255,255,255,0.35)';c.font='16px monospace';c.fillText(`${j.y2} · ${j.s}`,x,y+58)}) }
function drawGraph(c: CanvasRenderingContext2D, S: number) { const rng=(i:number)=>((Math.sin(42+i*127.1)*43758.5453)%1+1)%1;const ns:{x:number;y:number}[]=[];for(let i=0;i<24;i++)ns.push({x:S*.15+rng(i*2)*S*.7,y:S*.18+rng(i*2+1)*S*.55});c.strokeStyle='rgba(255,255,255,0.08)';c.lineWidth=1;ns.forEach((a,i)=>ns.forEach((b,j)=>{if(j>i&&Math.abs(a.x-b.x)+Math.abs(a.y-b.y)<S*.35){c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke()}}));ns.forEach((n,i)=>{c.fillStyle=`rgba(255,255,255,${.15+rng(i+200)*.2})`;c.beginPath();c.arc(n.x,n.y,4+rng(i+100)*8,0,Math.PI*2);c.fill()}) }
function drawFunnel(c: CanvasRenderingContext2D, S: number) { [{l:'T1 · Instant',cl:'rgba(100,220,150,0.3)',w:.7},{l:'T2 · Local LLM',cl:'rgba(255,200,80,0.25)',w:.5},{l:'T3 · Executive',cl:'rgba(255,100,80,0.2)',w:.3}].forEach((t,i)=>{const y=S*.28+i*(S*.18),w=S*t.w,x=(S-w)/2;c.fillStyle=t.cl;c.fillRect(x,y,w,S*.12);c.fillStyle='rgba(255,255,255,0.6)';c.font='bold 22px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(t.l,S/2,y+S*.06)}) }
function drawDashboard(c: CanvasRenderingContext2D, S: number) { c.fillStyle='rgba(0,0,0,0.3)';c.fillRect(S*.08,S*.15,S*.84,S*.6);c.fillStyle='rgba(255,255,255,0.08)';c.fillRect(S*.08,S*.15,S*.84,S*.06);c.fillStyle='rgba(255,255,255,0.5)';c.font='16px monospace';c.textAlign='left';c.fillText('RAJ SADAN · COMMAND CENTER',S*.12,S*.19);['Cortex','Senses','Cron','Knowledge','WhatsApp'].forEach((s,i)=>{const x=S*.1+i*95,y=S*.25;c.fillStyle='rgba(100,220,150,0.2)';c.fillRect(x,y,85,24);c.fillStyle='rgba(100,220,150,0.7)';c.font='12px monospace';c.textAlign='center';c.fillText(s,x+42,y+16)});for(let i=0;i<3;i++){const y=S*.35+i*55;c.fillStyle='rgba(255,255,255,0.05)';c.fillRect(S*.1,y,S*.8,42);c.fillStyle='rgba(255,255,255,0.25)';c.font='14px monospace';c.textAlign='left';c.fillText(['▸ Alert: Health check passed','▸ Briefing: Morning ready','▸ Metric: 68 capabilities'][i],S*.13,y+26)} }
function drawChat(c: CanvasRenderingContext2D, S: number) { c.strokeStyle='rgba(255,255,255,0.2)';c.lineWidth=2;const px=S*.25,py=S*.12,pw=S*.5;c.strokeRect(px,py,pw,S*.68);c.fillStyle='rgba(255,255,255,0.08)';c.fillRect(px,py,pw,S*.06);c.fillStyle='rgba(255,255,255,0.5)';c.font='bold 16px sans-serif';c.textAlign='center';c.fillText('Raj Sadan Bot',S/2,py+S*.04);[{t:'✓ All 11 services online',a:'left' as const,y:.24},{t:'/status',a:'right' as const,y:.34},{t:'☀ Morning briefing ready',a:'left' as const,y:.44},{t:'⚡ Cortex cycle: 14.2s',a:'left' as const,y:.54}].forEach(m=>{const bx=m.a==='left'?px+15:px+pw-200,by=S*m.y;c.fillStyle=m.a==='left'?'rgba(255,255,255,0.08)':'rgba(255,255,255,0.15)';c.fillRect(bx,by,185,32);c.fillStyle='rgba(255,255,255,0.6)';c.font='14px monospace';c.textAlign='left';c.fillText(m.t,bx+10,by+21)}) }

function useProjectTexture(project: Project) {
  return useMemo(() => {
    const S = 1024, cv = document.createElement('canvas'); cv.width = cv.height = S; const ctx = cv.getContext('2d')!
    drawBase(ctx, S, project.colors)
    switch (project.visual) { case 'mesh': drawMesh(ctx, S); break; case 'pipeline': drawPipeline(ctx, S); break; case 'timeline': drawTimeline(ctx, S); break; case 'graph': drawGraph(ctx, S); break; case 'funnel': drawFunnel(ctx, S); break; case 'dashboard': drawDashboard(ctx, S); break; case 'chat': drawChat(ctx, S); break }
    drawTitle(ctx, S, project.title); drawStats(ctx, S, project.stats)
    return new THREE.CanvasTexture(cv)
  }, [project.title, project.colors, project.visual, project.stats])
}

/* ── Shared materials ────────────────────────────────────── */
/*
 * Material palette derived from Shadertoy path tracer reference:
 *   Walls  → Copper GGX:  specular (0.955, 0.637, 0.538), roughness 0.45
 *   Floor  → Silver GGX:  specular (0.972, 0.960, 0.915), roughness 0.35
 *   Ceiling→ Ceramic GGX: albedo   (0.8, 0.7, 0.65),     roughness 0.30
 */
function useMaterials() {
  return useMemo(() => ({
    // Walls — smooth golden, warm and bright
    wall: new THREE.MeshStandardMaterial({
      color: new THREE.Color(0.95, 0.82, 0.55), roughness: 0.75, metalness: 0.08,
      normalMap: _wallNormal, normalScale: new THREE.Vector2(0.3, 0.3), roughnessMap: _wallRoughness,
    }),
    // Walls — same golden, DoubleSide for keyboard room orbit
    wallDouble: new THREE.MeshStandardMaterial({
      color: new THREE.Color(0.95, 0.82, 0.55), roughness: 0.75, metalness: 0.08,
      side: THREE.DoubleSide,
    }),
    // Frame materials
    frameOuter: new THREE.MeshStandardMaterial({ color: '#5C3A1E', roughness: 0.3, metalness: 0.5 }),
    frameInner: new THREE.MeshStandardMaterial({ color: '#3E2510', roughness: 0.4, metalness: 0.3 }),
    mat: new THREE.MeshStandardMaterial({ color: '#E8E0D0', roughness: 0.95, metalness: 0 }),
    artBg: new THREE.MeshBasicMaterial({ color: '#FAF8F2' }),
  }), [])
}

/* ── WallFrame ───────────────────────────────────────────── */
let focusProjectIndex = -1, focusActive = false
export function setClickTarget(i: number) { focusProjectIndex = i; focusActive = true }

function WallFrame({ project, position, side, projectIndex, mats }: {
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
  useFrame(({ camera }, delta) => {
    if (!grp.current) return
    const t = hov.current ? 0.08 : 0; pop.current += (t - pop.current) * 0.1; grp.current.position.z = pop.current
    // Entry settle — one-shot damped scale pulse when gallery first entered
    if (entry.current.t < 0 && _scrollProgress > 0.001) entry.current.t = 0
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
      const worldPos = new THREE.Vector3(); grp.current.getWorldPosition(worldPos)
      const dist = camera.position.distanceTo(worldPos)
      const proximity = Math.max(0, 1 - dist / 8) // 0 at 8+ units, 1 at 0
      const targetGlow = (hov.current ? 0.6 : proximity * 0.25)
      const targetOpacity = (hov.current ? 0.4 : proximity * 0.15)
      glowMat.emissiveIntensity += (targetGlow - glowMat.emissiveIntensity) * 0.1
      glowMat.opacity += (targetOpacity - glowMat.opacity) * 0.1
    }
  })
  return (
    <group position={position} rotation={[0, rotY, 0]}>
      <group ref={grp}>
        <mesh onClick={() => { setClickTarget(projectIndex); getAudioEngine()?.playShutterClick() }} onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer'; getAudioEngine()?.playHoverPing() }} onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }} material={mats.frameOuter}><boxGeometry args={[frame.w + FRAME_BORDER * 2 + mw * 2, frame.h + FRAME_BORDER * 2 + mw * 2, FRAME_DEPTH]} /></mesh>
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

/* ── Testimonial frame on back wall ──────────────────────── */
function TestimonialFrame({ testimonial, position, mats }: {
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
          <Text position={[0, 0.5, FRAME_DEPTH / 2 + 0.005]} fontSize={0.18} color="#C8A45C" anchorX="center" anchorY="middle" font="/fonts/syne-bold.woff">
            Recommend Vishal
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.085} color="#A09880" anchorX="center" anchorY="middle" maxWidth={fw - 0.6} lineHeight={1.6}>
            Share your experience working together
          </Text>
          <mesh position={[0, -0.4, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.4, 0.003]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -0.7, FRAME_DEPTH / 2 + 0.005]} fontSize={0.07} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.12} font="/fonts/jetbrains-mono.woff">
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
          <Text position={[-fw / 2 + 0.2, fh / 2 - 0.25, FRAME_DEPTH / 2 + 0.005]} fontSize={0.4} color="#C8A45C" anchorX="left" anchorY="top" font="/fonts/playfair-display.woff">
            "
          </Text>
          <Text position={[0, 0.1, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" maxWidth={fw - 0.5} lineHeight={1.7}>
            {testimonial.text}
          </Text>
          <mesh position={[0, -fh / 2 + 0.7, FRAME_DEPTH / 2 + 0.005]}>
            <planeGeometry args={[fw * 0.5, 0.004]} />
            <meshBasicMaterial color="#C8A45C" />
          </mesh>
          <Text position={[0, -fh / 2 + 0.48, FRAME_DEPTH / 2 + 0.005]} fontSize={0.11} color="#2A2420" anchorX="center" anchorY="middle" font="/fonts/syne-bold.woff">
            {testimonial.name}
          </Text>
          <Text position={[0, -fh / 2 + 0.28, FRAME_DEPTH / 2 + 0.005]} fontSize={0.055} color="#9A8A6E" anchorX="center" anchorY="middle" letterSpacing={0.08} font="/fonts/jetbrains-mono.woff">
            {testimonial.role} · {testimonial.company}
          </Text>
        </group>
      )}

      <group position={[0, -(fh / 2 + FRAME_BORDER + 0.25), FRAME_DEPTH / 2]}>
        <mesh position={[0, -0.05, 0]}>
          <planeGeometry args={[1.0, 0.25]} />
          <meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.6} />
        </mesh>
        <Text position={[0, 0, 0.005]} fontSize={0.06} color="#2A2420" anchorX="center" anchorY="middle" letterSpacing={0.1} font="/fonts/jetbrains-mono.woff">
          {isCTA ? 'RECOMMEND' : 'TESTIMONIAL'}
        </Text>
      </group>
    </group>
  )
}

/* ── Tube light — glowing cylinder mounted above each frame ── */
function TubeLight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
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


/* ── Frame spotlight — warm focused light on each project frame ── */
function FrameSpotlight({ position, side }: { position: [number, number, number]; side: 'left' | 'right' }) {
  const lightRef = useRef<THREE.SpotLight>(null)
  const targetX = side === 'left' ? position[0] + 0.5 : position[0] - 0.5
  useFrame(() => {
    if (lightRef.current) {
      lightRef.current.target.position.set(position[0], position[1], position[2])
      lightRef.current.target.updateMatrixWorld()
    }
  })
  return (
    <spotLight
      ref={lightRef}
      position={[targetX, position[1] + 2.5, position[2]]}
      angle={0.45}
      penumbra={0.8}
      intensity={1.2}
      color="#FFE0B0"
      distance={6}
      decay={2}
    />
  )
}

/* ── Scroll arrow — 3D chevron on the gallery floor ── */
function ScrollArrow() {
  const grp = useRef<THREE.Group>(null)
  const opacity = useRef(1)
  const mat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#3A3A42', emissive: '#C8A45C', emissiveIntensity: 0.15,
    roughness: 0.25, metalness: 0.7, transparent: true, opacity: 1,
    side: THREE.DoubleSide,
  }), [])

  // Build arrow shape: chevron + shaft as a single extruded geometry
  const arrowGeo = useMemo(() => {
    const shape = new THREE.Shape()
    // Chevron arrow pointing up (+Y in shape space, becomes -Z when rotated flat)
    //   Outer chevron
    shape.moveTo(0, 0.7)        // tip
    shape.lineTo(0.45, 0.15)    // right wing outer
    shape.lineTo(0.25, 0.15)    // right wing inner notch
    shape.lineTo(0.25, -0.1)    // right shaft top
    shape.lineTo(0.1, -0.1)     // right shaft inner
    shape.lineTo(0.1, 0.25)     // inner right of chevron
    shape.lineTo(0, 0.42)       // inner tip
    shape.lineTo(-0.1, 0.25)    // inner left of chevron
    shape.lineTo(-0.1, -0.1)    // left shaft inner
    shape.lineTo(-0.25, -0.1)   // left shaft top
    shape.lineTo(-0.25, 0.15)   // left wing inner notch
    shape.lineTo(-0.45, 0.15)   // left wing outer
    shape.closePath()

    const extrudeSettings = { depth: 0.06, bevelEnabled: true, bevelThickness: 0.015, bevelSize: 0.015, bevelSegments: 2 }
    const geo = new THREE.ExtrudeGeometry(shape, extrudeSettings)
    geo.center()
    return geo
  }, [])

  useFrame(({ clock }) => {
    if (!grp.current) return
    const t = clock.elapsedTime

    // Gentle bounce along Z (into corridor)
    grp.current.position.z = -4 + Math.sin(t * 2) * 0.12

    // Show when near entrance (progress < 0.03), fade when scrolling, reappear when back to top
    const fadeTarget = _scrollProgress < 0.01 ? 1 : _scrollProgress < 0.06 ? 1 - (_scrollProgress - 0.01) / 0.05 : 0
    opacity.current += (fadeTarget - opacity.current) * 0.08
    mat.opacity = opacity.current
    grp.current.visible = opacity.current > 0.01
  })

  return (
    <group ref={grp} position={[0, FLOOR_Y + 0.03, -4]} rotation={[-Math.PI / 2, 0, 0]}>
      <mesh geometry={arrowGeo} material={mat} scale={[1.2, 1.2, 1]} />
    </group>
  )
}

/* ── Graffiti back button — spray-painted on left wall before frame 1 ── */
function GraffitiBackButton() {
  const grp = useRef<THREE.Group>(null)
  const hov = useRef(false)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#FFFFFF', emissive: '#FFFFFF', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useFrame(({ camera }) => {
    if (!grp.current || !glowRef.current) return
    const worldPos = new THREE.Vector3()
    grp.current.getWorldPosition(worldPos)
    const dist = camera.position.distanceTo(worldPos)
    const proximity = Math.max(0, 1 - dist / 6)
    const targetGlow = hov.current ? 0.8 : proximity * 0.2
    const targetOpacity = hov.current ? 0.15 : proximity * 0.06
    glowMat.emissiveIntensity += (targetGlow - glowMat.emissiveIntensity) * 0.1
    glowMat.opacity += (targetOpacity - glowMat.opacity) * 0.1
  })

  return (
    <group position={[-WALL_X + 0.1, FRAME_Y, -1]} rotation={[0, Math.PI / 2, 0]}>
      <group ref={grp}>
        {/* Hover glow backdrop */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[1.6, 1.0]} />
        </mesh>

        {/* Paint drip / splatter background — rough rectangle */}
        <mesh position={[0, 0, 0.005]}>
          <planeGeometry args={[1.4, 0.75]} />
          <meshStandardMaterial color="#1A1A1A" transparent opacity={0.35} roughness={1} metalness={0} />
        </mesh>

        {/* Arrow ← */}
        <Text
          position={[-0.42, 0.02, 0.01]}
          fontSize={0.28}
          color="#E8E0D0"
          anchorX="center"
          anchorY="middle"
          letterSpacing={0}
          font={undefined}
        >
          ←
        </Text>

        {/* "BACK" text — spray-paint style */}
        <Text
          position={[0.12, 0.02, 0.01]}
          fontSize={0.22}
          color="#E8E0D0"
          anchorX="center"
          anchorY="middle"
          letterSpacing={0.15}
          font={undefined}
        >
          BACK
        </Text>

        {/* Underline drip */}
        <mesh position={[0, -0.22, 0.008]}>
          <planeGeometry args={[1.1, 0.02]} />
          <meshStandardMaterial color="#E8E0D0" transparent opacity={0.4} roughness={1} metalness={0} />
        </mesh>

        {/* Invisible click plane */}
        <mesh
          position={[0, 0, 0.02]}
          onClick={() => { fireBackClick(); getAudioEngine()?.playButtonClick() }}
          onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
        >
          <planeGeometry args={[1.6, 1.0]} />
          <meshStandardMaterial transparent opacity={0} />
        </mesh>
      </group>
    </group>
  )
}

/* ── Wall Radio — streaming radio player on right wall ── */

const RADIO_CHANNELS = [
  { name: 'Lofi', url: 'https://ice5.somafm.com/lush-128-mp3' },
  { name: 'Jazz', url: 'https://ice4.somafm.com/secretagent-128-mp3' },
  { name: 'Ambient', url: 'https://ice5.somafm.com/groovesalad-128-mp3' },
  { name: 'Chill', url: 'https://ice2.somafm.com/seventies-128-mp3' },
]

// Module-level radio state (persists across re-renders)
let _radioAudio: HTMLAudioElement | null = null
let _radioPlaying = false
let _radioMuted = false
let _radioVolume = 0.25
let _radioChannel = 0
let _radioLoading = false
let _radioListeners: Array<() => void> = []

function _notifyRadio() { _radioListeners.forEach(fn => fn()) }

/** Preload the first channel (call early — creates Audio element but doesn't play) */
export function preloadRadio() {
  if (_radioAudio) return
  _radioAudio = new Audio(RADIO_CHANNELS[0].url)
  _radioAudio.crossOrigin = 'anonymous'
  _radioAudio.volume = _radioVolume
  _radioAudio.preload = 'auto'
  // Just load metadata + buffer, don't play
  _radioAudio.load()
}

/** Start playing (must be called after user gesture) */
function _playRadio() {
  if (!_radioAudio) preloadRadio()
  _radioLoading = true
  _notifyRadio()
  _radioAudio!.play().then(() => {
    _radioPlaying = true
    _radioLoading = false
    _notifyRadio()
  }).catch(() => {
    _radioLoading = false
    _notifyRadio()
  })
}

export function stopRadio() {
  if (_radioAudio) _radioAudio.pause()
  _radioPlaying = false
  _notifyRadio()
}

export function toggleRadioMute() {
  _radioMuted = !_radioMuted
  if (_radioAudio) _radioAudio.volume = _radioMuted ? 0 : _radioVolume
  _notifyRadio()
}

export function setRadioVolume(vol: number) {
  _radioVolume = Math.max(0, Math.min(1, vol))
  _radioMuted = _radioVolume === 0
  if (_radioAudio) _radioAudio.volume = _radioMuted ? 0 : _radioVolume
  _notifyRadio()
}

function _switchChannel(idx: number) {
  _radioChannel = idx
  const wasPlaying = _radioPlaying
  if (_radioAudio) { _radioAudio.pause(); _radioAudio.src = '' }
  _radioAudio = new Audio(RADIO_CHANNELS[idx].url)
  _radioAudio.crossOrigin = 'anonymous'
  _radioAudio.volume = _radioMuted ? 0 : _radioVolume
  if (wasPlaying) {
    _radioLoading = true
    _notifyRadio()
    _radioAudio.play().then(() => {
      _radioPlaying = true
      _radioLoading = false
      _notifyRadio()
    }).catch(() => {
      _radioLoading = false
      _notifyRadio()
    })
  } else {
    _radioAudio.preload = 'auto'
    _radioAudio.load()
    _notifyRadio()
  }
}

export function nextRadioChannel() {
  _switchChannel((_radioChannel + 1) % RADIO_CHANNELS.length)
}

/** Auto-start radio when gallery is entered (called after user has interacted) */
export function startRadioOnGalleryEnter() {
  if (!_radioPlaying && !_radioLoading) _playRadio()
}

/** Subscribe to radio state changes for external UI */
export function subscribeRadio(fn: () => void) {
  _radioListeners.push(fn)
  return () => { _radioListeners = _radioListeners.filter(f => f !== fn) }
}

export function getRadioState() {
  return { playing: _radioPlaying, muted: _radioMuted, loading: _radioLoading, channel: RADIO_CHANNELS[_radioChannel].name, volume: _radioVolume }
}

function WallRadio() {
  const grp = useRef<THREE.Group>(null)
  const hov = useRef(false)
  const knobRef = useRef<THREE.Group>(null)
  const [, forceUpdate] = useState(0)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useEffect(() => {
    const listener = () => forceUpdate(n => n + 1)
    _radioListeners.push(listener)
    return () => { _radioListeners = _radioListeners.filter(f => f !== listener) }
  }, [])

  // M key to mute
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'm' || e.key === 'M') toggleRadioMute() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  // Animate volume knob rotation
  useFrame(({ camera }) => {
    if (!grp.current || !glowRef.current) return
    // Proximity glow
    const worldPos = new THREE.Vector3()
    grp.current.getWorldPosition(worldPos)
    const dist = camera.position.distanceTo(worldPos)
    const proximity = Math.max(0, 1 - dist / 6)
    const targetGlow = hov.current ? 0.7 : proximity * 0.2
    const targetOpacity = hov.current ? 0.12 : proximity * 0.05
    glowMat.emissiveIntensity += (targetGlow - glowMat.emissiveIntensity) * 0.1
    glowMat.opacity += (targetOpacity - glowMat.opacity) * 0.1
    // Knob rotation: 0 vol = -135°, 1 vol = +135°
    if (knobRef.current) {
      const targetAngle = (-135 + _radioVolume * 270) * Math.PI / 180
      knobRef.current.rotation.z += (targetAngle - knobRef.current.rotation.z) * 0.15
    }
  })

  // Cycle volume: 0 → 0.25 → 0.5 → 0.75 → 1.0 → 0 (mute)
  const handleVolumeCycle = useCallback(() => {
    const steps = [0, 0.25, 0.5, 0.75, 1.0]
    const current = steps.findIndex(s => Math.abs(s - _radioVolume) < 0.05)
    const next = (current + 1) % steps.length
    setRadioVolume(steps[next])
    // Auto-start if off and volume > 0
    if (!_radioPlaying && steps[next] > 0) _playRadio()
    getAudioEngine()?.playButtonClick()
  }, [])

  const handleMuteToggle = useCallback(() => {
    if (!_radioPlaying) {
      _playRadio()
    } else {
      toggleRadioMute()
    }
    getAudioEngine()?.playButtonClick()
  }, [])

  const handleNext = useCallback(() => {
    nextRadioChannel()
    getAudioEngine()?.playButtonClick()
  }, [])

  const channelName = RADIO_CHANNELS[_radioChannel].name
  const statusText = _radioLoading ? '◌ TUNING...' : _radioPlaying ? (_radioMuted ? '● MUTED' : '● ON AIR') : '○ OFF'
  const statusColor = _radioLoading ? '#C8A45C' : _radioPlaying ? (_radioMuted ? '#C87A4C' : '#6AE06A') : '#8A7A62'
  const knobColor = _radioMuted ? '#5A5040' : '#C8A45C'

  return (
    <group position={[WALL_X - 0.1, FRAME_Y, -1]} rotation={[0, -Math.PI / 2, 0]}>
      <group ref={grp}>
        {/* Glow backdrop */}
        <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.01]}>
          <planeGeometry args={[2.0, 1.4]} />
        </mesh>

        {/* Radio body — dark panel */}
        <mesh position={[0, 0, 0.005]}>
          <planeGeometry args={[1.8, 1.2]} />
          <meshStandardMaterial color="#1A1A1A" roughness={0.8} metalness={0.1} transparent opacity={0.55} />
        </mesh>

        {/* ── Left: Speaker grille ── */}
        {[-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3].map((y, i) => (
          <mesh key={i} position={[-0.5, y, 0.008]}>
            <planeGeometry args={[0.5, 0.018]} />
            <meshStandardMaterial color="#3A3A3A" roughness={1} metalness={0} transparent opacity={0.5} />
          </mesh>
        ))}

        {/* ── Center: Display ── */}
        <Text position={[0.15, 0.22, 0.01]} fontSize={0.13} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.06}>
          {channelName}
        </Text>
        <Text position={[0.15, 0.06, 0.01]} fontSize={0.055} color={statusColor} anchorX="center" anchorY="middle" letterSpacing={0.08}>
          {statusText}
        </Text>

        {/* ── Volume knob (3D cylinder) — click to cycle volume ── */}
        <group position={[-0.15, -0.3, 0.04]}
          onClick={handleVolumeCycle}
          onPointerOver={() => { document.body.style.cursor = 'pointer' }}
          onPointerOut={() => { document.body.style.cursor = 'default' }}
        >
          {/* Knob base ring */}
          <mesh rotation={[Math.PI / 2, 0, 0]}>
            <cylinderGeometry args={[0.12, 0.12, 0.02, 24]} />
            <meshStandardMaterial color="#2A2420" roughness={0.4} metalness={0.5} />
          </mesh>
          {/* Rotatable knob */}
          <group ref={knobRef}>
            <mesh rotation={[Math.PI / 2, 0, 0]}>
              <cylinderGeometry args={[0.09, 0.09, 0.04, 24]} />
              <meshStandardMaterial color="#3A3028" roughness={0.3} metalness={0.6} />
            </mesh>
            {/* Indicator dot */}
            <mesh position={[0, 0.07, 0.025]}>
              <sphereGeometry args={[0.015, 8, 8]} />
              <meshStandardMaterial color={knobColor} emissive={knobColor} emissiveIntensity={0.5} />
            </mesh>
          </group>
          {/* VOL label */}
          <Text position={[0, -0.16, 0.01]} fontSize={0.04} color="#5A5040" anchorX="center" anchorY="middle" letterSpacing={0.1}>
            VOL
          </Text>
        </group>

        {/* ── Mute/Play button ── */}
        <group position={[0.2, -0.3, 0.03]}>
          <mesh rotation={[Math.PI / 2, 0, 0]}
            onClick={handleMuteToggle}
            onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
            onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
          >
            <cylinderGeometry args={[0.1, 0.1, 0.035, 24]} />
            <meshStandardMaterial color={_radioMuted || !_radioPlaying ? '#3A3028' : '#2A3A28'} roughness={0.4} metalness={0.4} />
          </mesh>
          <Text position={[0, 0, 0.025]} fontSize={0.035} color={knobColor} anchorX="center" anchorY="middle" letterSpacing={0.03}>
            {_radioPlaying ? (_radioMuted ? 'UNMUTE' : 'MUTE') : 'PLAY'}
          </Text>
        </group>

        {/* ── Next station button ── */}
        <group position={[0.55, -0.3, 0.03]}>
          <mesh rotation={[Math.PI / 2, 0, 0]}
            onClick={handleNext}
            onPointerOver={() => { document.body.style.cursor = 'pointer' }}
            onPointerOut={() => { document.body.style.cursor = 'default' }}
          >
            <cylinderGeometry args={[0.1, 0.1, 0.035, 24]} />
            <meshStandardMaterial color="#3A3028" roughness={0.4} metalness={0.4} />
          </mesh>
          <Text position={[0, 0, 0.025]} fontSize={0.035} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.03}>
            NEXT
          </Text>
        </group>

        {/* Underline accent */}
        <mesh position={[0, -0.52, 0.008]}>
          <planeGeometry args={[1.5, 0.015]} />
          <meshStandardMaterial color="#C8A45C" transparent opacity={0.4} roughness={1} metalness={0} />
        </mesh>
      </group>
    </group>
  )
}

/* ── Let's Connect — framed CTA on keyboard room right wall ── */
function LetsConnectFrame() {
  const hov = useRef(false)
  const glowRef = useRef<THREE.Mesh>(null)
  const glowMat = useMemo(() => new THREE.MeshStandardMaterial({
    color: '#C8A45C', emissive: '#C8A45C', emissiveIntensity: 0,
    transparent: true, opacity: 0, side: THREE.DoubleSide,
  }), [])

  useFrame(({ camera }) => {
    if (!glowRef.current) return
    const worldPos = new THREE.Vector3()
    glowRef.current.getWorldPosition(worldPos)
    const dist = camera.position.distanceTo(worldPos)
    const proximity = Math.max(0, 1 - dist / 12)
    const targetGlow = hov.current ? 0.8 : proximity * 0.3
    const targetOpacity = hov.current ? 0.2 : proximity * 0.08
    glowMat.emissiveIntensity += (targetGlow - glowMat.emissiveIntensity) * 0.1
    glowMat.opacity += (targetOpacity - glowMat.opacity) * 0.1
  })

  return (
    <group position={[KB_ENTRY_X + 0.1, 1.5, (KB_Z + KB_ROOM / 2 + BACK_WALL_Z + CW) / 2]} rotation={[0, Math.PI / 2, 0]}>
      {/* Glow backdrop */}
      <mesh ref={glowRef} material={glowMat} position={[0, 0, -0.02]}>
        <planeGeometry args={[3.5, 2.0]} />
      </mesh>

      {/* Frame outer */}
      <mesh position={[0, 0, 0.005]}>
        <planeGeometry args={[3.2, 1.6]} />
        <meshStandardMaterial color="#1E1C18" roughness={0.6} metalness={0.2} transparent opacity={0.6} />
      </mesh>

      {/* Frame border */}
      <mesh position={[0, 0, 0.003]}>
        <planeGeometry args={[3.4, 1.8]} />
        <meshStandardMaterial color="#C8A45C" roughness={0.3} metalness={0.5} transparent opacity={0.15} />
      </mesh>

      {/* Main text */}
      <Text
        position={[0, 0.15, 0.01]}
        fontSize={0.35}
        color="#C8A45C"
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.08}
        fontWeight={700}
      >
        Let's Connect
      </Text>

      {/* Subtitle */}
      <Text
        position={[0, -0.25, 0.01]}
        fontSize={0.1}
        color="#8A7A62"
        anchorX="center"
        anchorY="middle"
        letterSpacing={0.12}
      >
        CLICK TO REACH OUT
      </Text>

      {/* Accent line */}
      <mesh position={[0, -0.08, 0.008]}>
        <planeGeometry args={[1.8, 0.008]} />
        <meshStandardMaterial color="#C8A45C" transparent opacity={0.5} />
      </mesh>

      {/* Click plane */}
      <mesh
        position={[0, 0, 0.02]}
        onClick={() => { fireConnectClick(); getAudioEngine()?.playButtonClick() }}
        onPointerOver={() => { hov.current = true; document.body.style.cursor = 'pointer' }}
        onPointerOut={() => { hov.current = false; document.body.style.cursor = 'default' }}
      >
        <planeGeometry args={[3.2, 1.6]} />
        <meshStandardMaterial transparent opacity={0} />
      </mesh>
    </group>
  )
}

/* ── Back wall spotlight — warm overhead aimed at back wall center ── */
function BackWallSpotlight() {
  const ref = useRef<THREE.SpotLight>(null)
  useFrame(() => {
    if (ref.current) { ref.current.target.position.set(0, 1, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[0, CEIL_Y - 0.3, BACK_WALL_Z + 3]} angle={0.6} penumbra={0.9} intensity={2.5} color="#FFD9A0" distance={10} decay={1.5} />
}

/* ── Testimonial spotlight — individual warm light per frame ── */
function TestimonialSpotlight({ x }: { x: number }) {
  const ref = useRef<THREE.SpotLight>(null)
  useFrame(() => {
    if (ref.current) { ref.current.target.position.set(x, FRAME_Y, BACK_WALL_Z); ref.current.target.updateMatrixWorld() }
  })
  return <spotLight ref={ref} position={[x, CEIL_Y - 0.5, BACK_WALL_Z + 2.5]} angle={0.4} penumbra={0.8} intensity={1.0} color="#FFE0B0" distance={6} decay={2} />
}

/* ── Floating keyboard — gentle rotation + bob ───────────── */
function FloatingKB({ position }: { position: [number, number, number] }) {
  const outerRef = useRef<THREE.Group>(null)
  // 3-phase lifecycle:
  // - unmounted (scroll < 5%): nothing in scene graph
  // - preloading (5-93%): mounted 500 units below, compiling shaders across frames
  // - visible (>93%): camera turn is complete, teleport to real position
  const [phase, setPhase] = useState<'unmounted' | 'preloading' | 'visible'>('unmounted')

  useFrame(({ clock }) => {
    if (phase === 'unmounted' && _scrollProgress > 0.05) setPhase('preloading')
    if (phase === 'preloading' && _scrollProgress > 0.93) setPhase('visible')

    if (!outerRef.current) return
    const p = _scrollProgress
    if (p < 0.97) {
      outerRef.current.rotation.y = Math.PI + clock.elapsedTime * 0.1
      outerRef.current.position.y = position[1] + Math.sin(clock.elapsedTime * 0.4) * 0.08
    } else {
      outerRef.current.rotation.y += (Math.PI - outerRef.current.rotation.y) * 0.03
      outerRef.current.position.y += (position[1] - outerRef.current.position.y) * 0.03
    }
  })

  if (phase === 'unmounted') return null

  return (
    <group
      ref={outerRef}
      // During preload: hide 500 units below the scene — out of camera frustum
      // but still in the scene graph so Three.js compiles geometries/shaders
      position={phase === 'preloading' ? [position[0], -500, position[2]] : position}
    >
      <group rotation={[0, -Math.PI / 2, 0]} scale={0.7}>
        <SkillKeyboard />
      </group>
    </group>
  )
}

/* ══════════════════════════════════════════════════════════
   CAMERA RIG — walk forward, lock on wall, pan right, keyboard orbit
   ══════════════════════════════════════════════════════════ */
function CameraRig() {
  const scroll = useScroll()
  const { camera, clock } = useThree()
  const focusDist = useFocusDistance()
  const curPos = useRef(new THREE.Vector3(0, 0.5, 3))
  const curLook = useRef(new THREE.Vector3(0, 0.5, -10))
  const prevOff = useRef(0)
  const kbTriggered = useRef(false)
  const kbFocused = useRef(false)

  useFrame(() => {
    const p = scroll.offset
    _scrollProgress = p

    // Handle scroll unlock request (back scroll from keyboard)
    if (_scrollUnlockRequested && kbFocused.current) {
      _scrollUnlockRequested = false
      kbTriggered.current = false
      kbFocused.current = false
      setKbFocused(false)
      const el = scroll.el
      if (el) {
        // Snap directly — no smooth scroll which fights drei's tracking
        el.scrollTop = el.scrollHeight * 0.85
      }
      return
    }

    // Hysteresis: once KB focused, detect back-scroll to exit
    if (kbFocused.current) {
      if (p < 0.96) {
        // User scrolled back — exit keyboard
        kbTriggered.current = false
        kbFocused.current = false
        setKbFocused(false)
        const el = scroll.el
        if (el) {
          // Snap to turn phase — no smooth scroll
          el.scrollTop = el.scrollHeight * 0.87
        }
      } else {
        _scrollProgress = Math.max(p, 0.97)
        return
      }
    }
    if (p < 0.92) { kbTriggered.current = false }
    if (focusActive && Math.abs(p - prevOff.current) > 0.002) { focusActive = false; focusProjectIndex = -1 }
    prevOff.current = p

    let tPos: THREE.Vector3, tLook: THREE.Vector3

    if (focusActive && focusProjectIndex >= 0) {
      // Focus on a project frame (click-to-zoom)
      const isLeft = focusProjectIndex < LEFT_PROJECTS.length
      const pi = isLeft ? focusProjectIndex : focusProjectIndex - LEFT_PROJECTS.length
      const z = -(pi + 1) * SPACING, lookY = FRAME_Y - 0.3
      if (isLeft) { tPos = new THREE.Vector3(-WALL_X + focusDist + 0.15, lookY, z); tLook = new THREE.Vector3(-WALL_X + 0.15, lookY, z) }
      else { tPos = new THREE.Vector3(WALL_X - focusDist - 0.15, lookY, z); tLook = new THREE.Vector3(WALL_X - 0.15, lookY, z) }
    } else if (p < 0.58) {
      // Walk forward — ends exactly at WALL_LOCK_Z
      const t = p / 0.58
      const z = 3 - t * (3 - WALL_LOCK_Z)
      tPos = new THREE.Vector3(0, 0.5, z)
      const wallProximity = Math.max(0, (p - 0.45) / 0.13)
      const lookZ = (z - 10) + (BACK_WALL_Z - (z - 10)) * wallProximity * wallProximity
      tLook = new THREE.Vector3(0, 0.5, lookZ)
    } else if (p < 0.88) {
      // Pan right along the back wall
      const t = (p - 0.58) / 0.30
      const panX = t * TEST_PAN_END
      tPos = new THREE.Vector3(panX, 0.6, WALL_LOCK_Z)
      tLook = new THREE.Vector3(panX, 0.6, BACK_WALL_Z)
    } else if (p < 0.93) {
      // Turn right — look down the corridor at the keyboard
      const cx = TEST_PAN_END
      tPos = new THREE.Vector3(cx, 0.8, KB_Z)
      tLook = new THREE.Vector3(KB_X, 0.8, KB_Z)
    } else if (p < 0.97 || !kbTriggered.current) {
      // Zoom in — stay below ceiling, camera max y = 2.5
      // Also enters here if p >= 0.97 but kbTriggered is false (fast scroll skip)
      // This prevents teleporting to orbit before the zoom phase completes
      if (!kbTriggered.current) { kbTriggered.current = true; resetBoot(); getAudioEngine()?.playBootSweep() }
      const t = Math.min(1, (p - 0.93) / 0.04)
      const ease = Math.sin(t * Math.PI / 2)
      const cx = TEST_PAN_END
      tPos = new THREE.Vector3(
        cx + ease * (KB_X - cx),
        0.8 + ease * 1.7,
        KB_Z + ease * 5
      )
      tLook = new THREE.Vector3(KB_X, FLOOR_Y, KB_Z)
      // Only allow orbit focus once the camera has actually arrived (lerped close enough)
      if (p >= 0.97 && curPos.current.distanceTo(tPos) < 1.0) {
        kbFocused.current = true
        setKbFocused(true)
        camera.position.set(KB_X, 2.5, KB_Z + 5)
        camera.lookAt(KB_X, FLOOR_Y, KB_Z)
        return
      }
    } else {
      // Keyboard focus — OrbitControls takes over
      if (!kbFocused.current) {
        kbFocused.current = true
        setKbFocused(true)
        camera.position.set(KB_X, 2.5, KB_Z + 5)
        camera.lookAt(KB_X, FLOOR_Y, KB_Z)
      }
      return
    }

    // Direct position for wall-lock + pan + turn; lerp for walk + focus + keyboard zoom
    const isLocked = !focusActive && p >= 0.58 && p < 0.93
    const isKeyboard = !focusActive && p >= 0.93
    if (isLocked) {
      curPos.current.copy(tPos)
      curLook.current.copy(tLook)
    } else if (isKeyboard) {
      curPos.current.lerp(tPos, 0.06)
      curLook.current.lerp(tLook, 0.06)
    } else {
      const ls = focusActive ? 0.18 : 0.08
      curPos.current.lerp(tPos, ls); curLook.current.lerp(tLook, ls)
    }

    camera.position.copy(curPos.current)

    // Subtle head-bob during corridor walk (sinusoidal Y offset)
    if (!focusActive && p < 0.58) {
      const walkSpeed = Math.abs(p - prevOff.current) * 400
      const bobAmount = Math.min(walkSpeed, 1) * 0.02
      camera.position.y += Math.sin(clock.elapsedTime * 3.5) * bobAmount
    }

    // FOV transition: 65 (gallery) -> 50 (keyboard intimate) during zoom
    const perspCam = camera as THREE.PerspectiveCamera
    const targetFov = p >= 0.97 ? 50 : (p >= 0.93 ? 65 - (Math.sin(((p - 0.93) / 0.04) * Math.PI / 2)) * 15 : 65)
    if (Math.abs(perspCam.fov - targetFov) > 0.1) {
      perspCam.fov += (targetFov - perspCam.fov) * 0.08
      perspCam.updateProjectionMatrix()
    }

    if (!focusActive && p >= 0.88 && p < 0.93) {
      // Manual Y rotation for the turn
      const turnT = (p - 0.88) / 0.05
      const ease = turnT * turnT * (3 - 2 * turnT)
      camera.rotation.set(0, -ease * Math.PI / 2, 0)
    } else if (!focusActive && p >= 0.93) {
      camera.lookAt(curLook.current)
    } else {
      camera.lookAt(curLook.current)
      const t = clock.elapsedTime
      camera.rotation.z += Math.sin(t * 0.5) * 0.002 + Math.sin(t * 0.3) * 0.001
    }
  })
  return null
}

/* ══════════════════════════════════════════════════════════
   GALLERY CORRIDOR + BACK WALL + KEYBOARD EXHIBITION HALL
   ══════════════════════════════════════════════════════════ */
function GalleryCorridor() {
  const mats = useMaterials()

  return (
    <group>
      {/* ── PROJECT CORRIDOR ─────────────────────────────── */}

      {/* Floor — warm silver, low metalness for brightness */}
      <mesh receiveShadow rotation={[-Math.PI / 2, 0, 0]} position={[KB_X / 2, FLOOR_Y, KB_Z]}>
        <planeGeometry args={[200, 200]} />
        <meshStandardMaterial color={[0.88, 0.85, 0.80]} roughness={0.4} metalness={0.08} side={THREE.DoubleSide} />
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

      {/* Scroll cue arrow on floor */}
      <ScrollArrow />

      {/* ── BACK WALL — About Me + Testimonials ────────── */}
      {/* Stops at keyboard room entry */}
      <mesh position={[(KB_ENTRY_X) / 2 - WALL_X, 0.5, BACK_WALL_Z]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X + CW, CH + 2]} />
      </mesh>

      {/* Front wall of testimonial wing — stops at room entry */}
      <mesh position={[(KB_ENTRY_X + WALL_X) / 2, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wall}>
        <planeGeometry args={[KB_ENTRY_X - WALL_X, CH + 2]} />
      </mesh>

      {/* About Me — center of corridor (x=0) */}
      <group position={[0, 0, BACK_WALL_Z + 0.02]}>
        <mesh position={[0, 1.8, -0.02]}>
          <planeGeometry args={[5, 1.2]} />
          <meshBasicMaterial color="#C8A45C" transparent opacity={0.04} />
        </mesh>
        <Text position={[0, 1.8, 0]} fontSize={0.8} color="#C8A45C" anchorX="center" anchorY="middle" letterSpacing={0.05} font="/fonts/poseidon.otf">VISHAL RAJ</Text>
        <mesh position={[0, 1.4, 0]}><planeGeometry args={[2.5, 0.003]} /><meshBasicMaterial color="#C8A45C" /></mesh>
        <Text position={[0, 1.1, 0]} fontSize={0.12} color="#8A7A62" anchorX="center" anchorY="middle" letterSpacing={0.2} font="/fonts/jetbrains-mono.woff">FLUTTER PLATFORM LEAD</Text>
        <Text position={[0, 0.6, 0]} fontSize={0.08} color="#7A7060" anchorX="center" anchorY="middle" letterSpacing={0.08} font="/fonts/jetbrains-mono.woff">9+ years crafting mobile platforms</Text>
      </group>

      {/* ── BACK WALL LIGHTING — warm testimonial zone ── */}
      {/* Central overhead spotlight on back wall */}
      <BackWallSpotlight />
      {/* Warm fill lights along testimonial wall */}
      <pointLight position={[TEST_START_X, CEIL_Y - 1, BACK_WALL_Z + 2]} intensity={1.0} color="#FFE8C8" distance={15} decay={2} />
      <pointLight position={[TEST_START_X + TEST_CARDS.length * TEST_SPACING / 2, CEIL_Y - 0.5, BACK_WALL_Z + 1.5]} intensity={0.8} color="#FFF0D8" distance={20} decay={2} />

      {/* Testimonial frames on the back wall (includes CTA as last card) */}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialFrame
          key={t.id}
          testimonial={t}
          position={[TEST_START_X + i * TEST_SPACING, FRAME_Y, BACK_WALL_Z + 0.08]}
          mats={mats}
        />
      ))}

      {/* Individual spotlights on each testimonial frame */}
      {ALL_TEST_CARDS.map((t, i) => (
        <TestimonialSpotlight key={`tspot-${t.id}`} x={TEST_START_X + i * TEST_SPACING} />
      ))}

      {/* Graffiti back button — on left wall before frame 1 */}
      <GraffitiBackButton />

      {/* Radio player — on right wall opposite back button */}
      <WallRadio />

      {/* Left wall frames (4) */}
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

      {/* Right wall frames (3) */}
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


      {/* ── KEYBOARD EXHIBITION HALL — 24x24 room ──────── */}
      {/* Room center: (KB_X, KB_Z), walls at +/-12 from center */}
      {/* Entry wall at KB_ENTRY_X has 8-unit opening matching corridor width */}

      {/* Keyboard room walls (DoubleSide for orbit camera) */}
      <mesh position={[KB_X, 1.5, KB_Z + KB_ROOM / 2]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_X, 1.5, KB_Z - KB_ROOM / 2]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      <mesh position={[KB_END_X, 1.5, KB_Z]} rotation={[0, -Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM, CH + 2]} />
      </mesh>
      {/* Entry panels */}
      <mesh position={[KB_ENTRY_X, 1, (KB_Z + KB_ROOM / 2 + BACK_WALL_Z + CW) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X, 1, (BACK_WALL_Z + KB_Z - KB_ROOM / 2) / 2]} rotation={[0, Math.PI / 2, 0]} material={mats.wallDouble}>
        <planeGeometry args={[KB_ROOM / 2 - CW / 2, CH + 2]} />
      </mesh>

      {/* Corridor extension walls — prevent void when orbiting */}
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>
      <mesh position={[KB_ENTRY_X - 10, 0.5, BACK_WALL_Z + CW]} rotation={[0, Math.PI, 0]} material={mats.wallDouble}>
        <planeGeometry args={[20, CH + 2]} />
      </mesh>

      {/* Let's Connect — on right wall of keyboard room */}
      <LetsConnectFrame />

      {/* Keyboard — centered in the hall */}
      <FloatingKB position={[KB_X, 0.6, KB_Z]} />

      <group position={[KB_X, 1.5, KB_Z]}>
        <KBParticles count={25} />
      </group>

    </group>
  )
}

/* ══════════════════════════════════════════════════════════
   EXPORTED SCENE — single gallery, single scroll
   ══════════════════════════════════════════════════════════ */

function KeyboardOrbit() {
  const controlsRef = useRef<any>(null)
  useFrame(() => {
    if (!controlsRef.current) return
    const active = _scrollProgress >= 0.97
    controlsRef.current.enabled = active
    if (active) {
      controlsRef.current.target.set(KB_X, 0, KB_Z)
    }
  })
  return (
    <OrbitControls
      ref={controlsRef}
      enabled={false}
      enableZoom={false}
      enablePan={false}
      minPolarAngle={Math.PI / 4}
      maxPolarAngle={Math.PI / 2.2}
      dampingFactor={0.05}
      makeDefault={false}
    />
  )
}

/* ── Shader warm-up: compile all materials on first frames ── */
function ShaderWarmup() {
  const { gl, scene, camera } = useThree()
  const done = useRef(false)

  useFrame(() => {
    if (done.current) return
    done.current = true
    gl.compile(scene, camera)
  })

  return null
}

export function GalleryScene() {
  return (
    <Canvas
      camera={{ position: [0, 0.3, 3], fov: 65 }}
      gl={{ antialias: true, toneMapping: THREE.ACESFilmicToneMapping, toneMappingExposure: 1.6, preserveDrawingBuffer: true, powerPreference: 'high-performance' }}
      shadows
      style={{ position: 'absolute', inset: 0 }}
      onCreated={({ gl }) => { gl.setClearColor(new THREE.Color('#C4B496'), 1) }}
    >
      <color attach="background" args={['#C4B496']} />
      <fog attach="fog" args={['#C4B496', 25, 80]} />
      <ambientLight intensity={0.35} color="#FFF8E8" />
      <hemisphereLight args={['#FFF8E8', '#C4B496', 0.4]} />

      <KeyboardOrbit />
      <ShaderWarmup />

      <Suspense fallback={null}>
        <ScrollControls pages={16} damping={0.2}>
          <CameraRig />
          <GalleryCorridor />
        </ScrollControls>
      </Suspense>
    </Canvas>
  )
}
