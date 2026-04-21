/**
 * Typed Flutter-React communication bridge.
 * Replaces raw postMessage with versioned, queued, acknowledged messages.
 *
 * Security: inbound messages are filtered by `event.origin` — only same-origin
 * messages are processed. Prevents a malicious iframe or browser extension
 * from spoofing `flutter-handoff` to force-navigate the user out of Flutter.
 */

const PROTOCOL_VERSION = '2.0'

/* ── Message types ────────────────────────────────── */

export type FlutterInboundType =
  | 'flutter-loading'
  | 'flutter-ready'
  | 'flutter-handoff'
  | 'flutter-error'

export type ReactOutboundType =
  | 'navigate'
  | 'flutter-pause'
  | 'flutter-resume'
  | 'theme-change'
  | 'reduced-motion'
  | 'ack'

export interface BridgeMessage {
  type: string
  version: string
  correlationId?: string
  timestamp: number
}

export interface FlutterReadyPayload extends BridgeMessage {
  type: 'flutter-ready'
  renderer?: string
  wasmEnabled?: boolean
}

export interface FlutterLoadingPayload extends BridgeMessage {
  type: 'flutter-loading'
  progress: number
}

export interface NavigatePayload extends BridgeMessage {
  type: 'navigate'
  route: 'home' | 'contact'
}

/* ── Event callback types ─────────────────────────── */

type ReadyCallback = (payload: FlutterReadyPayload) => void
type HandoffCallback = () => void
type ErrorCallback = (payload: BridgeMessage) => void
type LoadingCallback = (progress: number) => void

/* ── Bridge class ─────────────────────────────────── */

export class FlutterBridge {
  private iframe: HTMLIFrameElement | null = null
  private messageQueue: Record<string, unknown>[] = []
  private isReady = false
  private readyTimeout: ReturnType<typeof setTimeout> | null = null

  // Callbacks
  private onReadyCbs: ReadyCallback[] = []
  private onHandoffCbs: HandoffCallback[] = []
  private onErrorCbs: ErrorCallback[] = []
  private onLoadingCbs: LoadingCallback[] = []
  private onTimeoutCbs: Array<() => void> = []

  private handoffTriggered = false
  private boundHandler: (e: MessageEvent) => void

  constructor() {
    this.boundHandler = this.handleMessage.bind(this)
    window.addEventListener('message', this.boundHandler)
  }

  /** Attach the iframe element — drains any queued messages */
  attach(iframe: HTMLIFrameElement) {
    this.iframe = iframe
    this.drainQueue()
  }

  /** Start a timeout: if Flutter doesn't fire 'flutter-ready' within ms, fire onTimeout */
  startReadyTimeout(ms = 4000) {
    this.readyTimeout = setTimeout(() => {
      if (!this.isReady) {
        this.onTimeoutCbs.forEach(fn => fn())
      }
    }, ms)
  }

  /* ── Event subscriptions ────────────────────────── */

  onReady(fn: ReadyCallback) { this.onReadyCbs.push(fn); return () => { this.onReadyCbs = this.onReadyCbs.filter(f => f !== fn) } }
  onHandoff(fn: HandoffCallback) { this.onHandoffCbs.push(fn); return () => { this.onHandoffCbs = this.onHandoffCbs.filter(f => f !== fn) } }
  onError(fn: ErrorCallback) { this.onErrorCbs.push(fn); return () => { this.onErrorCbs = this.onErrorCbs.filter(f => f !== fn) } }
  onLoading(fn: LoadingCallback) { this.onLoadingCbs.push(fn); return () => { this.onLoadingCbs = this.onLoadingCbs.filter(f => f !== fn) } }
  onTimeout(fn: () => void) { this.onTimeoutCbs.push(fn); return () => { this.onTimeoutCbs = this.onTimeoutCbs.filter(f => f !== fn) } }

  /* ── Outbound messages ──────────────────────────── */

  /**
   * Route-change methods. These emit the concrete message types that today's
   * Flutter build handles (goto-home, goto-contact). The generic `navigate()`
   * below sends a versioned `{type:'navigate', route}` for future Flutter
   * builds that move to the typed protocol — current Flutter ignores it, so
   * don't call it yet.
   */
  gotoHome() {
    this.send({ type: 'goto-home', version: PROTOCOL_VERSION, timestamp: Date.now() })
  }

  gotoContact() {
    this.send({ type: 'goto-contact', version: PROTOCOL_VERSION, timestamp: Date.now() })
    // Parent-side scroll workaround: reset the iframe's viewport scroll
    // position. Conceptually this belongs inside Flutter — once Flutter ships
    // a `scroll-reset` handler this can move to a message and delete the
    // direct contentWindow reach-in.
    try {
      this.iframe?.contentWindow?.scrollTo(0, 0)
    } catch {
      // cross-origin — iframe may be on a different domain in the future
    }
  }

  /** Versioned successor to gotoHome/gotoContact. Not wired in Flutter yet. */
  navigate(route: 'home' | 'contact') {
    this.send({
      type: 'navigate',
      version: PROTOCOL_VERSION,
      route,
      timestamp: Date.now(),
    })
  }

  pause() {
    this.send({ type: 'flutter-pause', version: PROTOCOL_VERSION, timestamp: Date.now() })
  }

  resume() {
    this.send({ type: 'flutter-resume', version: PROTOCOL_VERSION, timestamp: Date.now() })
  }

  sendReducedMotion(enabled: boolean) {
    this.send({ type: 'reduced-motion', version: PROTOCOL_VERSION, enabled, timestamp: Date.now() } as Record<string, unknown>)
  }

  /* ── Visibility control (GSAP-free — managed by FlutterEmbed) ── */

  get ready() { return this.isReady }

  /* ── Inbound message handler ────────────────────── */

  private handleMessage(event: MessageEvent) {
    // Security: only accept same-origin messages. Browser extensions and
    // third-party iframes can post to our window — without this check they
    // could spoof flutter-handoff and force a phase transition.
    if (event.origin !== window.location.origin) return

    const data = event.data
    if (!data || typeof data !== 'object') return

    const type = data.type as string
    if (!type || typeof type !== 'string') return

    // Accept both legacy (no version) and v2 messages
    // Legacy messages: flutter-loading, flutter-ready, flutter-handoff (from current Flutter code)
    // V2 messages: include version field

    switch (type) {
      case 'flutter-loading': {
        const progress = typeof data.progress === 'number' ? Math.max(0, Math.min(1, data.progress)) : 0
        this.onLoadingCbs.forEach(fn => fn(progress))
        break
      }
      case 'flutter-ready': {
        this.isReady = true
        if (this.readyTimeout) { clearTimeout(this.readyTimeout); this.readyTimeout = null }
        this.drainQueue()
        const payload: FlutterReadyPayload = {
          type: 'flutter-ready',
          version: data.version || '1.0',
          renderer: data.renderer,
          wasmEnabled: data.wasmEnabled,
          timestamp: Date.now(),
        }
        this.onReadyCbs.forEach(fn => fn(payload))
        break
      }
      case 'flutter-handoff': {
        if (!this.handoffTriggered) {
          this.handoffTriggered = true
          this.onHandoffCbs.forEach(fn => fn())
        }
        break
      }
      case 'flutter-error': {
        this.onErrorCbs.forEach(fn => fn(data as BridgeMessage))
        break
      }
    }
  }

  /* ── Send with queue ────────────────────────────── */

  private send(message: Record<string, unknown>) {
    if (!this.iframe?.contentWindow || !this.isReady) {
      this.messageQueue.push(message)
      return
    }
    this.iframe.contentWindow.postMessage(message, window.location.origin)
  }

  private drainQueue() {
    if (!this.isReady || !this.iframe?.contentWindow) return
    while (this.messageQueue.length > 0) {
      const msg = this.messageQueue.shift()!
      this.iframe.contentWindow.postMessage(msg, window.location.origin)
    }
  }

  /** Reset handoff state (for phase transitions back to Flutter) */
  resetHandoff() {
    this.handoffTriggered = false
  }

  /** Clean up listener */
  dispose() {
    window.removeEventListener('message', this.boundHandler)
    if (this.readyTimeout) clearTimeout(this.readyTimeout)
  }
}

/** Singleton bridge instance */
export const flutterBridge = new FlutterBridge()
