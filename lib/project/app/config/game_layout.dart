import 'package:flame/components.dart';

class GameLayout {
  // --- Global ---
  static const double iconSize = 45.0;

  // --- Contact Page ---
  static const double contactLeftColRelX = 0.12; // 12%
  static const double contactRightColRelX = 0.58; // 58%
  static const double contactContentRelW = 0.32; // 32%

  static const double contactTitleRelY = 0.22;
  static const double contactDescRelY = 0.48;
  static const double contactIconRelY = 0.72;
  static const double contactFormRelY = 0.30;

  static const double contactFormSpacing = 120.0;
  static const double contactButtonW = 180.0;
  static const double contactButtonH = 55.0;

  // --- Testimonials Page ---
  static const double testimonialTitleRelY = 0.15;
  static const double testimonialCarouselRelY = 0.5;
  static const double testimonialButtonRelY = 0.85;
  static const double testimonialButtonW = 200.0;
  static const double testimonialButtonH = 50.0;

  // --- Experience Page ---
  static const double experienceOrbitRelW = 0.4;
  static const double experienceTextRelX = 0.05;

  // --- God Ray ---
  static const double godRayCoreSize = 0.0;
  static const double godRayCoreBlur = 2.0;
  static const double godRayInnerSize = 24.0;
  static const double godRayInnerBlur = 15.0;
  static const double godRayOuterSize = 64.0;
  static const double godRayOuterBlur = 35.0;

  // --- Logo Overlay ---
  static const double logoOverlayOuterRadius = 135.0;
  static const double logoOverlayInnerRadius = 95.0;

  static const double logoOverlayHLineLength = 80.0;
  static const double logoOverlayHLineGap = 120.0;
  static const double logoOverlayHThreshold = 300.0;

  static const double logoOverlayVLineLength = 70.0;
  static const double logoOverlayVLineGap = 120.0;
  static const double logoOverlayVThreshold = 150.0;

  static const double logoOverlayStartThickness = 3.0;
  static const double logoOverlayEndThickness = 0.5;

  static const double titleHeatDriftY = -20.0;

  // --- Philosophy Card ---
  static const double cardPadding = 32.0;
  static const double cardTitleOffset = 60.0;
  static const double cardDividerOffset = 92.0; // 60 + 32
  static const double cardDescOffset = 112.0; // 60 + 32 + 20
  static const double cardWidth = 550.0;
  static const double cardHeight = 250.0;
  static const double cardCornerRadius = 20.0;
  static const int cardDescWrapLimit = 80;

  // --- Skills Keyboard ---
  static const double keyboardChassisWidthRatio = 0.8;
  static const double keyboardChassisHeightRatio = 0.5;
  static const double keyboardKeySize = 60.0;
  static const double keyboardKeySpacing = 15.0;
  static const double keyboardRowSpacing = 70.0;
  static const double keyboardKeyDepth = 10.0;
  static const double keyboardKeyRadius = 8.0;

  // --- Experience Details ---
  static const double expDescMaxWidth = 450.0;
  static const double expOrbitRadiusMultiplier = 1.0;
  static const double expSatelliteLabelDist = 40.0;
  static const double expSatelliteDotSize = 6.0;

  // --- Testimonial Carousel ---
  static const double testiCardWidth = 400.0;
  static const double testiCardHeight = 250.0;
  static const double testiCardSpacing = 40.0;
  static const double testiCarouselThreshold = 300.0;

  static const double testiCardPadding = 24.0;
  static const double testiAuthorBtmMargin = 60.0;
  static const double testiRoleBtmMargin = 36.0;
  static const double testiCardRadius = 16.0;

  // --- Scroll Driven Layouts ---

  // Experience
  static const double expExitY = -1000.0;
  static const double expInitialScale = 0.95;
  static const double expExitScale = 0.98;

  static const double expOrbitRadiusRatio = 0.65;
  static const double expActiveThreshold = 0.35;
  static const double expActiveScale = 1.2;
  static const double expInactiveScale = 0.8;
  static const double expWarpMaxScale = 8.0;
  static const double expSatelliteSpacing = 0.7854; // pi/4
  static const double expTextAnimOffset = 30.0;

  // --- Bouncing Arrow & Menu ---
  static const double arrowShadowOffsetX = 0.0;
  static const double arrowShadowOffsetY = 4.0;
  static const double arrowSize = 30.0;
  static const double arrowSpacing = 10.0;
  static const double arrowBottomMargin = 60.0;

  static const double menuMargin = 40.0;
  static const double menuSize = 50.0;

  // --- Orbital Arcs ---
  static const double orbitalArcWidthOuter = 100.0;

  // --- Z-Index (Priorities) ---
  static const int zBackground = 1;
  static const int zDimLayer = 2;
  static const int zLogo = 10;
  static const int zGodRay = 20;
  static const int zSecondaryTitle = 24;
  static const int zTitle = 25;
  static const int zContent = 25; // Philosophy, Experience, Testimonials
  static const int zBoldText = 26;
  static const int zSkills = 28;
  static const int zLogoOverlay = 30;
  static const int zContact = 30;

  // --- Logo Animator Layout ---
  static const double logoHeaderY = 60.0;
  static const double logoMinScale = 0.25;
  static const double logoStartX = 60.0;
  static const double logoInitialScale = 3.0;
  static const double logoRemovingScale = 0.3;
  static const double logoRemovingTargetX = 36.0;
  static const double logoRemovingTargetY = 36.0;

  // --- Cursor System Layout ---
  static const double cursorGlowOffset = 10.0;

  // --- Factory / Composition Layout ---
  static const double secTitleYOffset = 48.0;
  static const double philosophyTextXRatio = 0.15;
  static const double cardStackWidthRatio = 0.4;
  static const double cardStackHeightRatio = 0.6;
  static const double cardStackXRatio = 0.75;

  // --- Parallax ---
  static const double standardParallaxY = -1000.0;
  static const double orbitalRadiusOuter = 1.0;
  static const double orbitalRadiusMid = 0.8;
  static const double orbitalRadiusInner = 0.65;
  static const double orbitalArcWidthMid = 50.0; // Added default
  static const double orbitalArcWidthInner = 25.0; // Added default

  // --- Carousel Layout ---
  static const double carouselCardWidth = 550.0;
  static const double carouselSpacing = 50.0;
  static const double carouselCenterYOffset = 100.0; // The -100 from center
  static const double carouselOffscreenY = 400.0;

  // --- Overlay Layout ---
  static const double overlayTitleY = 0.15;
  static const double overlayContentY = 0.5;
  static const double overlayButtonY = 0.85;

  // Philosophy
  static const double philExitY = -40.0;
  static const double philStackLift = -350.0;
  static const double philStackRotation = 0.15;
  static const double philStackScaleMax = 1.05;
  static const double philStackScaleMin = 0.98;

  // Skills
  static const double skillsExitY = -120.0;
  static const double skillsInitialScale = 0.9;

  // Testimonials
  static const double testiExitY = -1000.0;

  // Sequence offsets
  static const double keyboardChassisShadowOffset = 10.0;
  static const double keyboardStartYOffset = 60.0;
  static const List<double> keyboardRowOffsets = [0.0, 30.0, 45.0, 0.0];

  // --- Vector Definitions ---
  static final Vector2 scaleOne = Vector2.all(1.0);
  static final Vector2 scaleZero = Vector2.zero();

  // Sizes
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);
  static final Vector2 contactButtonSize = Vector2(
    contactButtonW,
    contactButtonH,
  );
  static final Vector2 testimonialButtonSize = Vector2(
    testimonialButtonW,
    testimonialButtonH,
  );
  static final Vector2 testiCardSize = Vector2(testiCardWidth, testiCardHeight);
  static final Vector2 menuSizeVector = Vector2.all(menuSize);
  static final Vector2 arrowSizeVector = Vector2.all(arrowSize);

  // Offsets
  static final Vector2 titleHeatDriftVector = Vector2(0, titleHeatDriftY);
  static final Vector2 philosophyStackLiftVector = Vector2(0, philStackLift);
  static final Vector2 secTitleOffsetVector = Vector2(0, secTitleYOffset);
  static final Vector2 logoRemovingTargetVector = Vector2(
    logoRemovingTargetX,
    logoRemovingTargetY,
  );

  // Philosophy Card Vectors
  static final Vector2 cardPaddingVector = Vector2.all(cardPadding);
  static final Vector2 cardTitlePosVector = Vector2(
    cardPadding,
    cardPadding + cardTitleOffset,
  );
  static final Vector2 cardDividerPosVector = Vector2(
    cardPadding,
    cardPadding + cardDividerOffset,
  );
  static final Vector2 cardDescPosVector = Vector2(
    cardPadding,
    cardPadding + cardDescOffset,
  );
}
