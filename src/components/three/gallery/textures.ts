/**
 * Project artwork textures — canvas-based generative art for each project frame.
 * Memory fix: textures are disposed on unmount via useEffect cleanup.
 */
import { useMemo, useEffect, useRef } from 'react'
import * as THREE from 'three'
import type { Project } from '../../../config/projects'

function drawBase(ctx: CanvasRenderingContext2D, S: number, c: [string, string]) {
  const g = ctx.createLinearGradient(0, 0, S, S); g.addColorStop(0, c[0]); g.addColorStop(1, c[1]); ctx.fillStyle = g; ctx.fillRect(0, 0, S, S)
  const r = ctx.createRadialGradient(S * .4, S * .35, 0, S * .4, S * .35, S * .6); r.addColorStop(0, 'rgba(255,255,255,0.06)'); r.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = r; ctx.fillRect(0, 0, S, S)
}

function drawStats(ctx: CanvasRenderingContext2D, S: number, stats: string[]) {
  ctx.font = 'bold 28px monospace'; ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.textAlign = 'center'
  const y = S - 60; stats.forEach((s, i) => ctx.fillText(s, S / 2 + (i - (stats.length - 1) / 2) * 180, y))
  ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(S * .15, y - 25); ctx.lineTo(S * .85, y - 25); ctx.stroke()
}

function drawTitle(ctx: CanvasRenderingContext2D, _S: number, t: string) { ctx.font = 'bold 56px sans-serif'; ctx.fillStyle = 'rgba(255,255,255,0.12)'; ctx.textAlign = 'left'; ctx.fillText(t, 50, 70) }

function drawMesh(c: CanvasRenderingContext2D, S: number) { const ns = [{x:S*.5,y:S*.3,r:35,l:'PC'},{x:S*.25,y:S*.6,r:28,l:'Pi'},{x:S*.75,y:S*.6,r:24,l:'Phone'}]; c.strokeStyle='rgba(255,255,255,0.25)';c.lineWidth=2;ns.forEach((a,i)=>ns.forEach((b,j)=>{if(j>i){c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke()}}));for(let i=1;i<=4;i++){c.strokeStyle=`rgba(255,255,255,${.08-i*.015})`;c.lineWidth=1;c.beginPath();c.arc(S*.5,S*.45,60+i*40,0,Math.PI*2);c.stroke()}ns.forEach(n=>{c.fillStyle='rgba(255,255,255,0.2)';c.beginPath();c.arc(n.x,n.y,n.r,0,Math.PI*2);c.fill();c.fillStyle='rgba(255,255,255,0.7)';c.font='bold 22px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(n.l,n.x,n.y)}) }

function drawPipeline(c: CanvasRenderingContext2D, S: number) { const st=['Script','TTS','Footage','Edit','Upload'],y=S*.45;st.forEach((s,i)=>{const x=S*.12+i*(S*.19);c.fillStyle='rgba(255,255,255,0.1)';c.fillRect(x-35,y-22,70,44);c.strokeStyle='rgba(255,255,255,0.3)';c.lineWidth=1;c.strokeRect(x-35,y-22,70,44);c.fillStyle='rgba(255,255,255,0.7)';c.font='18px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(s,x,y);if(i<st.length-1){c.strokeStyle='rgba(255,255,255,0.3)';c.beginPath();c.moveTo(x+38,y);c.lineTo(x+58,y);c.stroke()}}) }

function drawTimeline(c: CanvasRenderingContext2D, S: number) { const js=[{l:'PayU',y2:'2016',s:'Fintech'},{l:'FieldAssist',y2:'2018',s:'FMCG'},{l:'Twin Health',y2:'2022',s:'Health'}],y=S*.48;c.strokeStyle='rgba(255,255,255,0.2)';c.lineWidth=2;c.beginPath();c.moveTo(S*.12,y);c.lineTo(S*.88,y);c.stroke();js.forEach((j,i)=>{const x=S*.2+i*(S*.3);c.fillStyle='rgba(255,255,255,0.5)';c.beginPath();c.arc(x,y,8,0,Math.PI*2);c.fill();c.fillStyle='rgba(255,255,255,0.7)';c.font='bold 22px sans-serif';c.textAlign='center';c.fillText(j.l,x,y+35);c.fillStyle='rgba(255,255,255,0.35)';c.font='16px monospace';c.fillText(`${j.y2} · ${j.s}`,x,y+58)}) }

function drawGraph(c: CanvasRenderingContext2D, S: number) { const rng=(i:number)=>((Math.sin(42+i*127.1)*43758.5453)%1+1)%1;const ns:{x:number;y:number}[]=[];for(let i=0;i<24;i++)ns.push({x:S*.15+rng(i*2)*S*.7,y:S*.18+rng(i*2+1)*S*.55});c.strokeStyle='rgba(255,255,255,0.08)';c.lineWidth=1;ns.forEach((a,i)=>ns.forEach((b,j)=>{if(j>i&&Math.abs(a.x-b.x)+Math.abs(a.y-b.y)<S*.35){c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke()}}));ns.forEach((n,i)=>{c.fillStyle=`rgba(255,255,255,${.15+rng(i+200)*.2})`;c.beginPath();c.arc(n.x,n.y,4+rng(i+100)*8,0,Math.PI*2);c.fill()}) }

function drawFunnel(c: CanvasRenderingContext2D, S: number) { [{l:'T1 · Instant',cl:'rgba(100,220,150,0.3)',w:.7},{l:'T2 · Local LLM',cl:'rgba(255,200,80,0.25)',w:.5},{l:'T3 · Executive',cl:'rgba(255,100,80,0.2)',w:.3}].forEach((t,i)=>{const y=S*.28+i*(S*.18),w=S*t.w,x=(S-w)/2;c.fillStyle=t.cl;c.fillRect(x,y,w,S*.12);c.fillStyle='rgba(255,255,255,0.6)';c.font='bold 22px monospace';c.textAlign='center';c.textBaseline='middle';c.fillText(t.l,S/2,y+S*.06)}) }

function drawDashboard(c: CanvasRenderingContext2D, S: number) { c.fillStyle='rgba(0,0,0,0.3)';c.fillRect(S*.08,S*.15,S*.84,S*.6);c.fillStyle='rgba(255,255,255,0.08)';c.fillRect(S*.08,S*.15,S*.84,S*.06);c.fillStyle='rgba(255,255,255,0.5)';c.font='16px monospace';c.textAlign='left';c.fillText('RAJ SADAN · COMMAND CENTER',S*.12,S*.19);['Cortex','Senses','Cron','Knowledge','WhatsApp'].forEach((s,i)=>{const x=S*.1+i*95,y=S*.25;c.fillStyle='rgba(100,220,150,0.2)';c.fillRect(x,y,85,24);c.fillStyle='rgba(100,220,150,0.7)';c.font='12px monospace';c.textAlign='center';c.fillText(s,x+42,y+16)});for(let i=0;i<3;i++){const y=S*.35+i*55;c.fillStyle='rgba(255,255,255,0.05)';c.fillRect(S*.1,y,S*.8,42);c.fillStyle='rgba(255,255,255,0.25)';c.font='14px monospace';c.textAlign='left';c.fillText(['▸ Alert: Health check passed','▸ Briefing: Morning ready','▸ Metric: 68 capabilities'][i],S*.13,y+26)} }

function drawChat(c: CanvasRenderingContext2D, S: number) { c.strokeStyle='rgba(255,255,255,0.2)';c.lineWidth=2;const px=S*.25,py=S*.12,pw=S*.5;c.strokeRect(px,py,pw,S*.68);c.fillStyle='rgba(255,255,255,0.08)';c.fillRect(px,py,pw,S*.06);c.fillStyle='rgba(255,255,255,0.5)';c.font='bold 16px sans-serif';c.textAlign='center';c.fillText('Raj Sadan Bot',S/2,py+S*.04);[{t:'✓ All 11 services online',a:'left' as const,y:.24},{t:'/status',a:'right' as const,y:.34},{t:'☀ Morning briefing ready',a:'left' as const,y:.44},{t:'⚡ Cortex cycle: 14.2s',a:'left' as const,y:.54}].forEach(m=>{const bx=m.a==='left'?px+15:px+pw-200,by=S*m.y;c.fillStyle=m.a==='left'?'rgba(255,255,255,0.08)':'rgba(255,255,255,0.15)';c.fillRect(bx,by,185,32);c.fillStyle='rgba(255,255,255,0.6)';c.font='14px monospace';c.textAlign='left';c.fillText(m.t,bx+10,by+21)}) }

export function useProjectTexture(project: Project) {
  const texRef = useRef<THREE.CanvasTexture | null>(null)

  const tex = useMemo(() => {
    const S = 1024, cv = document.createElement('canvas'); cv.width = cv.height = S; const ctx = cv.getContext('2d')!
    drawBase(ctx, S, project.colors)
    switch (project.visual) { case 'mesh': drawMesh(ctx, S); break; case 'pipeline': drawPipeline(ctx, S); break; case 'timeline': drawTimeline(ctx, S); break; case 'graph': drawGraph(ctx, S); break; case 'funnel': drawFunnel(ctx, S); break; case 'dashboard': drawDashboard(ctx, S); break; case 'chat': drawChat(ctx, S); break }
    drawTitle(ctx, S, project.title); drawStats(ctx, S, project.stats)
    const t = new THREE.CanvasTexture(cv)
    texRef.current = t
    return t
  }, [project.title, project.colors, project.visual, project.stats])

  // Memory fix: dispose texture on unmount
  useEffect(() => {
    return () => { texRef.current?.dispose() }
  }, [tex])

  return tex
}
