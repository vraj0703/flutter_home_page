/**
 * AudioEngine — Procedural UI sounds via Web Audio API
 * Synthesized sounds: hover ping, shutter click, scroll tick, whoosh, clack, boot sweep, button click
 */

export type SectionName = 'gallery' | 'testimonials' | 'skills' | 'none'

export class AudioEngine {
  private ctx: AudioContext | null = null
  private masterGain: GainNode | null = null
  private uiGain: GainNode | null = null
  private currentSection: SectionName = 'none'
  private _muted = false
  private _initialized = false

  get muted() { return this._muted }

  /** Initialize AudioContext (must be called after user gesture for autoplay) */
  init() {
    if (this._initialized) return
    try {
      this.ctx = new AudioContext()
      this.masterGain = this.ctx.createGain()
      this.masterGain.gain.value = 1.0
      this.masterGain.connect(this.ctx.destination)

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
  }

  /** Toggle mute */
  toggleMute(): boolean {
    this.setMuted(!this._muted)
    return this._muted
  }

  /** Track current section (no ambient audio) */
  async setSection(section: SectionName) {
    this.currentSection = section
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
    if (this.ctx && this.ctx.state !== 'closed') {
      this.ctx.close()
    }
    this._initialized = false
  }
}
