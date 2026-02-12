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
  static const String philosophyEntrySfx = 'do.wav'; // Title (Do)
  static const String philosophyCompleteSfx =
      're.wav'; // (Deprecated reuse, or re-purpose)

  // Trail Card SFX (Sequential Scale)
  static const String trailCard1Sfx = 're.wav'; // Card 1 (Re)
  static const String trailCard2Sfx = 'mi.wav'; // Card 2 (Mi)
  static const String trailCard3Sfx = 'fa.wav'; // Card 3 (Fa)
  static const String trailCard4Sfx = 'si.wav'; // Card 4 (Si)

  static const String philosophyButtonSfx = 'sol.wav'; // Button (Sol)
  static const String waterdropSfx = 'waterdrop.wav'; // User requested
  static const String glassBreakSfx = 'glass_break.mp3';
  static const String thunderCrackSfx = 'thunder_crack.mp3';
  static const String thunderRollSfx = 'thunder_roll.wav';

  // Glass Clockwork SFX
  static const String gearTickSfx = 'ting.wav'; // Replaced missing gear_tick
  static const String selectionClickSfx =
      'bouncy_arrow.wav'; // Replaced missing selection_click
  static const String ambientBreeze =
      'space_ambient.mp3'; // Replaced missing ambient_breeze

  // Volumes
  static const double bgmVolume = 0.4;
  static const double sfxVolume = 0.6;
  static const double enterSfxVolume = 0.8; // Slightly louder for impact
  static const double titleLoadedVolume = 0.7;
  static const double hoverVolume = 0.3; // Lower for subtlety

  // Throttling (avoid spamming hover sounds)
  static const int hoverThrottleMs = 100;
}
