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

  // --- 2.5. Work Experience Title Section (3600 - 4650) ---
  // Full page parallax entrance and exit, NO overlaps
  static const double workExpTitleEntranceStart = 3600.0;
  static const double workExpTitleEntranceDuration = 400.0; // Longer for smooth parallax
  static double get workExpTitleEntranceEnd =>
      workExpTitleEntranceStart + workExpTitleEntranceDuration; // 4000

  static const double workExpTitleHoldStart = 4000.0;
  static const double workExpTitleHoldDuration = 300.0; // Extended for emphasis
  static double get workExpTitleHoldEnd =>
      workExpTitleHoldStart + workExpTitleHoldDuration; // 4300

  static const double workExpTitleExitStart = 4300.0;
  static const double workExpTitleExitDuration = 350.0; // Longer for smooth parallax
  static double get workExpTitleExitEnd =>
      workExpTitleExitStart + workExpTitleExitDuration; // 4650

  // --- Transition Gap: Work Experience -> Experience Section (4650 - 4750) ---
  static const double workExpToExperienceGap = 100.0;

  // --- 3. Experience Section (4750 - 7100) ---
  // Clean entrance AFTER work exp title fully exits
  static const double experienceEntranceStart = 4750.0;
  static const double experienceEntranceDuration = 300.0;
  static double get experienceEntranceEnd =>
      experienceEntranceStart + experienceEntranceDuration; // 5050
  static const double experienceInteractionStart =
      5050.0; // Starts after entrance completes
  // Length based on content (5 items * 350 = 1750)
  static const double experienceInteractionDuration = 1750.0;
  static double get experienceInteractionEnd =>
      experienceInteractionStart + experienceInteractionDuration; // 6800
  static double get experienceExitStart => experienceInteractionEnd; // 6800
  static const double experienceExitDuration = 300.0;
  static double get experienceExitEnd =>
      experienceExitStart + experienceExitDuration; // 7100

  static const double experienceScrollDivisor = 500.0;

  // --- Transition Gap: Experience -> Testimonials (7100 - 7200) ---
  static const double experienceToTestimonialGap = 100.0;

  // --- 4. Testimonials (7200 - 11100) ---
  // Clean entrance after experience fully exits
  static const double testimonialEntranceStart = 7200.0;
  static const double testimonialEntranceDuration = 300.0;
  static double get testimonialEntranceEnd =>
      testimonialEntranceStart + testimonialEntranceDuration; // 7500
  static const double testimonialInteractionStart =
      7500.0; // Start interaction after entrance
  static const double testimonialVisibleDuration = 3200.0; // Compressed slightly
  static double get testimonialInteractionEnd =>
      testimonialInteractionStart + testimonialVisibleDuration; // 10700
  static double get testimonialExitStart => testimonialInteractionEnd; // 10700
  static const double testimonialExitDuration = 400.0;
  static double get testimonialExitEnd =>
      testimonialExitStart + testimonialExitDuration; // 11100

  // --- Transition Gap: Testimonials -> Skills (11100 - 11200) ---
  static const double testimonialToSkillsGap = 100.0;

  // --- 5. Skills (11200 - 13200) ---
  // Clean entrance after testimonials fully exit
  static const double skillsEntranceStart = 11200.0;
  static const double skillsEntranceDuration = 400.0;
  static double get skillsEntranceEnd =>
      skillsEntranceStart + skillsEntranceDuration; // 11600
  static const double skillsInteractEnd =
      12800.0; // Hold -> 11600 + 1200 = 12800
  static const double skillsExitDuration = 400.0;
  static double get skillsExitEnd => skillsInteractEnd + skillsExitDuration; // 13200

  // --- Transition Gap: Skills -> Contact (13200 - 13300) ---
  static const double skillsToContactGap = 100.0;

  // --- 6. Contact (13300+) ---
  // Clean entrance after skills fully exit
  static const double contactEntranceStart = 13300.0;
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
