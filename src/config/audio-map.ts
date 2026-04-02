export const AUDIO = {
  titleLoaded: '/audio/title_loaded.mp3',
  harpEnter: '/audio/harp_enter.mp3',
  boldText: '/audio/bold_text.mp3',
  enterSound: '/audio/enter_sound.mp3',
  bouncyArrow: '/audio/bouncy_arrow.mp3',
  whoosh: '/audio/whoosh.mp3',
  slideIn: '/audio/slide_in.mp3',
  ting: '/audio/ting.mp3',
  rumble: '/audio/rumble.mp3',
  waterdrop: '/audio/waterdrop.mp3',
  do: '/audio/do.mp3',
  re: '/audio/re.mp3',
  mi: '/audio/mi.mp3',
  fa: '/audio/fa.mp3',
  sol: '/audio/sol.mp3',
  si: '/audio/si.mp3',
} as const

export type AudioId = keyof typeof AUDIO
