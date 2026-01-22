class GameAudioConfig {
  // Folder structure assumes assets/audio/
  static const String prefix = 'audio/';

  // BGM
  static const String ambientBgm = 'space_ambient.mp3';

  // SFX
  static const String hoverSfx = 'hover.mp3';
  static const String clickSfx = 'click.mp3';
  static const String enterSfx = 'enter_sound.wav';
  static const String titleLoadedSfx = 'title_loaded.wav';
  static const String slideInSfx = 'slide_in.wav';
  static const String bouncyArrowSfx = 'bouncy_arrow.wav';
  static const String boldTextSwell = 'bold_text_swell.mp3';
  static const String tingSfx = 'ting.wav';
  static const String scrollTickSfx = 'scroll_tick.mp3'; // Optional
  static const String philosophyEntrySfx = 'do.wav'; // Philosophy section entry

  // Volumes
  static const double bgmVolume = 0.4;
  static const double sfxVolume = 0.6;
  static const double enterSfxVolume = 0.8; // Slightly louder for impact
  static const double titleLoadedVolume = 0.7;
  static const double hoverVolume = 0.3; // Lower for subtlety

  // Throttling (avoid spamming hover sounds)
  static const int hoverThrottleMs = 100;
}
