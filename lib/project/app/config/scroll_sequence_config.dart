class ScrollSequenceConfig {
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
  static const double titleAnimDuration = 3.0;
  static const double titleAnimLiftDuration = 2.0;
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
  static const double boldTextStart = 0.0;// Extended from 1700

  // Relative Progress Ranges (0.0 - 1.0)
  // Entrance (0.0 - 0.4): 0 - 1200
  static const double boldTextPass1End = 1200.0;
  // Shine (0.4 - 0.6): 1200 - 1800
  static const double boldTextPass2End = 1800.0;
  // Exit (0.6 - 1.0): 1800 - 3000

  /// Snap point: Bold Text Focus (Clarity Phase Center)
  static const double boldTextFocus = 1500.0;

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

  // --- Transition Gap: Philosophy -> Work Experience (Closed) ---
  static const double philosophyToWorkExpGap = 0.0;

  // --- 2.5. Work Experience Title Section (4800 - 6400) ---
  static const double workExpTitleEntranceStart = philosophyEnd; // 4800.0
  static const double workExpTitleEntranceDuration = 600.0;
  static double get workExpTitleEntranceEnd =>
      workExpTitleEntranceStart + workExpTitleEntranceDuration; // 5400

  static const double workExpTitleHoldStart =
      5400.0; // Adjusted to match new End
  static const double workExpTitleHoldDuration = 500.0;
  static double get workExpTitleHoldEnd =>
      workExpTitleHoldStart + workExpTitleHoldDuration; // 5900

  static const double workExpTitleExitStart = 5900.0; // Adjusted
  static const double workExpTitleExitDuration = 500.0;
  static double get workExpTitleExitEnd =>
      workExpTitleExitStart + workExpTitleExitDuration; // 6400

  // --- Transition Gap: Work Experience -> Experience Section (Closed) ---
  static const double workExpToExperienceGap = 0.0;

  // --- 3. Experience Section (6400 - 8750) ---
  static const double experienceEntranceStart =
      6400.0; // Matches workExpTitleExitEnd
  static const double experienceEntranceDuration = 300.0;

  static double get experienceEntranceEnd =>
      experienceEntranceStart + experienceEntranceDuration; // 6700
  static const double experienceInteractionStart = 6700.0;
  static const double experienceInteractionDuration = 1750.0;

  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 8450
  static double get experienceExitStart => experienceInteractionEnd; // 8450
  static const double experienceExitDuration = 300.0;

  static double get experienceExitEnd =>
      experienceExitStart + experienceExitDuration; // 8750

  static const double experienceScrollDivisor = 500.0;

  // --- Transition Gap: Experience -> Testimonials (Closed) ---
  static const double experienceToTestimonialGap = 0.0;

  // --- 4. Testimonials (8750 - 12650) ---
  static const double testimonialEntranceStart =
      8750.0; // Matches experienceExitEnd
  static const double testimonialEntranceDuration = 300.0;

  static double get testimonialEntranceEnd =>
      testimonialEntranceStart + testimonialEntranceDuration; // 9050
  static const double testimonialInteractionStart = 9050.0;
  static const double testimonialVisibleDuration = 3200.0;
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 12250
  static double get testimonialExitStart => testimonialInteractionEnd; // 12250
  static const double testimonialExitDuration = 400.0;

  static double get testimonialExitEnd =>
      testimonialExitStart + testimonialExitDuration; // 12650

  // --- Transition Gap: Testimonials -> Contact (Closed) ---
  static const double testimonialToContactGap = 0.0;

  // --- 5. Contact (12650+) - FINAL SECTION ---
  static const double contactEntranceStart =
      12650.0; // Matches testimonialExitEnd
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
