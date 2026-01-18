import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/views/components/experience/experience_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'components/god_ray.dart';
import 'components/logo_layer/logo.dart';
import 'components/logo_layer/logo_overlay.dart';
import 'components/bold_text/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/views/components/testimonials/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_page_component.dart';
import 'package:flutter_home_page/project/app/views/components/skills/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/system/game_component_factory.dart';
import 'package:flutter_home_page/project/app/system/game_scroll_configurator.dart';

class MyGame extends FlameGame
    with PointerMoveCallbacks, TapCallbacks, ScrollDetector {
  VoidCallback? onStartExitAnimation;
  final Queuer queuer;
  final StateProvider stateProvider;

  MyGame({
    this.onStartExitAnimation,
    required this.queuer,
    required this.stateProvider,
  });

  late RayMarchingShadowComponent shadowScene;
  late GodRayComponent godRay;
  late LogoOverlayComponent interactiveUI;
  late LogoComponent logoComponent;
  late FragmentShader metallicShader;

  late BackgroundRunComponent backgroundRun;
  late CinematicTitleComponent cinematicTitle;
  late CinematicSecondaryTitleComponent cinematicSecondaryTitle;

  BoldTextRevealComponent? boldTextReveal;
  PhilosophyTextComponent? philosophyText;
  PeelingCardStackComponent? cardStack;
  ExperiencePageComponent? experiencePage;
  TestimonialPageComponent? testimonialPage;
  SkillsKeyboardComponent? skillsPage;
  ContactPageComponent? contactPage;

  RectangleComponent? _dimLayer;

  Vector2 _virtualLightPosition = Vector2.zero();
  Vector2 _targetLightPosition = Vector2.zero();
  Vector2 _lightDirection = Vector2.zero();
  Vector2 _targetLightDirection = Vector2.zero();

  Vector2 _targetLogoPosition = Vector2.zero();
  double _targetLogoScale = 3.0; // Initial zoom
  double _currentLogoScale = 3.0;
  Vector2 _baseLogoSize = Vector2.zero();

  double _logoPositionProgress = 0.0;
  double _logoScaleProgress = 0.0;
  final SpringCurve _logoSpringCurve = const SpringCurve(
    mass: 0.8,
    stiffness: 200.0,
    damping: 15.0,
  );

  Vector2? _lastKnownPointerPosition;

  final double smoothingSpeed = 20.0;
  final double glowVerticalOffset = 10.0;

  late final Timer _inactivityTimer;
  static const double inactivityTimeout = 5.0;
  static const double uiFadeDuration = 0.5;
  static const double headerY = 60.0;

  final ScrollSystem scrollSystem = ScrollSystem();
  final ScrollOrchestrator scrollOrchestrator = ScrollOrchestrator();

  final GameComponentFactory _componentFactory = GameComponentFactory();
  final GameScrollConfigurator _scrollConfigurator = GameScrollConfigurator();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = size / 2;

    _inactivityTimer = Timer(inactivityTimeout, onTick: () {}, repeat: false);
    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();

    await _initializeComponents();

    queuer.queue(event: const SceneEvent.gameReady());
    scrollSystem.register(scrollOrchestrator);
  }

  Future<void> _initializeComponents() async {
    // 1. Logo Layer
    final logoImage = await _componentFactory.loadImage('logo.png');
    final startZoom = 3.0;
    _baseLogoSize = Vector2(
      logoImage.width.toDouble(),
      logoImage.height.toDouble(),
    );
    final logoSize = _baseLogoSize * startZoom;
    final bgColor = backgroundColor();

    shadowScene = await _componentFactory.createShadowScene(
      size: size,
      logoImage: logoImage,
      logoSize: logoSize,
    );
    await add(shadowScene);

    logoComponent = await _componentFactory.createLogoComponent(
      size: size,
      logoImage: logoImage,
      logoSize: logoSize,
      tintColor: bgColor,
    );
    await add(logoComponent);

    godRay = _componentFactory.createGodRay(size);
    await add(godRay);

    // 2. Interactive UI
    interactiveUI = _componentFactory.createInteractiveUI(
      size: size,
      stateProvider: stateProvider,
      queuer: queuer,
    );
    await add(interactiveUI);

    // 3. Background & Titles
    backgroundRun = await _componentFactory.createBackgroundRun(size);
    await add(backgroundRun);

    metallicShader = await _componentFactory.loadShader(
      'assets/shaders/metallic_text.frag',
    );

    cinematicTitle = _componentFactory.createCinematicTitle(
      size: size,
      shader: metallicShader,
    );
    await add(cinematicTitle);

    cinematicSecondaryTitle = _componentFactory.createCinematicSecondaryTitle(
      size: size,
      shader: metallicShader,
    );
    await add(cinematicSecondaryTitle);

    boldTextReveal = _componentFactory.createBoldTextReveal(
      size: size,
      shader: metallicShader,
    );
    await add(boldTextReveal!);

    _dimLayer = _componentFactory.createDimLayer(size);
    await add(_dimLayer!);

    // 4. Scrollable Pages
    philosophyText = _componentFactory.createPhilosophyText(
      size: size,
      shader: metallicShader,
    );
    await add(philosophyText!);

    cardStack = _componentFactory.createCardStack(
      size: size,
      scrollOrchestrator: scrollOrchestrator,
    );
    await add(cardStack!);

    experiencePage = _componentFactory.createExperiencePage(size);
    await add(experiencePage!);

    testimonialPage = _componentFactory.createTestimonialPage(
      size: size,
      shader: metallicShader,
    );
    await add(testimonialPage!);

    skillsPage = _componentFactory.createSkillsPage(size);
    await add(skillsPage!);

    contactPage = _componentFactory.createContactPage(
      size: size,
      shader: metallicShader,
    );
    await add(contactPage!);
  }

  @override
  Color backgroundColor() => const Color(0xFFC78E53);

  @override
  void onScroll(PointerScrollInfo info) {
    if (!isLoaded) return;
    queuer.queue(event: const SceneEvent.onScroll());

    final delta = info.scrollDelta.global.y;
    scrollSystem.onScroll(delta);

    stateProvider.sceneState().maybeWhen(
      menu: (uiOpacity) {
        queuer.queue(event: SceneEvent.onScrollSequence(delta));
      },
      orElse: () {},
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    queuer.queue(event: SceneEvent.tapDown(event));
    super.onTapDown(event);
  }

  void loadTitleBackground() {
    backgroundRun.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final center = size / 2;
    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {},
      logo: () {
        logoComponent.position = center;
        shadowScene.logoPosition = center;
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);

        interactiveUI.position = center;
        interactiveUI.gameSize = size;
      },
      logoOverlayRemoving: () {},
      titleLoading: () {
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);
      },
      title: () {
        cinematicTitle.position = center;
        cinematicSecondaryTitle.position = center + Vector2(0, 48);
      },
      menu: (uiOpacity) {
        _updateMenuLayoutTargets();
      },
    );
    _dimLayer?.size = size;
    boldTextReveal?.position = center;
  }

  void _updateMenuLayoutTargets() {
    final logoScale = 0.25;
    final logoW = _baseLogoSize.x * logoScale;
    final headerY = MyGame.headerY;
    final startX = 60.0;
    final logoCX = startX + (logoW / 2);
    _targetLogoPosition = Vector2(logoCX, headerY);
    _targetLogoScale = logoScale;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    final cursorPosition = _lastKnownPointerPosition ?? size / 2;
    followCursor(dt, cursorPosition);

    scrollSystem.updateSnap(dt);

    stateProvider.sceneState().when(
      loading: (isSvgReady, isGameReady) {
        cinematicTitle.position = size / 2;
        cinematicSecondaryTitle.position = size / 2 + Vector2(0, 48);
        interactiveUI.inactivityOpacity += dt / uiFadeDuration;
      },
      logo: () {
        cinematicTitle.position = size / 2;
      },
      logoOverlayRemoving: () {
        _targetLogoPosition = Vector2(36, 36);
        _targetLogoScale = 0.3;
        _animateLogo(dt);
      },
      titleLoading: () {},
      title: () {},
      menu: (uiOpacity) {
        _targetLightPosition = size / 2;
        _animateLogo(dt);
      },
    );
    _inactivityTimer.update(dt);
  }

  void _animateLogo(double dt) {
    final positionDistance =
        (logoComponent.position - _targetLogoPosition).length;
    final scaleDistance = (_currentLogoScale - _targetLogoScale).abs();

    if (positionDistance > 2.0) {
      _logoPositionProgress = (_logoPositionProgress + dt * 6.0).clamp(
        0.0,
        1.0,
      );
      final curvedProgress = _logoSpringCurve.transform(_logoPositionProgress);
      logoComponent.position.lerp(
        _targetLogoPosition,
        curvedProgress * dt * 10.0,
      );
      shadowScene.logoPosition.lerp(
        _targetLogoPosition,
        curvedProgress * dt * 10.0,
      );
    } else {
      logoComponent.position = _targetLogoPosition.clone();
      shadowScene.logoPosition = _targetLogoPosition.clone();
      _logoPositionProgress = 0.0;
    }

    if (scaleDistance > 0.01) {
      _logoScaleProgress = (_logoScaleProgress + dt * 6.0).clamp(0.0, 1.0);
      final curvedProgress = _logoSpringCurve.transform(_logoScaleProgress);
      _currentLogoScale =
          lerpDouble(
            _currentLogoScale,
            _targetLogoScale,
            curvedProgress * dt * 10.0,
          ) ??
          3.0;
    } else {
      _currentLogoScale = _targetLogoScale;
      _logoScaleProgress = 0.0;
    }

    if (_baseLogoSize != Vector2.zero()) {
      final newSize = _baseLogoSize * _currentLogoScale;
      logoComponent.size = newSize;
      shadowScene.logoSize = newSize;
    }
  }

  void followCursor(double dt, Vector2 position) {
    godRay.position = position;
    _targetLightPosition = position + Vector2(0, glowVerticalOffset);
    final vectorFromCenter = position - size / 2;
    if (vectorFromCenter.length2 > 0) {
      _targetLightDirection = vectorFromCenter.normalized();
    }
    interactiveUI.cursorPosition = position - interactiveUI.position;

    final distance = (_targetLightPosition - _virtualLightPosition).length;
    final speed = distance > 100 ? 22.0 : 18.0;
    final rawT = speed * dt;
    final easedT = Curves.easeOutQuad.transform(rawT.clamp(0.0, 1.0));

    _virtualLightPosition.lerp(_targetLightPosition, easedT);
    _lightDirection.lerp(_targetLightDirection, easedT);
    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightPosition = _virtualLightPosition;
    shadowScene.lightDirection = _lightDirection;
    shadowScene.logoSize = logoComponent.size;
  }

  void enterTitle() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () => cinematicTitle.show(
        () => cinematicSecondaryTitle.show(
          () => queuer.queue(event: SceneEvent.titleLoaded()),
        ),
      ),
    );
  }

  void enterMenu() {
    _updateMenuLayoutTargets();

    // Delegate to ScrollConfigurator
    _scrollConfigurator.configureScroll(
      scrollOrchestrator: scrollOrchestrator,
      scrollSystem: scrollSystem,
      screenSize: size,
      stateProvider: stateProvider,
      components: GameComponents(
        cinematicTitle: cinematicTitle,
        cinematicSecondaryTitle: cinematicSecondaryTitle,
        interactiveUI: interactiveUI,
        dimLayer: _dimLayer!,
        boldTextReveal: boldTextReveal!,
        philosophyText: philosophyText!,
        cardStack: cardStack!,
        experiencePage: experiencePage!,
        testimonialPage: testimonialPage!,
        skillsPage: skillsPage!,
        contactPage: contactPage!,
      ),
    );
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}
