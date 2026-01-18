import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

/// Configuration for the Orbital Anchor Ring - a continuous attention-guiding element
/// that animates throughout the scroll sequence with section-specific behaviors.
class AnchorConfig {
  // --- State Timing ---

  /// Dormant: Hidden before scroll starts
  static const double dormantEnd = 500.0;

  /// Awakening: During Bold Text section (500-1700)
  static const double awakeningStart = 500.0;
  static const double awakeningEnd = 1700.0;

  /// Following Text: Tracks bold text movement (500-1700)
  static const double followingTextStart = 500.0;
  static const double followingTextEnd = 1700.0;

  /// Orbiting Philosophy: Circular orbit during philosophy (1900-3500)
  static const double orbitingPhilosophyStart = 1900.0;
  static const double orbitingPhilosophyEnd = 3500.0;

  /// Dramatic Orbit: Hero moment during Work Experience title (3600-4650)
  static const double dramaticOrbitStart =
      ScrollSequenceConfig.workExpTitleEntranceStart;
  static const double dramaticOrbitEnd =
      ScrollSequenceConfig.workExpTitleExitEnd;

  /// Multi-Orbit: 3-5 rings during Experience (4750-6800)
  static const double multiOrbitStart =
      ScrollSequenceConfig.experienceInteractionStart;
  static const double multiOrbitEnd =
      ScrollSequenceConfig.experienceInteractionEnd;

  /// Carousel Orbit: Follows testimonial carousel (7200-10700)
  static const double carouselOrbitStart =
      ScrollSequenceConfig.testimonialInteractionStart;
  static const double carouselOrbitEnd =
      ScrollSequenceConfig.testimonialInteractionEnd;

  /// Pulse Grid: Matrix-style pulse during Skills (11200-12800)
  static const double pulseGridStart =
      ScrollSequenceConfig.skillsEntranceStart;
  static const double pulseGridEnd =
      ScrollSequenceConfig.skillsInteractEnd;

  /// The Reveal: Massive zoom-out at Contact (13300+)
  static const double zoomOutStart =
      ScrollSequenceConfig.contactEntranceStart;
  static const double zoomOutEnd =
      ScrollSequenceConfig.contactExitEnd;

  // --- Visual Properties ---

  /// Ring dimensions
  static const double ringRadiusBase = 60.0;
  static const double ringThickness = 3.0;
  static const double ringGlowRadius = 15.0;

  /// Scale ranges per state
  static const double scaleAwakening = 0.5;
  static const double scaleFollowing = 0.8;
  static const double scaleOrbiting = 1.0;
  static const double scaleDramatic = 1.5;
  static const double scaleMulti = 0.7;
  static const double scaleCarousel = 0.9;
  static const double scalePulse = 1.2;
  static const double scaleZoomOutMax = 30.0;

  /// Opacity ranges
  static const double opacityHidden = 0.0;
  static const double opacityAwakening = 0.3;
  static const double opacityVisible = 1.0;
  static const double opacityDramatic = 1.0;
  static const double opacityFadeOut = 0.0;

  // --- Animation Properties ---

  /// Rotation speeds (radians per second)
  static const double rotationSpeedSlow = 1.0;
  static const double rotationSpeedMedium = 2.0;
  static const double rotationSpeedFast = 5.0;
  static const double rotationSpeedDramatic = 8.0;

  /// Orbit radii for circular movement
  static const double orbitRadiusPhilosophy = 150.0;
  static const double orbitRadiusDramatic = 250.0;
  static const double orbitRadiusCarousel = 180.0;

  /// Multi-orbit configuration
  static const int multiOrbitCount = 5;
  static const double multiOrbitRadiusMin = 100.0;
  static const double multiOrbitRadiusMax = 300.0;

  // --- Color Palette ---

  /// Soft white for awakening
  static const Color colorSoftWhite = Color(0xFFEEEEEE);

  /// Golden for philosophy
  static const Color colorGolden = Color(0xFFC78E53);

  /// Cyan for dramatic orbit
  static const Color colorCyan = Color(0xFF00E5FF);

  /// Purple for experience
  static const Color colorPurple = Color(0xFFAA00FF);

  /// Warm gold for testimonials
  static const Color colorWarmGold = Color(0xFFFFB74D);

  /// Matrix green for skills
  static const Color colorMatrixGreen = Color(0xFF00FF41);

  /// Rainbow shimmer for zoom-out
  static const List<Color> colorsRainbow = [
    Color(0xFFFF0080), // Pink
    Color(0xFFFF8C00), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF80), // Green
    Color(0xFF00FFFF), // Cyan
    Color(0xFF0080FF), // Blue
    Color(0xFF8000FF), // Purple
  ];

  // --- Particle Trail Properties ---

  /// Particle trail enabled for dramatic state
  static const bool particlesEnabledDramatic = true;
  static const int particleCountDramatic = 20;
  static const double particleLifetime = 0.8; // seconds
  static const double particleSpawnRate = 0.02; // seconds between spawns
  static const double particleFadeSpeed = 1.5;

  /// Particle visual properties
  static const double particleSizeMin = 2.0;
  static const double particleSizeMax = 6.0;
  static const double particleOpacityStart = 0.8;
  static const double particleOpacityEnd = 0.0;

  // --- Physics and Easing ---

  /// Spring parameters for smooth movement
  static const double springMass = 1.0;
  static const double springStiffness = 160.0;
  static const double springDamping = 14.0;

  /// Position interpolation speed
  static const double positionLerpSpeed = 8.0;

  /// Scale transition speed
  static const double scaleTransitionSpeed = 5.0;

  // --- Zoom-Out Finale Properties ---

  /// Portal effect parameters
  static const double portalPulseFrequency = 3.0; // Hz
  static const double portalPulseAmplitude = 0.1;
  static const double portalRotationSpeed = 4.0;

  /// Rainbow shimmer parameters
  static const double rainbowCycleSpeed = 2.0; // full cycle per 2 seconds
  static const int rainbowSegmentCount = 7;

  // --- Z-Index ---

  /// High priority to appear above most content but below UI overlays
  static const int zIndex = 100;
}
