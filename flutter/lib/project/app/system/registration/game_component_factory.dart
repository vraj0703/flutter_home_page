import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
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
import 'package:flutter_home_page/project/app/views/components/contact/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/back_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/white_overlay_component.dart';
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
  late final ContactTextComponent _contactText;
  late final ContactTrailComponent _contactTrail;
  late final WhiteOverlayComponent _whiteOverlay;
  late final BackButtonComponent _backButton;
  late final ContactTextButton _homeButton;
  late final ContactIconButton _audioToggle;

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

  ContactTextComponent get contactText => _contactText;

  ContactTrailComponent get contactTrail => _contactTrail;

  WhiteOverlayComponent get whiteOverlay => _whiteOverlay;

  BackButtonComponent get backButton => _backButton;
  ContactTextButton get homeButton => _homeButton;
  ContactIconButton get audioToggle => _audioToggle;

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
    _contactText,
    _contactTrail,
    _whiteOverlay,
    _backButton,
    _homeButton,
    _audioToggle,
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

    // ─── Metallic shader program (shared by title, secondary title, contact) ───
    if (!_shaderCache.containsKey(GameAssets.metallicShader)) {
      _shaderCache[GameAssets.metallicShader] =
          await FragmentProgram.fromAsset(GameAssets.metallicShader);
    }
    final metallicProgram = _shaderCache[GameAssets.metallicShader]!;

    // ─── Cinematic Title ───
    _cinematicTitle = CinematicTitleComponent(
      primaryText: GameStrings.primaryTitle,
      shaderProgram: metallicProgram,
      position: size / 2,
    );
    _cinematicTitle.priority = GameLayout.zTitle;

    // ─── Cinematic Secondary Title ───
    _cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: GameStrings.secondaryTitle,
      shaderProgram: metallicProgram,
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

    // ─── contact Text ───
    _contactText = ContactTextComponent(
      text: GameStrings.contactTitle,
      style: material.TextStyle(
        fontFamily: GameStyles.fontModernUrban,
        fontSize: GameStyles.contactFontSize,
        fontWeight: material.FontWeight.bold,
        color: GameStyles.contactText,
        letterSpacing: 1.5,
      ),
      shaderProgram: metallicProgram,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * GameLayout.contactTextXRatio, size.y / 2),
    );
    _contactText.priority = GameLayout.zContent;
    _contactText.opacity = 0.0;

    // ─── contact Trail ───
    _contactTrail = ContactTrailComponent();
    _contactTrail.priority = GameLayout.zContent;
    _contactTrail.opacity = 0.0;

    // ─── Back Button (Contact Section) ───
    _backButton = BackButtonComponent(
      position: Vector2(80.0, size.y - 50.0),
      anchor: Anchor.center,
    );
    _backButton.priority = GameLayout.zContent + 2;
    _backButton.opacity = 0.0;

    // ─── Home Button (Contact Section) ───
    _homeButton = ContactTextButton(
      text: 'Home',
      position: Vector2(size.x - 160.0, size.y - 50.0),
    );
    _homeButton.priority = GameLayout.zContent + 2;
    _homeButton.opacity = 0.0;

    // ─── Audio Toggle Button (Contact Section) ───
    _audioToggle = ContactIconButton(
      icon: '♪',
      position: Vector2(size.x - 50.0, size.y - 50.0),
    );
    _audioToggle.priority = GameLayout.zContent + 2;
    _audioToggle.opacity = 0.0;

    // ─── White Overlay ───
    _whiteOverlay = WhiteOverlayComponent();
    _whiteOverlay.size = size;
    _whiteOverlay.opacity = 0.0; // Default hidden
  }
}

/// Simple text button for contact section (Home, etc.)
class ContactTextButton extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasPaint {
  final String text;
  VoidCallback? onTap;
  bool _hovering = false;
  double _hoverGlow = 0.0;

  ContactTextButton({required this.text, super.position})
      : super(size: Vector2(100, 44), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _hoverGlow += ((_hovering ? 1.0 : 0.0) - _hoverGlow) * dt * 6.0;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;
    final rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(22));
    canvas.drawRRect(rrect, Paint()..color = Color.fromRGBO(255, 255, 255, (0.08 + _hoverGlow * 0.12) * opacity));
    canvas.drawRRect(rrect, Paint()..color = Color.fromRGBO(255, 255, 255, (0.15 + _hoverGlow * 0.5) * opacity)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final tp = material.TextPainter(
      text: material.TextSpan(text: text, style: material.TextStyle(fontSize: 14, fontWeight: material.FontWeight.w500, color: Color.fromRGBO(255, 255, 255, 0.8 * opacity), letterSpacing: 1.0)),
      textDirection: material.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap?.call();
  @override
  void onHoverEnter() => _hovering = true;
  @override
  void onHoverExit() => _hovering = false;
  @override
  bool containsLocalPoint(Vector2 point) =>
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(22)).contains(point.toOffset());
}

/// Simple icon button for contact section (Audio toggle)
class ContactIconButton extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasPaint {
  VoidCallback? onTap;
  bool Function()? isMuted;
  bool _hovering = false;
  double _hoverGlow = 0.0;

  ContactIconButton({required String icon, this.isMuted, super.position})
      : super(size: Vector2(44, 44), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _hoverGlow += ((_hovering ? 1.0 : 0.0) - _hoverGlow) * dt * 6.0;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0.0) return;
    final muted = isMuted?.call() ?? false;
    final label = muted ? '🔇' : '🔊';
    final rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(22));
    canvas.drawRRect(rrect, Paint()..color = Color.fromRGBO(255, 255, 255, (0.08 + _hoverGlow * 0.12) * opacity));
    canvas.drawRRect(rrect, Paint()..color = Color.fromRGBO(255, 255, 255, (0.15 + _hoverGlow * 0.5) * opacity)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final tp = material.TextPainter(
      text: material.TextSpan(text: label, style: material.TextStyle(fontSize: 18, color: Color.fromRGBO(255, 255, 255, 0.8 * opacity))),
      textDirection: material.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap?.call();
  @override
  void onHoverEnter() => _hovering = true;
  @override
  void onHoverExit() => _hovering = false;
  @override
  bool containsLocalPoint(Vector2 point) =>
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(22)).contains(point.toOffset());
}
