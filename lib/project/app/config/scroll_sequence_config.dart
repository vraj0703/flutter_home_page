class ScrollSequenceConfig {
  // --- 0. Intro / Title Section ---
  static const double titleParallaxEnd = 800.0;
  static const double secondaryTitleParallaxEnd = 1000.0;
  static const double titleFadeEnd = 500.0;
  static const double secondaryTitleFadeEnd = 100.0;
  static const double uiFadeEnd = 100.0;

  // --- Intro Animation Durations (ms) ---
  static const int sceneRevealDuration = 2000;
  static const int loadingBlinkDuration = 600;
  static const int arrowBounceDuration = 1500;

  // --- 1. Bold Text Section (0 - 1700) ---
  // Entrance: 400 -> 900
  static const double boldTextEntranceStart = 400.0;
  static const double boldTextEntranceDuration = 500.0;
  static double get boldTextEntranceEnd =>
      boldTextEntranceStart + boldTextEntranceDuration; // 900

  // Drift: 900 -> 1400
  static const double boldTextDriftStart = 900.0; // Matches entrance end
  static const double boldTextDriftDuration = 500.0;
  static double get boldTextDriftEnd =>
      boldTextDriftStart + boldTextDriftDuration; // 1400

  // Fade In: 500 -> 750
  static const double boldTextFadeInStart = 500.0;
  static const double boldTextFadeInDuration = 250.0;
  static double get boldTextFadeInEnd =>
      boldTextFadeInStart + boldTextFadeInDuration; // 750

  // Shine: 1050 -> 1400
  static const double boldTextShineStart = 1050.0;
  static const double boldTextShineDuration = 350.0;

  // Exit
  static const double boldTextStart = 0.0;
  static const double boldTextEnd = 1700.0;
  static const double boldTextFadeOutRegion =
      200.0; // How far from end to start fading out

  // --- Dim Layer (1500 - 2000) ---
  static const double dimLayerStart = 1500.0;
  static const double dimLayerEnd = 2000.0;

  // --- 2. Philosophy Section (1900 - 3500) ---
  // Wait 200px after Bold Text (1700 -> 1900)
  static const double philosophyStart = 1900.0;
  static const double philosophyEnd = 3500.0;

  // Internal Philosophy Stages (+200 shift)
  static const double philosophyFadeInEnd = 2300.0; // +400 -> 2100 + 200 = 2300
  static const double philosophyPeelStart = 2350.0; // +450 -> 2150 + 200 = 2350
  static const double philosophyPeelDuration = 250.0;
  static const double philosophyPeelDelay = 150.0;
  static const double philosophyExitStart =
      3200.0; // End - 300 -> 3500 - 300 = 3200

  // --- 3. Experience Section (3700 - 6100) ---
  // Wait 200px after Philosophy (3500 -> 3700)
  static const double experienceEntranceStart = 3700.0;
  static const double experienceInteractionStart =
      4000.0; // +300 -> 3700 + 300 = 4000
  // Length based on content (5 items * 350 = 1750)
  static const double experienceInteractionDuration = 1750.0;
  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 5750
  static double get experienceExitStart => experienceInteractionEnd; // 5750
  static double get experienceExitEnd => experienceExitStart + 350.0; // 6100

  // --- 4. Testimonials (6300 - 10500) ---
  // Wait 200px after Experience (6100 -> 6300)
  static const double testimonialEntranceStart = 6300.0;
  static const double testimonialInteractionStart =
      6600.0; // +300 -> 6300 + 300 = 6600
  static const double testimonialVisibleDuration = 3500.0;
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 10100
  static double get testimonialExitStart => testimonialInteractionEnd; // 10100
  static double get testimonialExitEnd => testimonialExitStart + 400.0; // 10500

  // --- 5. Skills (10700 - 12700) ---
  // Wait 200px after Testimonial End (10500 -> 10700)
  static const double skillsEntranceStart = 10700.0;
  static const double skillsEntranceEnd =
      11100.0; // +400 -> 10700 + 400 = 11100
  static const double skillsInteractEnd =
      12300.0; // Hold -> 11100 + (11500-10300) = 11100 + 1200 = 12300
  static const double skillsExitEnd =
      12700.0; // Exit -> 12300 + (11900-11500) = 12300 + 400 = 12700

  // --- 6. Contact (12900+) ---
  // Wait 200px after Skills End (12700 -> 12900)
  static const double contactEntranceStart = 12900.0;
  static const double contactEntranceDuration = 600.0;
  static const double contactHoldDuration = 1000.0;
  static const double contactExitDuration = 600.0;

  static double get contactVisibleStart =>
      contactEntranceStart + contactEntranceDuration;
  static double get contactExitStart =>
      contactVisibleStart + contactHoldDuration;
  static double get contactExitEnd => contactExitStart + contactExitDuration;
}
