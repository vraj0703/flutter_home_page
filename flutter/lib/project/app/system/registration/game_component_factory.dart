import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_home_page/project/app/config/game_assets.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_strings.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_tint_component.dart';
import 'package:flutter_home_page/project/app/views/components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_home_page/project/app/views/components/god_ray.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/back_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/white_overlay_component.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';

class GameComponentFactory {
  // Shader cache to avoid duplicate loads
  final Map<String, FragmentProgram> _shaderCache = {};

  // ── Private component fields ──────────────────────────────────────────
  late final RayMarchingShadowComponent _shadowScene;
  late final LogoComponent _logoComponent;
  late final LogoOverlayComponent _logoOverlay;
  late final GodRayComponent _godRay;
  late final BackgroundRunComponent _backgroundRun;
  late final BackgroundTintComponent _backgroundTint;
  late final BeachBackgroundComponent _beachBackground;
  late final CinematicTitleComponent _cinematicTitle;
  late final CinematicSecondaryTitleComponent _cinematicSecondaryTitle;
  late final BoldTextRevealComponent _boldTextReveal;
  late final PhilosophyTextComponent _philosophyText;
  late final PhilosophyTrailComponent _philosophyTrail;
  late final WhiteOverlayComponent _whiteOverlay;
  late final BackButtonComponent _backButton;

  // ── Typed public getters ──────────────────────────────────────────────
  RayMarchingShadowComponent get shadowScene => _shadowScene;

  LogoComponent get logoComponent => _logoComponent;

  LogoOverlayComponent get logoOverlay => _logoOverlay;

  GodRayComponent get godRay => _godRay;

  BackgroundRunComponent get backgroundRun => _backgroundRun;

  BackgroundTintComponent get backgroundTint => _backgroundTint;

  BeachBackgroundComponent get beachBackground => _beachBackground;

  CinematicTitleComponent get cinematicTitle => _cinematicTitle;

  CinematicSecondaryTitleComponent get cinematicSecondaryTitle =>
      _cinematicSecondaryTitle;

  BoldTextRevealComponent get boldTextReveal => _boldTextReveal;

  PhilosophyTextComponent get philosophyText => _philosophyText;

  PhilosophyTrailComponent get philosophyTrail => _philosophyTrail;

  WhiteOverlayComponent get whiteOverlay => _whiteOverlay;

  BackButtonComponent get backButton => _backButton;

  /// All components in render-priority order for adding to the game tree.
  List<Component> get allComponents => [
    _shadowScene,
    _logoComponent,
    _logoOverlay,
    _godRay,
    _backgroundRun,
    _backgroundTint,
    _beachBackground,
    _cinematicTitle,
    _cinematicSecondaryTitle,
    _boldTextReveal,
    _philosophyText,
    _philosophyTrail,
    _whiteOverlay,
    _backButton,
  ];

  // ── Shader helper ─────────────────────────────────────────────────────

  /// Loads and caches the [FragmentProgram] for the given asset [path].
  ///
  /// Each call creates a **new** [FragmentShader] instance from the cached
  /// program. This is intentional — every component needs its own shader
  /// instance to maintain independent uniform state.
  Future<FragmentShader> _getOrLoadShaderProgram(String path) async {
    if (!_shaderCache.containsKey(path)) {
      _shaderCache[path] = await FragmentProgram.fromAsset(path);
    }
    return _shaderCache[path]!.fragmentShader();
  }

  // ── Initialize all components directly ────────────────────────────────
  Future<void> initializeComponents({
    required Vector2 size,
    required StateProvider stateProvider,
    required Queuer queuer,
    required material.Color Function() backgroundColorCallback,
    void Function(int section)? onSectionTap,
  }) async {
    // ─── Shadow Scene ───
    final logoImage = await Flame.images.load(GameAssets.logo);
    final godRaysShader = await _getOrLoadShaderProgram(
      GameAssets.godRaysShader,
    );
    final startZoom = GameLayout.logoInitialScale;
    final baseLogoSize = Vector2(
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final logoSize = baseLogoSize * startZoom;

    _shadowScene = RayMarchingShadowComponent(
      fragmentShader: godRaysShader,
      logoImage: logoImage,
      logoSize: logoSize,
    );
    _shadowScene.logoPosition = size / 2;

    // ─── Logo ───
    final logoShader = await _getOrLoadShaderProgram(GameAssets.logoShader);
    final tintColor = backgroundColorCallback();

    _logoComponent = LogoComponent(
      shader: logoShader,
      logoTexture: logoImage,
      tintColor: tintColor,
      size: logoSize,
      position: size / 2,
    );
    _logoComponent.priority = GameLayout.zLogo;

    // ─── Logo Overlay ───
    _logoOverlay = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    _logoOverlay.position = size / 2;
    _logoOverlay.priority = GameLayout.zLogoOverlay;
    _logoOverlay.gameSize = size;

    // ─── God Ray ───
    _godRay = GodRayComponent();
    _godRay.priority = GameLayout.zGodRay;
    _godRay.position = size / 2;

    // ─── Background Run ───
    final bgRunShader = await _getOrLoadShaderProgram(
      GameAssets.backgroundRunShader,
    );
    _backgroundRun = BackgroundRunComponent(
      shader: bgRunShader,
      size: size,
      priority: GameLayout.zBackground,
    );

    // ─── Background Tint ───
    _backgroundTint = BackgroundTintComponent();
    _backgroundTint.size = size;
    _backgroundTint.priority = GameLayout.zBackground + 1;

    // ─── Beach Background ───
    final beachShader = await _getOrLoadShaderProgram(GameAssets.beachShader);
    _beachBackground = BeachBackgroundComponent(
      size: size,
      shader: beachShader,
    );
    _beachBackground.opacity = 0.0;
    _beachBackground.priority = 10;

    // ─── Cinematic Title ───
    final metallicShader = await _getOrLoadShaderProgram(
      GameAssets.metallicShader,
    );
    _cinematicTitle = CinematicTitleComponent(
      primaryText: GameStrings.primaryTitle,
      shader: metallicShader,
      position: size / 2,
    );
    _cinematicTitle.priority = GameLayout.zTitle;

    // ─── Cinematic Secondary Title ───
    final metallicShader2 = await _getOrLoadShaderProgram(
      GameAssets.metallicShader,
    );
    _cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: GameStrings.secondaryTitle,
      shader: metallicShader2,
      position: size / 2 + GameLayout.secTitleOffsetVector,
    );
    _cinematicSecondaryTitle.priority = GameLayout.zSecondaryTitle;

    // ─── Bold Text Reveal ───
    final boldShader = await _getOrLoadShaderProgram(
      GameAssets.boldTextEntranceShader,
    );
    _boldTextReveal = BoldTextRevealComponent(
      text: GameStrings.boldText,
      textStyle: material.TextStyle(
        fontSize: GameStyles.titleFontSize,
        fontWeight: material.FontWeight.w500,
        fontFamily: GameStyles.fontInconsolata,
        letterSpacing: 2.0,
      ),
      shader: boldShader,
      position: size / 2,
    );
    _boldTextReveal.priority = GameLayout.zBoldText;
    _boldTextReveal.opacity = 0.0;

    // ─── Philosophy Text ───
    final philoShader = await _getOrLoadShaderProgram(
      GameAssets.metallicShader,
    );
    _philosophyText = PhilosophyTextComponent(
      text: GameStrings.philosophyTitle,
      style: material.TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.philosophyFontSize,
        fontWeight: material.FontWeight.bold,
        color: GameStyles.philosophyText,
        letterSpacing: 1.5,
      ),
      shader: philoShader,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * GameLayout.philosophyTextXRatio, size.y / 2),
    );
    _philosophyText.priority = GameLayout.zContent;
    _philosophyText.opacity = 0.0;

    // ─── Philosophy Trail ───
    _philosophyTrail = PhilosophyTrailComponent();
    _philosophyTrail.priority = GameLayout.zContent;
    _philosophyTrail.opacity = 0.0;

    // ─── Back Button (Contact Section) ───
    _backButton = BackButtonComponent(
      position: Vector2(80.0, size.y - 50.0),
      anchor: Anchor.center,
    );
    _backButton.priority = GameLayout.zContent + 2;
    _backButton.opacity = 0.0;

    // ─── White Overlay ───
    _whiteOverlay = WhiteOverlayComponent();
    _whiteOverlay.size = size;
    _whiteOverlay.opacity = 0.0; // Default hidden
  }
}
