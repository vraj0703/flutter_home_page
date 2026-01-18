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

  // --- Transition Gap: Philosophy -> Work Experience (3500 - 3600) ---
  static const double philosophyToWorkExpGap = 100.0;

  // --- 2.5. Work Experience Title Section (3600 - 5200) ---
  // Full page parallax entrance and exit with extended timing
  static const double workExpTitleEntranceStart = 3600.0;
  static const double workExpTitleEntranceDuration =
      600.0; // Extended for smoother parallax
  static double get workExpTitleEntranceEnd =>
      workExpTitleEntranceStart + workExpTitleEntranceDuration; // 4200

  static const double workExpTitleHoldStart = 4200.0;
  static const double workExpTitleHoldDuration = 500.0; // More time to appreciate
  static double get workExpTitleHoldEnd =>
      workExpTitleHoldStart + workExpTitleHoldDuration; // 4700

  static const double workExpTitleExitStart = 4700.0;
  static const double workExpTitleExitDuration =
      500.0; // Extended for smoother parallax
  static double get workExpTitleExitEnd =>
      workExpTitleExitStart + workExpTitleExitDuration; // 5200

  // --- Transition Gap: Work Experience -> Experience Section (5200 - 5300) ---
  static const double workExpToExperienceGap = 100.0;

  // --- 3. Experience Section (5300 - 7650) ---
  // Clean entrance AFTER work exp title fully exits
  static const double experienceEntranceStart = 5300.0;
  static const double experienceEntranceDuration = 300.0;

  static double get experienceEntranceEnd =>
      experienceEntranceStart + experienceEntranceDuration; // 5600
  static const double experienceInteractionStart =
      5600.0; // Starts after entrance completes
  // Length based on content (5 items * 350 = 1750)
  static const double experienceInteractionDuration = 1750.0;

  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 7350
  static double get experienceExitStart => experienceInteractionEnd; // 7350
  static const double experienceExitDuration = 300.0;

  static double get experienceExitEnd =>
      experienceExitStart + experienceExitDuration; // 7650

  static const double experienceScrollDivisor = 500.0;

  // --- Transition Gap: Experience -> Testimonials (7650 - 7750) ---
  static const double experienceToTestimonialGap = 100.0;

  // --- 4. Testimonials (7750 - 11650) ---
  // Clean entrance after experience fully exits
  static const double testimonialEntranceStart = 7750.0;
  static const double testimonialEntranceDuration = 300.0;

  static double get testimonialEntranceEnd =>
      testimonialEntranceStart + testimonialEntranceDuration; // 8050
  static const double testimonialInteractionStart =
      8050.0; // Start interaction after entrance
  static const double testimonialVisibleDuration =
      3200.0; // Compressed slightly
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 11250
  static double get testimonialExitStart => testimonialInteractionEnd; // 11250
  static const double testimonialExitDuration = 400.0;

  static double get testimonialExitEnd =>
      testimonialExitStart + testimonialExitDuration; // 11650

  // --- Transition Gap: Testimonials -> Contact (11650 - 11750) ---
  static const double testimonialToContactGap = 100.0;

  // --- 5. Contact (11750+) - FINAL SECTION ---
  // Clean entrance after testimonials fully exit, stays visible (no exit)
  static const double contactEntranceStart = 11750.0;
  static const double contactEntranceDuration = 600.0;
  static const double contactHoldDuration = 2000.0; // Extended hold

  static const double contactVisibleStart =
      contactEntranceStart + contactEntranceDuration;
  // No exit - contact stays visible as final section
  static const double maxScrollOffset = contactVisibleStart + contactHoldDuration; // ~14350

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

  static const double boldTextDriftOffset = 50.0;
}
