export { AudioEngine } from './AudioEngine'
export { AudioProvider, useAudio } from './AudioProvider'
export { AudioToggle } from './AudioToggle'

/**
 * Module-level audio engine instance for use inside Three.js Canvas contexts
 * where React hooks (useAudio) aren't available.
 *
 * The AudioProvider creates and manages the lifecycle of this instance.
 */
import { AudioEngine } from './AudioEngine'

let _sharedEngine: AudioEngine | null = null

export function setSharedAudioEngine(engine: AudioEngine) {
  _sharedEngine = engine
}

/** Get the shared engine for non-React contexts (Three.js useFrame, etc.) */
export function getAudioEngine(): AudioEngine | null {
  return _sharedEngine
}
