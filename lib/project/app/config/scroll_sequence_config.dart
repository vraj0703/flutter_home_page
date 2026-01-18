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
  static const int enterTitleDelay = 500;

  static const int sceneFadeDurationMs = 500;
  static const int sceneLoadingBlinkDurationMs = 1000;
  static const int sceneArrowBounceDurationMs = 1500;
  static const int sceneArrowFadeDurationMs = 300;

  static const double titleRevealDelay = 1.0;
  static const double titleAnimDuration = 4.0;
  static const double titleMoveDuration = 1.0;

  // --- Global UI Timings ---
  static const double inactivityTimeout = 5.0;
  static const double uiFadeDuration = 0.5;
  static const int uiFadeDurationMs = 500;

  // --- Duration Objects ---
  static const Duration enterTitleDelayDuration = Duration(
    milliseconds: enterTitleDelay,
  );
  static const Duration uiFadeDurationObj = Duration(
    milliseconds: uiFadeDurationMs,
  );
  static const Duration sceneFadeDurationObj = Duration(
    milliseconds: sceneFadeDurationMs,
  );
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

  // --- 2.5. Work Experience Title Section (3300 - 4100) ---
  // Overlaps with philosophy exit (3300 starts while philosophy exits at 3200-3500)
  static const double workExpTitleEntranceStart = 3300.0;
  static const double workExpTitleEntranceDuration = 350.0;
  static double get workExpTitleEntranceEnd =>
      workExpTitleEntranceStart + workExpTitleEntranceDuration; // 3650

  static const double workExpTitleHoldStart = 3650.0;
  static const double workExpTitleHoldDuration = 250.0;
  static double get workExpTitleHoldEnd =>
      workExpTitleHoldStart + workExpTitleHoldDuration; // 3900

  static const double workExpTitleExitStart = 3900.0;
  static const double workExpTitleExitDuration = 200.0;
  static double get workExpTitleExitEnd =>
      workExpTitleExitStart + workExpTitleExitDuration; // 4100

  // --- 3. Experience Section (4000 - 6450) ---
  // Fade in overlaps with Work Exp Title exit (starts at 4000, title ends at 4100)
  static const double experienceEntranceStart = 4000.0;
  static const double experienceInteractionStart =
      4300.0; // +300 -> 4000 + 300 = 4300
  // Length based on content (5 items * 350 = 1750)
  static const double experienceInteractionDuration = 1750.0;
  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 6050
  static double get experienceExitStart => experienceInteractionEnd; // 6050
  static double get experienceExitEnd => experienceExitStart + 350.0; // 6400

  static const double experienceScrollDivisor = 500.0;

  // --- 4. Testimonials (6600 - 10800) ---
  // Wait 200px after Experience (6400 -> 6600)
  static const double testimonialEntranceStart = 6600.0;
  static const double testimonialInteractionStart =
      6900.0; // +300 -> 6600 + 300 = 6900
  static const double testimonialVisibleDuration = 3500.0;
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 10400
  static double get testimonialExitStart => testimonialInteractionEnd; // 10400
  static double get testimonialExitEnd => testimonialExitStart + 400.0; // 10800

  // --- 5. Skills (11000 - 13000) ---
  // Wait 200px after Testimonial End (10800 -> 11000)
  static const double skillsEntranceStart = 11000.0;
  static const double skillsEntranceEnd =
      11400.0; // +400 -> 11000 + 400 = 11400
  static const double skillsInteractEnd =
      12600.0; // Hold -> 11400 + 1200 = 12600
  static const double skillsExitEnd =
      13000.0; // Exit -> 12600 + 400 = 13000

  // --- 6. Contact (13200+) ---
  // Wait 200px after Skills End (13000 -> 13200)
  static const double contactEntranceStart = 13200.0;
  static const double contactEntranceDuration = 600.0;
  static const double contactHoldDuration = 1000.0;
  static const double contactExitDuration = 600.0;

  static const double contactVisibleStart =
      contactEntranceStart + contactEntranceDuration;
  static const double contactExitStart =
      contactVisibleStart + contactHoldDuration;
  static const double contactExitEnd = contactExitStart + contactExitDuration;

  // --- Scroll Transition offsets ---
  static const double experienceFadeOffset = 300.0;
  static const double experienceExitFadeOffset = 350.0;

  static const double philosophyTransitionOffset = 400.0;

  static const double testimonialFadeOffset = 300.0;
  // --- UI Config ---
  static const double uiFadeDistance = 100.0;
  static const double dimLayerFinalAlpha = 0.6;

  // --- Logo Overlay Scene Progress Thresholds --- (Not scroll based, but sequence based)
  static const double logoOverlayRevealStart = 0.2;
  static const double logoOverlayLinesStart = 0.4;
  static const double logoOverlayTextStart = 0.5;

  // --- Carousel Timing ---
  static const double carouselEnterDuration = 0.8;
  static const double carouselExitDuration = 0.6;
  static const double carouselScrollDuration = 0.7;
  static const double testimonialExitDuration = 400.0;

  static const double boldTextDriftOffset = 50.0;
}
