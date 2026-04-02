/**
 * AudioEngine — Hybrid audio: real ambient loops + procedural UI sounds
 * Ambient: MP3 loops per section (gallery-piano, testimonials-pad, skills-electronic)
 * UI: Web Audio API synthesized sounds (hover, click, whoosh, clack, boot)
 */

export type SectionName = 'gallery' | 'testimonials' | 'skills' | 'none'

const AMBIENT_TRACKS: Record<Exclude<SectionName, 'none'>, string> = {
  gallery: '/audio/gallery-piano.mp3',
  testimonials: '/audio/testimonials-pad.mp3',
  skills: '/audio/skills-electronic.mp3',
}

// Free lofi radio stream — plays in gallery section via HTML5 Audio
const LOFI_STREAM_URL = 'https://play.streamafrica.net/lofiradio'

export class AudioEngine {
  private ctx: AudioContext | null = null
  private masterGain: GainNode | null = null
  private ambientGain: GainNode | null = null
  private uiGain: GainNode | null = null
  private currentAmbient: OscillatorNode[] = []
  private currentNoises: AudioBufferSourceNode[] = []
  private currentTrack: AudioBufferSourceNode | null = null
  private trackBuffers: Map<string, AudioBuffer> = new Map()
  private currentSection: SectionName = 'none'
  private _muted = false
  private _initialized = false
  private lofiAudio: HTMLAudioElement | null = null
  private lofiActive = false

  get muted() { return this._muted }

  /** Initialize AudioContext (must be called after user gesture for autoplay) */
  init() {
    if (this._initialized) return
    try {
      this.ctx = new AudioContext()
      this.masterGain = this.ctx.createGain()
      this.masterGain.gain.value = 1.0
      this.masterGain.connect(this.ctx.destination)

      this.ambientGain = this.ctx.createGain()
      this.ambientGain.gain.value = 0
      this.ambientGain.connect(this.masterGain)

      this.uiGain = this.ctx.createGain()
      this.uiGain.gain.value = 0.6
      this.uiGain.connect(this.masterGain)

      this._initialized = true
    } catch {
      console.warn('[Audio] Web Audio API not available')
    }
  }

  /** Resume context if suspended (browser autoplay policy) */
  private async ensureRunning() {
    if (!this.ctx) return false
    if (this.ctx.state === 'suspended') {
      try { await this.ctx.resume() } catch { return false }
    }
    return true
  }

  /** Set muted state */
  setMuted(muted: boolean) {
    this._muted = muted
    if (!this.masterGain || !this.ctx) return
    this.masterGain.gain.setTargetAtTime(
      muted ? 0 : 1.0,
      this.ctx.currentTime,
      0.15
    )
    // Sync lofi stream volume with mute state
    if (this.lofiAudio) {
      if (muted) this.lofiAudio.volume = 0
      else if (this.lofiActive) this.fadeLofi(0.25, 300)
    }
  }

  /** Toggle mute */
  toggleMute(): boolean {
    this.setMuted(!this._muted)
    return this._muted
  }

  // ─── Ambient Scores ───────────────────────────────────

  /** Crossfade to a new section's ambient score */
  async setSection(section: SectionName) {
    if (section === this.currentSection) return
    if (!this.ctx || !this.ambientGain) { this.init(); if (!this.ctx) return }
    await this.ensureRunning()

    // Fade out current
    this.ambientGain!.gain.setTargetAtTime(0, this.ctx!.currentTime, 0.4)

    // Manage lofi radio for gallery section
    if (section === 'gallery') this.startLofi()
    else this.stopLofi()

    // Wait for fade out
    setTimeout(() => {
      this.stopAmbient()
      this.currentSection = section
      if (section === 'none') return

      // Start new ambient track from file
      this.startAmbientTrack(section as Exclude<SectionName, 'none'>)

      // Fade in
      this.ambientGain!.gain.setTargetAtTime(1.0, this.ctx!.currentTime, 0.5)
    }, 500)
  }

  /** Start lofi radio stream */
  private startLofi() {
    if (this.lofiActive) return
    this.lofiActive = true
    if (!this.lofiAudio) {
      this.lofiAudio = new Audio(LOFI_STREAM_URL)
      this.lofiAudio.crossOrigin = 'anonymous'
      this.lofiAudio.loop = true
      this.lofiAudio.volume = 0
    }
    this.lofiAudio.play().catch(() => {})
    this.fadeLofi(0.25, 2000)
  }

  /** Stop lofi radio stream */
  private stopLofi() {
    if (!this.lofiActive || !this.lofiAudio) return
    this.lofiActive = false
    this.fadeLofi(0, 1000, () => { this.lofiAudio?.pause() })
  }

  /** Fade lofi audio volume smoothly */
  private fadeLofi(target: number, durationMs: number, onDone?: () => void) {
    if (!this.lofiAudio) { onDone?.(); return }
    const start = this.lofiAudio.volume
    const startTime = performance.now()
    const step = () => {
      if (!this.lofiAudio) { onDone?.(); return }
      const elapsed = performance.now() - startTime
      const t = Math.min(elapsed / durationMs, 1)
      this.lofiAudio.volume = start + (target - start) * t
      if (t < 1) requestAnimationFrame(step)
      else onDone?.()
    }
    requestAnimationFrame(step)
  }

  private stopAmbient() {
    this.currentAmbient.forEach(osc => { try { osc.stop() } catch {} })
    this.currentNoises.forEach(n => { try { n.stop() } catch {} })
    if (this.currentTrack) { try { this.currentTrack.stop() } catch {} }
    this.currentAmbient = []
    this.currentNoises = []
    this.currentTrack = null
  }

  /** Load and cache an audio file as AudioBuffer */
  private async loadTrack(url: string): Promise<AudioBuffer | null> {
    if (this.trackBuffers.has(url)) return this.trackBuffers.get(url)!
    if (!this.ctx) return null
    try {
      const response = await fetch(url)
      const arrayBuffer = await response.arrayBuffer()
      const audioBuffer = await this.ctx.decodeAudioData(arrayBuffer)
      this.trackBuffers.set(url, audioBuffer)
      return audioBuffer
    } catch (e) {
      console.warn('[Audio] Failed to load track:', url, e)
      return null
    }
  }

  /** Start a looping ambient track from file */
  private async startAmbientTrack(section: Exclude<SectionName, 'none'>) {
    if (!this.ctx || !this.ambientGain) return
    const url = AMBIENT_TRACKS[section]
    const buffer = await this.loadTrack(url)
    if (!buffer) return

    const source = this.ctx.createBufferSource()
    source.buffer = buffer
    source.loop = true
    source.connect(this.ambientGain)
    source.start()
    this.currentTrack = source
  }

  // ─── UI Sounds ────────────────────────────────────────

  /** Soft resonant ping — gallery frame hover */
  playHoverPing() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const osc = this.ctx.createOscillator()
    osc.type = 'sine'
    osc.frequency.value = 1200 + Math.random() * 400
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.08, this.ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.15)
    osc.connect(g).connect(this.uiGain)
    osc.start()
    osc.stop(this.ctx.currentTime + 0.15)
  }

  /** Camera shutter click — gallery frame focus */
  playShutterClick() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const noise = this.createNoise(0.08)
    const filter = this.ctx.createBiquadFilter()
    filter.type = 'highpass'
    filter.frequency.value = 3000
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.15, this.ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.08)
    noise.connect(filter).connect(g).connect(this.uiGain)
    noise.start()
    noise.stop(this.ctx.currentTime + 0.08)
  }

  /** Scroll tick — subtle granular tick */
  playScrollTick() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const osc = this.ctx.createOscillator()
    osc.type = 'sine'
    osc.frequency.value = 800
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.03, this.ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.03)
    osc.connect(g).connect(this.uiGain)
    osc.start()
    osc.stop(this.ctx.currentTime + 0.03)
  }

  /** Whoosh — transition between sections (noise sweep) */
  playTransitionWhoosh(direction: 'forward' | 'reverse' = 'forward') {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const noise = this.createNoise(0.8)
    const filter = this.ctx.createBiquadFilter()
    filter.type = 'bandpass'
    filter.Q.value = 2
    const now = this.ctx.currentTime
    if (direction === 'forward') {
      filter.frequency.setValueAtTime(200, now)
      filter.frequency.exponentialRampToValueAtTime(4000, now + 0.6)
    } else {
      filter.frequency.setValueAtTime(4000, now)
      filter.frequency.exponentialRampToValueAtTime(200, now + 0.6)
    }
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.12, now)
    g.gain.setValueAtTime(0.12, now + 0.3)
    g.gain.exponentialRampToValueAtTime(0.001, now + 0.8)
    noise.connect(filter).connect(g).connect(this.uiGain)
    noise.start()
    noise.stop(now + 0.8)
  }

  /** Mechanical clack — keyboard key hover */
  playKeyClack() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const noise = this.createNoise(0.04)
    const filter = this.ctx.createBiquadFilter()
    filter.type = 'bandpass'
    filter.frequency.value = 2500
    filter.Q.value = 3
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.1, this.ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.04)
    noise.connect(filter).connect(g).connect(this.uiGain)
    noise.start()
    noise.stop(this.ctx.currentTime + 0.04)
  }

  /** Rising tone sweep — boot-up power-on */
  playBootSweep() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const osc = this.ctx.createOscillator()
    osc.type = 'sawtooth'
    const now = this.ctx.currentTime
    osc.frequency.setValueAtTime(80, now)
    osc.frequency.exponentialRampToValueAtTime(800, now + 1.2)
    const filter = this.ctx.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.setValueAtTime(200, now)
    filter.frequency.exponentialRampToValueAtTime(2000, now + 1.0)
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.06, now)
    g.gain.setValueAtTime(0.06, now + 0.8)
    g.gain.exponentialRampToValueAtTime(0.001, now + 1.5)
    osc.connect(filter).connect(g).connect(this.uiGain)
    osc.start()
    osc.stop(now + 1.5)
  }

  /** Soft click — button hover */
  playButtonClick() {
    if (!this.ctx || !this.uiGain || this._muted) return
    this.ensureRunning()
    const osc = this.ctx.createOscillator()
    osc.type = 'sine'
    osc.frequency.value = 600
    const g = this.ctx.createGain()
    g.gain.setValueAtTime(0.05, this.ctx.currentTime)
    g.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.06)
    osc.connect(g).connect(this.uiGain)
    osc.start()
    osc.stop(this.ctx.currentTime + 0.06)
  }

  // ─── Utility ──────────────────────────────────────────

  /** Create a white noise buffer source */
  private createNoise(duration: number): AudioBufferSourceNode {
    const sampleRate = this.ctx!.sampleRate
    const length = sampleRate * duration
    const buffer = this.ctx!.createBuffer(1, length, sampleRate)
    const data = buffer.getChannelData(0)
    for (let i = 0; i < length; i++) {
      data[i] = Math.random() * 2 - 1
    }
    const source = this.ctx!.createBufferSource()
    source.buffer = buffer
    source.loop = true
    return source
  }

  /** Cleanup */
  dispose() {
    this.stopAmbient()
    this.stopLofi()
    if (this.lofiAudio) { this.lofiAudio.src = ''; this.lofiAudio = null }
    if (this.ctx && this.ctx.state !== 'closed') {
      this.ctx.close()
    }
    this._initialized = false
  }
}
