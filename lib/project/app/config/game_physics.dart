class GamePhysics {
  // --- Bouncy Lines ---
  static const double bouncyLineMaxScale = 2.0;
  static const double bouncyLineScaleSpeed = 15.0;
  static const double bouncyLineVelocityScaleFactor = 70.0;

  // --- Experience Page ---
  static const double expSmoothing = 5.0;

  // --- Logo Physics ---
  static const double logoLerpSpeed = 10.0;
  static const double logoProgressSpeed = 6.0;
  static const double logoOverlayTextAnimSpeed = 2.0;

  // --- Cursor Physics ---
  static const double cursorSmoothSpeedFar = 30.0;
  static const double cursorSmoothSpeedNear = 24.0;

  // Parallax
  static const double titleParallaxFactor = 0.02;
  static const double secondaryTitleParallaxFactor =
      0.015; // Slightly different for depth

  // --- Scroll Snap Physics ---
  static const double snapZoneRadius = 60.0;
  static const double snapVelocityThreshold = 40.0;
  static const double snapSpeed = 6.0;
  static const double snapDistanceThreshold = 5.0;
}
