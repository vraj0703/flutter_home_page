import 'package:flutter/material.dart';

class GameAssets {
  // Images
  static const String logo = 'logo.png';

  // Shaders
  static const String metallicShader = 'assets/shaders/metallic_text.frag';
  static const String godRaysShader = 'assets/shaders/god_rays.frag';
  static const String logoShader = 'assets/shaders/logo.frag';
  static const String backgroundShader =
      'assets/shaders/background_run_v2.frag';
}

class GameStrings {
  static const String primaryTitle = "VISHAL RAJ";
  static const String secondaryTitle = "Welcome to my space";
  static const String boldText = "Crafting Clarity from Chaos.";
  static const String philosophyTitle = "My Philosophy";
  static const String contactTitle = "CONTACT";
  static const String contactDescription =
      "If you're curious to know more about what you saw, I invite you to contact me or follow me on social media.";
  static const String contactSendButton = "SEND";
  static const String contactNameLabel = "Name";
  static const String contactEmailLabel = "Email";
  static const String contactMessageLabel = "How can I help you?";
  static const String testimonialsTitle = "TESTIMONIALS";
  static const String addTestimonialButton = "Add Testimonial";

  static const String loadingText = 'L O A D I N G';
  static const String enterText = 'ENTER';

  static const List<String> skillKeys = [
    "Flutter",
    "Dart",
    "Flame",
    "Firebase",
    "Git",
    "Figma",
    "Block",
    "Provider",
    "Riverpod",
    "Clean Arch",
    "CI/CD",
    "Jira",
    "Agile",
    "SOLID",
    "REST API",
    "GraphQL",
    "Python",
    "C++",
    "GLSL",
  ];
}

class GameStyles {
  // Colors
  static const Color primaryBackground = Color(0xFFC78E53);
  static const Color accentGold = Color(
    0xFFC78E53,
  ); // Same as background for now, used in buttons

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
  static const String fontInter = 'Inter'; // Added Inter
  static const String fontBroadway = 'Broadway';

  // Text Sizes
  static const double titleFontSize = 80.0;
  static const double primaryTitleFontSize = 54.0;
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
}
