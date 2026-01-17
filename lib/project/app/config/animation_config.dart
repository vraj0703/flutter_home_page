import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';

/// Centralized animation timing and curve configurations
/// Single source of truth for all animation parameters in the portfolio
class AnimationConfig {
  // ========== TIMING CONSTANTS ==========

  // Snap System Configuration
  static const double snapZoneRadius = 50.0;
  static const double snapVelocityThreshold = 50.0;
  static const double snapSpeed = 8.0;

  // Speed Constants
  static const double cursorTrackingFast = 22.0;
  static const double cursorTrackingMedium = 18.0;
  static const double logoAnimationSpeed = 6.0;

  // Snap Points (key scroll positions where magnetic snap occurs)
  static const List<double> snapPoints = [500, 1500, 4200, 14800];
  static const double snapZoneSize = 50.0; // +/- from snap point

  // ========== CURVE PRESETS ==========

  // Hero/Title Section Curves
  static const Curve heroParallax = SpringCurve(
    mass: 1.0,
    stiffness: 180.0,
    damping: 12.0,
  );

  static const Curve heroParallaxLight = SpringCurve(
    mass: 0.8,
    stiffness: 200.0,
    damping: 10.0,
  );

  // General Purpose Curves
  static const Curve elegantFade = ExponentialEaseOut();

  static const Curve playfulBounce = ElasticEaseOut(
    amplitude: 0.4,
    period: 0.3,
  );

  static const Curve dramaticEntry = AnticipationCurve(
    anticipationStrength: 0.12,
  );

  // Logo Animation Curve
  static const Curve logoSpring = SpringCurve(
    mass: 0.8,
    stiffness: 200.0,
    damping: 15.0,
  );

  // Contact Section Curves
  static const Curve contactEntrance = SpringCurve(
    mass: 1.2,
    stiffness: 150.0,
    damping: 14.0,
  );

  static const Curve contactExit = SpringCurve(
    mass: 1.0,
    stiffness: 160.0,
    damping: 12.0,
  );

  // Experience Timeline Curves
  static const Curve experienceWarp = SpringCurve(
    mass: 1.0,
    stiffness: 170.0,
    damping: 12.0,
  );

  // Testimonials Curves
  static const Curve testimonialsExit = SpringCurve(
    mass: 1.0,
    stiffness: 160.0,
    damping: 13.0,
  );

  // Skills Keyboard Curves
  static const Curve skillsEntrance = ElasticEaseOut(
    amplitude: 0.4,
    period: 0.3,
  );

  static const Curve skillsExit = SpringCurve(
    mass: 0.9,
    stiffness: 170.0,
    damping: 12.0,
  );

  // ========== ANIMATION DESCRIPTIONS ==========
  // For documentation and future reference

  /// Gets a human-readable description of the curve preset
  static String getCurveDescription(Curve curve) {
    if (curve is SpringCurve) {
      return 'Spring Physics (natural bounce and settle)';
    } else if (curve is ElasticEaseOut) {
      return 'Elastic Bounce (playful, attention-grabbing)';
    } else if (curve is AnticipationCurve) {
      return 'Anticipation (dramatic pull-back before action)';
    } else if (curve is ExponentialEaseOut) {
      return 'Exponential Ease (smooth, elegant deceleration)';
    } else if (curve is BezierCurve) {
      return 'Custom Bezier (fine-tuned timing)';
    } else {
      return 'Standard Flutter Curve';
    }
  }

  /// Get recommended curve for a specific animation type
  static Curve getCurveForAnimationType(AnimationType type) {
    switch (type) {
      case AnimationType.heroSection:
        return heroParallax;
      case AnimationType.textReveal:
        return elegantFade;
      case AnimationType.cardPeel:
        return dramaticEntry;
      case AnimationType.contactSlide:
        return contactEntrance;
      case AnimationType.skillsEntrance:
        return skillsEntrance;
      case AnimationType.fadeOut:
        return elegantFade;
      default:
        return elegantFade;
    }
  }
}

/// Animation type enumeration for easy curve selection
enum AnimationType {
  heroSection,
  textReveal,
  cardPeel,
  contactSlide,
  skillsEntrance,
  fadeOut,
}
