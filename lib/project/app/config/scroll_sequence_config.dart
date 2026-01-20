class ScrollSequenceConfig {
  // --- Intro / Title Section ---
  static const double titleParallaxEnd = 800.0;
  static const double secondaryTitleParallaxEnd = 1000.0;
  static const double titleFadeEnd = 500.0;
  static const double secondaryTitleFadeEnd = 100.0;
  static const double uiFadeEnd = 100.0;

  // --- Intro Animation Durations (ms) ---
  static const int sceneRevealDuration = 2000;
  static const int loadingBlinkDuration = 600;
  static const int arrowBounceDuration = 1500;
  static const int enterTitleDelay = 1000;

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

  // --- 1. Bold Text Section (0 - 3000) ---
  // The bold text sequence covers a large area for the 3-pass animation
  static const double boldTextStart = 0.0;
  static const double boldTextEnd = 3000.0; // Extended from 1700

  // Relative Progress Ranges (0.0 - 1.0)
  // Entrance (0.0 - 0.4): 0 - 1200
  static const double boldTextPass1End = 1200.0;
  // Shine (0.4 - 0.6): 1200 - 1800
  static const double boldTextPass2End = 1800.0;
  // Exit (0.6 - 1.0): 1800 - 3000

  // --- Dim Layer (Matches Shine Phase roughly) ---
  static const double dimLayerStart = 1200.0;
  static const double dimLayerEnd = 2500.0;

  // --- 2. Philosophy Section (3200 - 4800) ---
  // Shifted by +1300 (3000 - 1700)
  static const double philosophyStart = 3200.0;
  static const double philosophyEnd = 4800.0;

  // Internal Philosophy Stages
  static const double philosophyFadeInEnd = 3600.0;
  static const double philosophyPeelStart = 3650.0;
  static const double philosophyPeelDuration = 250.0;
  static const double philosophyPeelDelay = 150.0;
  static const double philosophyExitStart = 4500.0;

  // --- Transition Gap: Philosophy -> Work Experience (4800 - 4900) ---
  static const double philosophyToWorkExpGap = 100.0;

  // --- 2.5. Work Experience Title Section (4900 - 6500) ---
  static const double workExpTitleEntranceStart = 4900.0;
  static const double workExpTitleEntranceDuration = 600.0;
  static double get workExpTitleEntranceEnd =>
      workExpTitleEntranceStart + workExpTitleEntranceDuration; // 5500

  static const double workExpTitleHoldStart = 5500.0;
  static const double workExpTitleHoldDuration = 500.0;
  static double get workExpTitleHoldEnd =>
      workExpTitleHoldStart + workExpTitleHoldDuration; // 6000

  static const double workExpTitleExitStart = 6000.0;
  static const double workExpTitleExitDuration = 500.0;
  static double get workExpTitleExitEnd =>
      workExpTitleExitStart + workExpTitleExitDuration; // 6500

  // --- Transition Gap: Work Experience -> Experience Section (6500 - 6600) ---
  static const double workExpToExperienceGap = 100.0;

  // --- 3. Experience Section (6600 - 8950) ---
  static const double experienceEntranceStart = 6600.0;
  static const double experienceEntranceDuration = 300.0;

  static double get experienceEntranceEnd =>
      experienceEntranceStart + experienceEntranceDuration; // 6900
  static const double experienceInteractionStart = 6900.0;
  static const double experienceInteractionDuration = 1750.0;

  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 8650
  static double get experienceExitStart => experienceInteractionEnd; // 8650
  static const double experienceExitDuration = 300.0;

  static double get experienceExitEnd =>
      experienceExitStart + experienceExitDuration; // 8950

  static const double experienceScrollDivisor = 500.0;

  // --- Transition Gap: Experience -> Testimonials (8950 - 9050) ---
  static const double experienceToTestimonialGap = 100.0;

  // --- 4. Testimonials (9050 - 12950) ---
  static const double testimonialEntranceStart = 9050.0;
  static const double testimonialEntranceDuration = 300.0;

  static double get testimonialEntranceEnd =>
      testimonialEntranceStart + testimonialEntranceDuration; // 9350
  static const double testimonialInteractionStart = 9350.0;
  static const double testimonialVisibleDuration = 3200.0;
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 12550
  static double get testimonialExitStart => testimonialInteractionEnd; // 12550
  static const double testimonialExitDuration = 400.0;

  static double get testimonialExitEnd =>
      testimonialExitStart + testimonialExitDuration; // 12950

  // --- Transition Gap: Testimonials -> Contact (12950 - 13050) ---
  static const double testimonialToContactGap = 100.0;

  // --- 5. Contact (13050+) - FINAL SECTION ---
  static const double contactEntranceStart = 13050.0;
  static const double contactEntranceDuration = 600.0;
  static const double contactHoldDuration = 2000.0;

  static const double contactVisibleStart =
      contactEntranceStart + contactEntranceDuration;
  static const double maxScrollOffset =
      contactVisibleStart + contactHoldDuration; // ~15650

  // --- Scroll Transition offsets ---
  static const double experienceFadeOffset = 300.0;
  static const double experienceExitFadeOffset = 350.0;

  static const double philosophyTransitionOffset = 400.0;

  static const double testimonialFadeOffset = 300.0;

  // --- UI Config ---
  static const double uiFadeDistance = 100.0;
  static const double dimLayerFinalAlpha = 0.6;

  // --- Logo Overlay Scene Progress Thresholds ---
  static const double logoOverlayRevealStart = 0.2;
  static const double logoOverlayLinesStart = 0.4;
  static const double logoOverlayTextStart = 0.5;

  // --- Carousel Timing ---
  static const double carouselEnterDuration = 0.8;
  static const double carouselExitDuration = 0.6;
  static const double carouselScrollDuration = 0.7;

  // --- Section Jump Targets (for progress indicator clicks) ---
  static const List<double> sectionJumpTargets = [
    0.0, // Section 0: Hero
    boldTextStart, // Section 1: Bold Text
    philosophyStart, // Section 2: Philosophy
    workExpTitleEntranceStart, // Section 3: Work Experience
    testimonialInteractionStart, // Section 4: Testimonials
    contactEntranceStart, // Section 5: Contact
  ];
}
