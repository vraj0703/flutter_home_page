class GameAudioConfig {
  // Folder structure assumes assets/audio/
  static const String prefix = 'audio/';

  // BGM (removed — space_ambient.mp3 was 37.8 MB, too large for web)

  // SFX
  static const String hoverSfx = 'hover.mp3';
  static const String clickSfx = 'click.mp3';
  static const String enterSfx = 'enter_sound.mp3';
  static const String titleLoadedSfx = 'title_loaded.mp3';
  static const String slideInSfx = 'slide_in.mp3';
  static const String bouncyArrowSfx = 'bouncy_arrow.mp3';
  static const String boldTextSwell = 'bold_text_swell.mp3';
  static const String tingSfx = 'ting.mp3';
  static const String scrollTickSfx = 'scroll_tick.mp3'; // Optional
  static const String contactEntrySfx = 'do.mp3'; // Title (Do)
  static const String contactCompleteSfx =
      're.mp3'; // (Deprecated reuse, or re-purpose)

  // Trail Card SFX (Sequential Scale)
  static const String trailCard1Sfx = 're.mp3'; // Card 1 (Re)
  static const String trailCard2Sfx = 'mi.mp3'; // Card 2 (Mi)
  static const String trailCard3Sfx = 'fa.mp3'; // Card 3 (Fa)
  static const String trailCard4Sfx = 'si.mp3'; // Card 4 (Si)

  static const String contactButtonSfx = 'sol.mp3'; // Button (Sol)
  static const String waterdropSfx = 'waterdrop.mp3'; // User requested
  static const String glassBreakSfx = 'glass_break.mp3';
  static const String thunderCrackSfx = 'thunder_crack.mp3';
  static const String thunderRollSfx = 'thunder_roll.mp3';

  // Glass Clockwork SFX
  static const String gearTickSfx = 'ting.mp3'; // Replaced missing gear_tick
  static const String selectionClickSfx =
      'bouncy_arrow.mp3'; // Replaced missing selection_click
  // ambientBreeze removed — was alias to space_ambient.mp3 (too large for web)

  // Volumes
  static const double bgmVolume = 0.4;
  static const double sfxVolume = 0.6;
  static const double enterSfxVolume = 0.8; // Slightly louder for impact
  static const double titleLoadedVolume = 0.7;
  static const double hoverVolume = 0.3; // Lower for subtlety

  // Throttling (avoid spamming hover sounds)
  static const int hoverThrottleMs = 100;
}
