import 'package:flutter/material.dart';

class GameStyles {
  // Colors
  static const Color primaryBackground = Color(0xFFC78E53);
  static const Color accentGold = Color(0xFFC78E53);

  static const Color boldTextBase = Color(0xFFE3E4E5);
  static const Color philosophyText = Colors.white;
  static const Color dimLayer = Color(0xFF000000);
  static const Color silverText = Color(0xFFCCCCCC);
  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color black = Colors.black;
  static const Color fadeTextDefault = Color(0xFFF0F0F2);

  // God Ray Colors
  static const Color godRayCore = Color(0xFFFFFFFF);
  static const Color godRayInner = Color(0xAAFFE082);
  static const Color godRayOuter = Color(0xAAE68A4D);

  // Logo Overlay Colors
  static const Color logoOverlayUi = Color(0xFF9A482F);
  static const Color logoOverlayShadow = Color(0xFFD6A65F);

  // Philosophy Card Colors
  static const Color cardFill = Color(0x0DFFFFFF); // White 5%
  static const Color cardStroke = Color(0x33FFFFFF); // White 20%
  static const Color cardShadow = Colors.black;
  static const Color cardDivider = Color(0x33FFFFFF); // White 20%
  static const Color cardDesc = Color(0xCCFFFFFF); // White 80%

  // Skills Keyboard Colors
  static const Color keyboardChassis = Color(0xFF111111);
  static const Color keyboardChassisSide = Color(0xFF000000);
  static const Color keySide = Color(0xFF1A1A1A);
  static const Color keyTop = Color(0xFF262626);
  static const Color keyHighlight = Color(0xFFFFFFFF);
  static const Color keyTextNormal = Colors.white;
  static const Color keyTextHighlight = Colors.black;

  // Bold Text Reveal Colors
  static const Color boldRevealBase = Color(0xFF444444);
  static const Color boldRevealShine = Color(0xFFFFFFFF);
  static const Color boldRevealEdge = Color(0xFFFFC107);

  // Glassy Gradients (Logo Overlay)
  static const List<Color> glassyColors = [
    Color.fromRGBO(214, 166, 95, 0.2),
    Color.fromRGBO(169, 95, 59, 0.05),
    Color.fromRGBO(154, 72, 47, 0.7),
    Color.fromRGBO(169, 95, 59, 0.05),
    Color.fromRGBO(214, 166, 95, 0.2),
  ];
  static const List<double> glassyStops = [0.0, 0.4, 0.5, 0.6, 1.0];

  // Fonts
  static const String fontInconsolata = 'InconsolataNerd';
  static const String fontModernUrban = 'ModrntUrban';
  static const String fontInter = 'Inter';
  static const String fontBroadway = 'Broadway';

  // Text Sizes
  static const double titleFontSize = 80.0;
  static const double primaryTitleFontSize = 48.0;
  static const double philosophyFontSize = 40.0;
  static const double contactTitleFontSize = 110.0;
  static const double contactDescriptionFontSize = 18.0;
  static const double buttonFontSize = 16.0;
  static const double formLabelFontSize = 15.0;
  static const double testimonialTitleFontSize = 48.0;
  static const double roleFontSize = 32.0;
  static const double companyFontSize = 12.0;
  static const double durationFontSize = 14.0;

  static const double loadingFontSize = 40.0;
  static const double enterFontSize = 15.0;

  // Phase 3 Text Sizes
  static const double cardIconVisibleSize = 42.0;
  static const double cardTitleVisibleSize = 22.0;
  static const double cardDescVisibleSize = 15.0;

  static const double keyFontSize = 10.0;

  // Phase 4 Text Sizes
  static const double expDescFontSize = 14.0;
  static const double satelliteFontSize = 16.0;
  static const double testiQuoteFontSize = 16.0;
  static const double testiAuthorFontSize = 14.0;
  static const double testiRoleFontSize = 12.0;

  // Text Spacing
  static const double loadingLetterSpacing = 12.0;
  static const double enterLetterSpacing = 10.0;
  static const double primaryTitleLetterSpacing = 8.0;

  // --- Animation Durations (Sec) ---
  static const double secTitleAnimDuration = 4.0;
  static const double secTitleHideDuration = 0.5;

  // --- Experience Styles ---
  static const double expActiveOpacity = 1.0;
  static const double expInactiveOpacity = 0.2;

  // --- Secondary Title Styles ---
  static const double secondaryTitleFontSize = 14.0;
  static const double secondaryTitleSpacing = 4.0;
  static const Color secondaryTitleColor = Color(0xFFAAB0B5);
  static const double testimonialTitleSpacing = 2.0;

  static const Color uiBlack = Colors.black;
  static const Color white = Colors.white;

  // --- Testimonial Styles ---
  static const double testiDimFactorBase = 0.5;
  static const double testiFillAlpha = 0.05;
  static const double testiBorderAlphaBase = 0.1;
  static const double testiQuoteAlpha = 0.9;
  static const double testiBorderWidth = 1.0;

  // --- Arrow & Menu Styles ---
  static const double arrowShadowBlur = 4.0;
  static const Color arrowColor = Color(0xFFC0C0C0);
  static const double menuBorderAlpha = 0.3;

  // --- Orbital Arcs Styles ---
  static const double orbitalArcAlphaOuter = 0.05;
  static const double orbitalArcAlphaMid = 0.08;
  static const double orbitalArcAlpha = 0.1;
  static const double orbitalArcShineAlpha = 0.3;
  static const double orbitalArcTailAlpha = 0.0;
  static const Color orbitalArcBaseColor = Colors.white;
  static const double orbitalArcAlphaInner = 0.5;
  static const double orbitalArcAlphaInnerBg = 0.2;

  // --- Logo Overlay ---
  static const double logoOverlayShadowBlur = 10.0;
  static const double logoOverlayShadowOffsetX = 2.0;
  static const double logoOverlayShadowOffsetY = 2.0;

  // --- Default Text Shadow ---
  static const Color textShadowColor = Colors.black45;
  static const double textShadowBlur = 10.0;
  static const double textShadowOffsetX = 2.0;
  static const double textShadowOffsetY = 2.0;

  // --- Text Styles ---
  static const TextStyle philosophyIconStyle = TextStyle(
    fontSize: cardIconVisibleSize,
    fontFamily: fontModernUrban,
  );

  static const TextStyle philosophyTitleStyle = TextStyle(
    fontFamily: fontModernUrban,
    fontSize: cardTitleVisibleSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle philosophyDescStyle = TextStyle(
    fontFamily: fontModernUrban,
    fontSize: cardDescVisibleSize,
    color: cardDesc,
    height: 1.4,
  );

  static const TextStyle cinematicPrimaryStyle = TextStyle(
    fontSize: primaryTitleFontSize,
    letterSpacing: primaryTitleLetterSpacing,
    fontWeight: FontWeight.w500,
    fontFamily: fontModernUrban,
  );

  static const TextStyle experienceDescStyle = TextStyle(
    fontFamily: fontInter,
    fontSize: expDescFontSize,
    color: Colors.white,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
}
