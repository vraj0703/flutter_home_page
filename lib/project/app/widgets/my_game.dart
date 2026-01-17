import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/models/philosophy_card_data.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/opacity.dart';
import 'package:flutter_home_page/project/app/system/scroll_effects/parallax.dart';
import 'package:flutter_home_page/project/app/system/ui_opacity_observer.dart';
import 'package:flutter_home_page/project/app/widgets/components/cinematic_title.dart';
import 'package:flutter_home_page/project/app/widgets/components/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/widgets/components/background_run_component.dart';
import 'components/god_ray.dart';
import 'components/logo.dart';
import 'components/logo_overlay.dart';
import 'components/bold_text_reveal_component.dart';
import 'package:flutter_home_page/project/app/system/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll_orchestrator.dart';
import 'package:flutter_home_page/project/app/system/bold_text_controller.dart';
import 'package:flutter_home_page/project/app/system/philosophy_page_controller.dart';
import 'package:flutter_home_page/project/app/widgets/components/philosophy_text_component.dart';
import 'package:flutter_home_page/project/app/widgets/components/peeling_card_stack_component.dart';
import 'package:flutter_home_page/project/app/widgets/components/experience_page_component.dart';
import 'package:flutter_home_page/project/app/system/experience_page_controller.dart';
import 'package:flutter_home_page/project/app/widgets/components/testimonial_page_component.dart';
import 'package:flutter_home_page/project/app/system/testimonial_page_controller.dart';
import 'package:flutter_home_page/project/app/widgets/components/contact_page_component.dart';
import 'package:flutter_home_page/project/app/system/contact_page_controller.dart';
import 'package:flutter_home_page/project/app/widgets/components/skills_keyboard_component.dart';
import 'package:flutter_home_page/project/app/system/skills_page_controller.dart';
import 'package:flutter_home_page/project/app/curves/custom_curves.dart';
import 'package:flutter/material.dart' as material;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final center = size / 2;

    _inactivityTimer = Timer(inactivityTimeout, onTick: () {}, repeat: false);

    _targetLightPosition = center;
    _virtualLightPosition = center.clone();
    _targetLightDirection = Vector2(0, -1)..normalize();
    _lightDirection = _targetLightDirection.clone();

    await loadLogoLayer();
    await loadLayerLineAndStart();
    await loadLayerName();

    queuer.queue(event: const SceneEvent.gameReady());

    scrollSystem.register(scrollOrchestrator);
  }

  Future<void> loadLogoLayer() async {
    final sprite = await Sprite.load('logo.png');
    final Image image = sprite.image;
    double zoom = 3;
    _baseLogoSize = Vector2(image.width.toDouble(), image.height.toDouble());
    Vector2 logoSize = _baseLogoSize * zoom;

    final program = await FragmentProgram.fromAsset(
      'assets/shaders/god_rays.frag',
    );
    final shader = program.fragmentShader();
    final logoProgram = await FragmentProgram.fromAsset(
      'assets/shaders/logo.frag',
    );
    shadowScene = RayMarchingShadowComponent(
      fragmentShader: shader,
      logoImage: image,
      logoSize: logoSize,
    );
    shadowScene.logoPosition = size / 2;
    await add(shadowScene);

    final bgColor = backgroundColor();
    logoComponent = LogoComponent(
      shader: logoProgram.fragmentShader(),
      logoTexture: image,
      tintColor: bgColor,
      size: logoSize,
      position: size / 2,
    );
    logoComponent.priority = 10;
    await add(logoComponent);

    godRay = GodRayComponent();
    godRay.priority = 20;
    godRay.position = size / 2;
    await add(godRay);
  }

  Future<void> loadLayerLineAndStart() async {
    interactiveUI = LogoOverlayComponent(
      stateProvider: stateProvider,
      queuer: queuer,
    );
    interactiveUI.position = size / 2;
    interactiveUI.priority = 30;
    interactiveUI.gameSize = size;
    interactiveUI.gameSize = size;
    await add(interactiveUI);
  }

  Future<void> loadLayerName() async {
    final backgroundProgram = await FragmentProgram.fromAsset(
      'assets/shaders/background_run_v2.frag',
    );

    backgroundRun = BackgroundRunComponent(
      shader: backgroundProgram.fragmentShader(),
      size: size,
      priority: 1,
    );
    await add(backgroundRun);

    final metallicTextProgram = await FragmentProgram.fromAsset(
      'assets/shaders/metallic_text.frag',
    );
    metallicShader = metallicTextProgram.fragmentShader();

    cinematicTitle = CinematicTitleComponent(
      primaryText: "VISHAL RAJ",
      shader: metallicShader,
      position: size / 2,
    );
    cinematicTitle.priority = 25;
    add(cinematicTitle);

    cinematicSecondaryTitle = CinematicSecondaryTitleComponent(
      text: "Welcome to my space",
      shader: metallicShader,
      position: size / 2 + Vector2(0, 48),
    );
    cinematicSecondaryTitle.priority = 24;
    add(cinematicSecondaryTitle);

    boldTextReveal = BoldTextRevealComponent(
      text: "Crafting Clarity from Chaos.",
      textStyle: material.TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w500,
        fontFamily: 'InconsolataNerd',
        letterSpacing: 2.0,
      ),
      shader: metallicShader,
      baseColor: const Color(0xFFE3E4E5),
      position: size / 2,
    );
    boldTextReveal!.priority = 26;
    boldTextReveal!.opacity = 0.0;
    await add(boldTextReveal!);

    _dimLayer = RectangleComponent(
      priority: 2,
      size: size,
      paint: Paint()..color = const Color(0xFF000000).withValues(alpha: 0.0),
    );
    await add(_dimLayer!);
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
    scrollSystem.setScrollOffset(0.0);
    cinematicTitle.show(() {});
    cinematicSecondaryTitle.show(() {});
    scrollOrchestrator.addBinding(
      cinematicTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: 800,
        initialPosition: cinematicTitle.position.clone(),
        endOffset: Vector2(0, -1000),
        curve: const SpringCurve(mass: 1.0, stiffness: 180.0, damping: 12.0),
      ),
    );

    scrollOrchestrator.addBinding(
      cinematicTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 500,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      cinematicSecondaryTitle,
      ParallaxScrollEffect(
        startScroll: 0,
        endScroll: 1000,
        initialPosition: cinematicSecondaryTitle.position.clone(),
        endOffset: Vector2(0, -1000),
        curve: const SpringCurve(mass: 0.8, stiffness: 200.0, damping: 10.0),
      ),
    );

    scrollOrchestrator.addBinding(
      cinematicSecondaryTitle,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      interactiveUI,
      OpacityScrollEffect(
        startScroll: 0,
        endScroll: 100,
        startOpacity: 1.0,
        endOpacity: 0.0,
        curve: const ExponentialEaseOut(),
      ),
    );

    scrollOrchestrator.addBinding(
      _dimLayer!,
      OpacityScrollEffect(
        startScroll: 1500,
        endScroll: 2000,
        startOpacity: 0.0,
        endOpacity: 0.6,
        curve: Curves.easeOutQuart,
      ),
    );

    scrollSystem.register(
      BoldTextController(
        component: boldTextReveal!,
        screenWidth: size.x,
        centerPosition: size / 2,
      ),
    );

    final philosophyText = PhilosophyTextComponent(
      text: "My Philosophy",
      style: material.TextStyle(
        fontFamily: 'ModrntUrban',
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: material.Colors.white,
        letterSpacing: 1.5,
      ),
      shader: metallicShader,
      anchor: Anchor.centerLeft,
      position: Vector2(size.x * 0.15, size.y / 2),
    );
    philosophyText.priority = 25;
    philosophyText.opacity = 0.0;
    add(philosophyText);

    final cardStack = PeelingCardStackComponent(
      scrollOrchestrator: scrollOrchestrator,
      cardsData: cardData,
      size: Vector2(size.x * 0.4, size.y * 0.6),
      position: Vector2(size.x * 0.75, size.y / 2),
    );
    cardStack.anchor = Anchor.center;
    cardStack.priority = 25;
    cardStack.opacity = 0.0;
    add(cardStack);

    scrollSystem.register(
      PhilosophyPageController(
        component: philosophyText,
        cardStack: cardStack,
        initialTextPos: philosophyText.position.clone(),
        initialStackPos: cardStack.position.clone(),
      ),
    );

    final experiencePage = ExperiencePageComponent(size: size);
    experiencePage.priority = 25;
    add(experiencePage);

    scrollSystem.register(ExperiencePageController(component: experiencePage));
    scrollSystem.register(UIOpacityObserver(stateProvider: stateProvider));

    final testimonialPage = TestimonialPageComponent(
      size: size,
      shader: metallicShader,
    );
    testimonialPage.priority = 25;
    testimonialPage.opacity = 0.0;
    add(testimonialPage);

    scrollSystem.register(
      TestimonialPageController(component: testimonialPage),
    );

    final skillsPage = SkillsKeyboardComponent(size: size);
    skillsPage.priority = 28; // Above Testimonials, Below Contact
    skillsPage.opacity = 0.0;
    add(skillsPage);

    scrollSystem.register(SkillsPageController(component: skillsPage));

    final contactPage = ContactPageComponent(
      size: size,
      shader: metallicShader,
    );
    contactPage.priority = 30;
    contactPage.position = Vector2(0, size.y);
    add(contactPage);

    scrollSystem.register(
      ContactPageController(component: contactPage, screenHeight: size.y),
    );
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastKnownPointerPosition = event.localPosition;
  }
}
