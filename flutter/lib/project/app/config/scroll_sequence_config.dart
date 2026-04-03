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
  static const double boldTextStart = 0.0; // Extended from 1700

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

  // --- 2. Contact Section (3200 - 4800) ---
  // Shifted by +1300 (3000 - 1700)
  static const double contactStart = 3200.0;
  static const double contactEnd = 4800.0;

  // Internal Contact Stages
  static const double contactFadeInEnd = 3600.0;
  static const double contactPeelStart = 3650.0;
  static const double contactPeelDuration = 250.0;
  static const double contactPeelDelay = 150.0;
  static const double contactExitStart = 4500.0;

  // --- Transition Gap: contact -> Work Experience (Closed) ---
  static const double contactToWorkExpGap = 0.0;

  // --- 2.5. Work Experience Title Section (4800 - 6400) ---
  static const double workExpTitleEntranceStart = contactEnd; // 4800.0
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

  // --- 3. Contact / contact (follows Work Experience) ---
  static const double contactEntranceStart =
      6400.0; // Matches workExpTitleExitEnd
  static const double contactEntranceDuration = 600.0;
  static const double contactHoldDuration = 2000.0;

  static const double contactVisibleStart =
      contactEntranceStart + contactEntranceDuration;
  static const double maxScrollOffset =
      contactVisibleStart + contactHoldDuration;

  // --- Scroll Transition offsets ---
  static const double contactTransitionOffset = 400.0;

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
    contactStart, // Section 2: Contact
  ];

  // --- Transition Configurations ---
  static const ContactTransitionConfig contactTransition =
  ContactTransitionConfig();
}

/// Layout and animation constants for [ContactSection].
///
/// Extracted from inline magic numbers to improve readability and allow
/// centralized tuning of the contact scroll experience.
class ContactSectionLayout {
  // ── Scroll thresholds ──────────────────────────────────────────────
  static const double entryScrollThreshold = 200.0;
  static const double whiteOverlayFadeDistance = 150.0;
  static const double backgroundFadeDistance = 500.0;
  static const double trailAppearOffset = 1000.0;
  static const double trailFadeDistance = 200.0;
  static const double titleStartOffset = 500.0;
  static const double titleEndOffset = 1000.0;
  static const double buttonShowThreshold = 2700.0;
  static const double audioPhaseWidth = 500.0;
  static const double warmUpLookahead = 500.0;

  // ── Background ─────────────────────────────────────────────────────
  static const double backgroundOverscan = 1.2;
  static const double backgroundOverscanMargin = 0.1;
  static const double backgroundYShift = 100.0;

  // ── Trail ──────────────────────────────────────────────────────────
  static const double trailInitialScale = 0.95;
  static const double trailScaleRange = 0.05;
  static const double trailInitialY = 200.0;

  // ── Title floating animation ───────────────────────────────────────
  static const double titleInitialScale = 0.1;
  static const double titleOvershootScale = 0.8;
  static const double titleSettleScale = 0.6;
  static const double titleOvershootThreshold = 0.7;
  static const double breatheAmplitude = 0.02;
  static const double breatheFrequency = 0.5;
  static const double swayAmount = 20.0;
  static const double titleStartYRatio = 0.7;
  static const double titleEndYRatio = 0.15;
  static const double waterLineYRatio = 0.55;
  static const double waterLevelRatio = 0.6;

  // ── Button fade ────────────────────────────────────────────────────
  static const double buttonFadeInSpeed = 3.0;
  static const double buttonFadeOutSpeed = 8.0;
  static const double buttonMinScale = 0.5;
  static const double buttonYRatio = 0.8;

  // ── Refraction capture ─────────────────────────────────────────────
  static const double refractionScale = 0.3;
  static const int highFpsThrottle = 2;
  static const int lowFpsThrottle = 3;
}

class ContactTransitionConfig {
  const ContactTransitionConfig();

  /// Duration to hold the button to fill the screen with rain (1.0 -> 2.5s)
  final double buttonHoldDuration = 2.5;

  /// Time to wait at max intensity before shattering (The "Tensor" moment)
  final int sustainDurationMs = 500;

  /// Delay from Shatter Trigger to Flash Trigger
  /// Allows the crack to be visible before the whiteout
  final int shatterToFlashDelayMs = 400;

  /// Duration of the Flash Attack phase (White out)
  /// Should match FlashTransitionComponent's internal logic roughly
  final int flashAttackDurationMs = 400;

  /// Total duration of the flash effect
  final double flashTotalDuration = 1.5;
}
