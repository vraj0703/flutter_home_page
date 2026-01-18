import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/curves/anticipation.dart';

import 'package:flutter_home_page/project/app/curves/elastic_ease_out.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';

class GameCurves {
  // Bouncy Lines
  static const double _bouncyLineStiffness = 500.0;
  static const double _bouncyLineDamping = 70.0;
  static const double bouncyLineMass = 20.0;

  // Contact Page
  static const double _contactEntranceMass = 1.2;
  static const double _contactEntranceStiffness = 150.0;
  static const double _contactEntranceDamping = 14.0;

  static const double _contactExitMass = 1.0;
  static const double _contactExitStiffness = 160.0;
  static const double _contactExitDamping = 12.0;

  // Experience Page
  static const double _expExitMass = 1.0;
  static const double _expExitStiffness = 170.0;
  static const double _expExitDamping = 12.0;

  // Philosophy Page
  static const double _philSpringMass = 0.8;
  static const double _philSpringStiffness = 140.0;
  static const double _philSpringDamping = 16.0;

  // Skills Page
  static const double _skillsSpringMass = 1.0;
  static const double _skillsSpringStiffness = 140.0;
  static const double _skillsSpringDamping = 18.0;

  // Testimonial Page
  static const double _testiExitMass = 1.0;
  static const double _testiExitStiffness = 160.0;
  static const double _testiExitDamping = 13.0;

  // Default Curves
  static const double _defaultSpringMass = 1.0;
  static const double _defaultSpringStiffness = 180.0;
  static const double _defaultSpringDamping = 12.0;

  static const double _defaultAnticipationStrength = 0.12;
  static const double _defaultElasticPeriod = 0.3;
  static const double _defaultElasticAmplitude = 0.4;

  // Bezier Control Points
  static const double _bezierSmoothP1X = 0.4;
  static const double _bezierSmoothP1Y = 0.0;
  static const double _bezierSmoothP2X = 0.2;
  static const double _bezierSmoothP2Y = 1.0;

  static const double _bezierSnappyP1X = 0.2;
  static const double _bezierSnappyP1Y = 0.9;
  static const double _bezierSnappyP2X = 0.3;
  static const double _bezierSnappyP2Y = 1.0;

  static const double _bezierElegantP1X = 0.25;
  static const double _bezierElegantP1Y = 0.1;
  static const double _bezierElegantP2X = 0.25;
  static const double _bezierElegantP2Y = 1.0;

  // Logo Physics
  static const double _logoSpringMass = 0.8;
  static const double _logoSpringStiffness = 200.0;
  static const double _logoSpringDamping = 15.0;

  // --- Initialized Curves ---

  // Springs
  static const SpringCurve defaultSpring = SpringCurve(
    mass: _defaultSpringMass,
    stiffness: _defaultSpringStiffness,
    damping: _defaultSpringDamping,
  );

  static const SpringCurve bouncyLineSpring = SpringCurve(
    mass: bouncyLineMass,
    stiffness: _bouncyLineStiffness,
    damping: _bouncyLineDamping,
  );

  static const SpringCurve contactEntranceSpring = SpringCurve(
    mass: _contactEntranceMass,
    stiffness: _contactEntranceStiffness,
    damping: _contactEntranceDamping,
  );

  static const SpringCurve contactExitSpring = SpringCurve(
    mass: _contactExitMass,
    stiffness: _contactExitStiffness,
    damping: _contactExitDamping,
  );

  static const SpringCurve expExitSpring = SpringCurve(
    mass: _expExitMass,
    stiffness: _expExitStiffness,
    damping: _expExitDamping,
  );

  static const SpringCurve philosophySpring = SpringCurve(
    mass: _philSpringMass,
    stiffness: _philSpringStiffness,
    damping: _philSpringDamping,
  );

  static const SpringCurve skillsSpring = SpringCurve(
    mass: _skillsSpringMass,
    stiffness: _skillsSpringStiffness,
    damping: _skillsSpringDamping,
  );

  static const SpringCurve testimonialExitSpring = SpringCurve(
    mass: _testiExitMass,
    stiffness: _testiExitStiffness,
    damping: _testiExitDamping,
  );

  static const SpringCurve logoSpring = SpringCurve(
    mass: _logoSpringMass,
    stiffness: _logoSpringStiffness,
    damping: _logoSpringDamping,
  );

  // Eases & Others
  static const AnticipationCurve defaultAnticipation = AnticipationCurve(
    anticipationStrength: _defaultAnticipationStrength,
  );

  static const ElasticEaseOut defaultElastic = ElasticEaseOut(
    period: _defaultElasticPeriod,
    amplitude: _defaultElasticAmplitude,
  );

  static const Cubic bezierSmooth = Cubic(
    _bezierSmoothP1X,
    _bezierSmoothP1Y,
    _bezierSmoothP2X,
    _bezierSmoothP2Y,
  );

  static const Cubic bezierSnappy = Cubic(
    _bezierSnappyP1X,
    _bezierSnappyP1Y,
    _bezierSnappyP2X,
    _bezierSnappyP2Y,
  );

  static const Cubic bezierElegant = Cubic(
    _bezierElegantP1X,
    _bezierElegantP1Y,
    _bezierElegantP2X,
    _bezierElegantP2Y,
  );

  // Standard Flutter Curves alias
  static const Curve standardEase = Curves.easeOutQuad;
  static const Curve standardLinear = Curves.linear;

  // Semantic Curves
  static const Curve arrowBounce = Curves.easeInOutQuad;
  static const Curve loadingBlink = Curves.linearToEaseOut;

  static const Curve titleEntry = Curves.easeOut;
  static const Curve titleScale = Curves.fastLinearToSlowEaseIn;
  static const Curve titleDrift = Curves.easeInCubic;
  static const Curve tabTransition = Curves.easeInOutCubic;

  static const Curve backgroundFade = Curves.easeInOut;
  static const Curve smoothDecel = Curves.easeOutQuart;
  static const Curve carouselIn = Curves.easeIn;
  static const Curve standardReveal = Curves.easeOut;
}
