/**
 * RadioEngine — Streaming radio state management.
 * Extracted from GalleryScene.tsx for separation of concerns.
 */

const RADIO_CHANNELS = [
  { name: 'Lofi', url: 'https://ice5.somafm.com/lush-128-mp3' },
  { name: 'Jazz', url: 'https://ice4.somafm.com/secretagent-128-mp3' },
  { name: 'Ambient', url: 'https://ice5.somafm.com/groovesalad-128-mp3' },
  { name: 'Chill', url: 'https://ice2.somafm.com/seventies-128-mp3' },
]

let _radioAudio: HTMLAudioElement | null = null
let _radioPlaying = false
let _radioMuted = false
let _radioVolume = 0.25
let _radioChannel = 0
let _radioLoading = false
let _radioListeners: Array<() => void> = []

function _notifyRadio() { _radioListeners.forEach(fn => fn()) }

export function preloadRadio() {
  if (_radioAudio) return
  _radioAudio = new Audio(RADIO_CHANNELS[0].url)
  _radioAudio.crossOrigin = 'anonymous'
  _radioAudio.volume = _radioVolume
  _radioAudio.preload = 'auto'
  _radioAudio.load()
}

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
  if (_radioAudio) {
    _radioAudio.pause()
    _radioAudio.src = ''       // Close streaming connection (memory fix)
    _radioAudio.load()         // Force the element to release buffered data
    _radioAudio = null         // Null so _playRadio's !_radioAudio guard triggers
    // and preloadRadio() creates a fresh element on next play. Without this,
    // play() would fail silently because src is empty but the element exists.
  }
  _radioPlaying = false
  _radioLoading = false
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

export function startRadioOnGalleryEnter() {
  if (!_radioPlaying && !_radioLoading) _playRadio()
}

export function subscribeRadio(fn: () => void) {
  _radioListeners.push(fn)
  return () => { _radioListeners = _radioListeners.filter(f => f !== fn) }
}

export function getRadioState() {
  return { playing: _radioPlaying, muted: _radioMuted, loading: _radioLoading, channel: RADIO_CHANNELS[_radioChannel].name, volume: _radioVolume }
}

export { RADIO_CHANNELS, _playRadio }
