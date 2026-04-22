import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:web/web.dart' as web;

import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/transition/transition_coordinator.dart';
import 'package:flutter_home_page/project/app/views/components/contact/beach_background_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/beach_scene_orchestrator.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_text_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/contact_trail_component.dart';
import 'package:flutter_home_page/project/app/views/components/contact/back_button_component.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo.dart';
import 'package:flutter_home_page/project/app/views/components/contact/white_overlay_component.dart';
import 'package:flutter_home_page/project/app/system/registration/game_component_factory.dart';

class CustomFloatEffect extends Effect {
  final double start;
  final double end;
  final void Function(double) onUpdate;

  CustomFloatEffect(this.start, this.end, this.onUpdate, EffectController controller) : super(controller);

  @override
  void apply(double progress) {
    onUpdate(start + (end - start) * progress);
  }
}

class ContactSection extends Component implements GameSection {
  @override
  double get maxScrollExtent => _maxHeight;
  final ContactTextComponent titleComponent;
  final BeachBackgroundComponent cloudBackground;
  final ContactTrailComponent trailComponent;
  final BackButtonComponent backButton;
  final WhiteOverlayComponent whiteOverlay;
  final LogoComponent logoComponent;
  Vector2 screenSize;
  final VoidCallback playEntrySound;
  final VoidCallback playCompletionSound;
  final GameAudioSystem _audioSystem;

  // ignore: unused_field
  final TransitionCoordinator _transitionCoordinator;

  final ContactTextButton homeButton;
  final ContactIconButton audioToggle;

  double get _maxHeight => trailComponent.maxScrollExtent;
  late BeachSceneOrchestrator orchestrator;
  bool _orchestratorInitialized = false;

  double _animTime = 0.0;

  // --- Contact Section State ---
  bool _isActive = false;

  /// Whether the first reflection capture has been done post-entrance
  bool _reflectionCaptured = false;

  /// Flips true when the entrance Effects have landed. Gates the breathe
  /// animation so it doesn't fight ScaleEffect during the first 1.2s of
  /// entry (the ScaleEffect wins by Flame's update ordering, but writing
  /// titleComponent.scale here every frame is wasted work and a fragility
  /// hazard — one reorder of children and the fight becomes visible).
  bool _entranceDone = false;

  static const double _entranceDuration = 2.0;

  /// Ambient lightning timer
  double _ambientLightningTimer = 0.0;
  static const double _ambientLightningMinInterval = 6.0;
  static const double _ambientLightningMaxInterval = 15.0;
  double _nextLightningAt = 8.0;
  final math.Random _rng = math.Random();

  ContactSection({
    required this.titleComponent,
    required this.cloudBackground,
    required this.trailComponent,
    required this.backButton,
    required this.whiteOverlay,
    required this.logoComponent,
    required this.homeButton,
    required this.audioToggle,
    required this.screenSize,
    required this.playEntrySound,
    required this.playCompletionSound,
    required GameAudioSystem audioSystem,
    required TransitionCoordinator transitionCoordinator,
  }) : _audioSystem = audioSystem,
        _transitionCoordinator = transitionCoordinator {
    orchestrator = BeachSceneOrchestrator(background: cloudBackground);
    cloudBackground.setOrchestrator(orchestrator);
    _orchestratorInitialized = true;

    // Wire Gallery button to navigate to React gallery
    backButton.onTap = navigateBackToReact;
    backButton.opacity = 0.0;
  }

  @override
  VoidCallback? onComplete;

  @override
  VoidCallback? onWarmUpNextSection;

  @override
  VoidCallback? onReverseComplete;


  @override
  List<Vector2> get snapRegions => [];

  @override
  void setScrollOffset(double offset) {}

  void triggerLightningEffect() {
    cloudBackground.triggerLightningEffect();
  }

  @override
  void prepareGhostRender() {
    _resetVisuals();
    cloudBackground.opacity = 0.02;
    trailComponent.opacity = 0.02;
    titleComponent.opacity = 0.02;
  }

  @override
  Future<void> warmUp() async {
    cloudBackground.warmUp();
    await titleComponent.warmUp();
  }

  @override
  Future<void> finalizeGhostRender() async {
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    titleComponent.opacity = 0.0;
    whiteOverlay.opacity = 0.0;
  }

  void preloadReflection() {
    if (!_orchestratorInitialized) return;
    orchestrator.reflection.registerTarget(titleComponent);
    for (final card in trailComponent.cards) {
      orchestrator.reflection.registerTarget(card);
    }
    final wasPaused = orchestrator.reflection.paused;
    orchestrator.reflection.paused = false;
    orchestrator.reflection.updateReflectionTexture();
    orchestrator.reflection.paused = wasPaused;
    _reflectionCaptured = true;
  }

  @override
  Future<void> enter(ScrollSystem scrollSystem) async {
    _isActive = true;
    _entranceDone = false;
    _ambientLightningTimer = 0.0;
    _animTime = 0.0;
    _nextLightningAt = _rng.nextDouble() * 4.0 + 4.0;

    orchestrator.reflection.paused = true;

    scrollSystem.resetScroll(0.0);
    scrollSystem.setBounds(0.0, 0.0);
    scrollSystem.setSnapRegions([]);

    playEntrySound();

    // 1. Overlay Fade out
    whiteOverlay.opacity = 1.0;
    whiteOverlay.add(OpacityEffect.to(0.0, EffectController(duration: 0.6)));

    // 2. Background Entry
    cloudBackground.opacity = 0.0;
    cloudBackground.scale = Vector2.all(ContactSectionLayout.backgroundOverscan);
    cloudBackground.position = Vector2(-(screenSize.x * ContactSectionLayout.backgroundOverscanMargin), 0.0);
    cloudBackground.setWaterLevel(screenSize.y * ContactSectionLayout.waterLevelRatio);

    cloudBackground.add(OpacityEffect.to(1.0, EffectController(duration: 0.8, curve: Curves.easeOutCubic)));
    cloudBackground.add(MoveEffect.to(
        Vector2(-(screenSize.x * ContactSectionLayout.backgroundOverscanMargin), -ContactSectionLayout.backgroundYShift),
        EffectController(duration: 0.8, curve: Curves.easeOutCubic)
    ));
    cloudBackground.add(CustomFloatEffect(0.0, 0.5, (val) {
      cloudBackground.setScrollProgress(val);
    }, EffectController(duration: 0.8, curve: Curves.easeOutCubic)));

    // 3. Title Animation
    titleComponent.opacity = 0.0;
    titleComponent.showReflection = true;
    titleComponent.waterLineY = screenSize.y * ContactSectionLayout.waterLineYRatio;

    final startY = screenSize.y * ContactSectionLayout.titleStartYRatio;
    final endY = screenSize.y * ContactSectionLayout.titleEndYRatio;
    titleComponent.position = Vector2(screenSize.x / 2, startY);
    titleComponent.scale = Vector2.all(ContactSectionLayout.titleInitialScale);

    final titleWait = 0.4;
    titleComponent.add(OpacityEffect.to(1.0, EffectController(duration: 0.8, startDelay: titleWait)));
    titleComponent.add(MoveEffect.to(Vector2(screenSize.x / 2, endY), EffectController(duration: 0.8, curve: Curves.elasticOut, startDelay: titleWait)));

    // Scale sequence (overshoot then settle)
    final overshootDur = 0.8 * ContactSectionLayout.titleOvershootThreshold;
    final settleDur = 0.8 * (1.0 - ContactSectionLayout.titleOvershootThreshold);
    titleComponent.add(SequenceEffect([
      ScaleEffect.to(Vector2.all(ContactSectionLayout.titleOvershootScale), EffectController(duration: overshootDur, startDelay: titleWait)),
      ScaleEffect.to(Vector2.all(ContactSectionLayout.titleSettleScale), EffectController(duration: settleDur)),
    ]));

    // 4. Trail and Cards Animation
    trailComponent.opacity = 0.0;
    trailComponent.position = Vector2(0, ContactSectionLayout.trailInitialY);
    trailComponent.scale = Vector2.all(ContactSectionLayout.trailInitialScale);

    final trailWait = 0.6;
    trailComponent.add(OpacityEffect.to(1.0, EffectController(duration: 1.0, curve: Curves.easeOutCubic, startDelay: trailWait)));
    trailComponent.add(MoveEffect.to(Vector2.zero(), EffectController(duration: 1.0, curve: Curves.easeOutCubic, startDelay: trailWait)));
    trailComponent.add(ScaleEffect.to(
        Vector2.all(ContactSectionLayout.trailInitialScale + ContactSectionLayout.trailScaleRange),
        EffectController(duration: 1.0, curve: Curves.easeOutCubic, startDelay: trailWait)
    ));
    trailComponent.add(CustomFloatEffect(0.0, 2700.0, (val) {
      trailComponent.setTargetScroll(val);
      trailComponent.updateTrailAnimation(val);
    }, EffectController(duration: 1.0, curve: Curves.easeOutCubic, startDelay: trailWait)));

    // 5. Buttons + Logo fade in
    final btnWait = 1.4;
    final btnDur = 0.6;

    backButton.opacity = 0.0;
    backButton.position = Vector2(80.0, screenSize.y - 50.0);
    backButton.add(OpacityEffect.to(1.0, EffectController(duration: btnDur, startDelay: btnWait)));

    logoComponent.priority = 50;
    logoComponent.position = Vector2(50.0, 50.0);
    logoComponent.scale = Vector2.zero();
    logoComponent.add(ScaleEffect.to(Vector2.all(0.15), EffectController(duration: btnDur, startDelay: btnWait)));

    homeButton.opacity = 0.0;
    homeButton.position = Vector2(screenSize.x - 160.0, screenSize.y - 50.0);
    homeButton.add(OpacityEffect.to(1.0, EffectController(duration: btnDur, startDelay: btnWait)));

    audioToggle.opacity = 0.0;
    audioToggle.position = Vector2(screenSize.x - 50.0, screenSize.y - 50.0);
    audioToggle.add(OpacityEffect.to(1.0, EffectController(duration: btnDur, startDelay: btnWait)));

    // 6. Registration of Reflection and completion flags
    add(TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () {
          if (_orchestratorInitialized) {
            orchestrator.reflection.registerTarget(titleComponent);
            for (final card in trailComponent.cards) {
              orchestrator.reflection.registerTarget(card);
            }
          }
        }
    ));

    add(TimerComponent(
        period: _entranceDuration,
        removeOnFinish: true,
        onTick: () {
          if (orchestrator.reflection.paused) {
            orchestrator.reflection.paused = false;
            if (!_reflectionCaptured) {
              _reflectionCaptured = true;
              orchestrator.reflection.updateReflectionTexture();
            }
          }
          // Release the breathe-animation gate — all entrance Effects have
          // either completed or are past the point where they'd fight with
          // per-frame scale writes from update().
          _entranceDone = true;
        }
    ));
  }

  @override
  Future<void> enterReverse(ScrollSystem scrollSystem) async {
    await enter(scrollSystem);
  }

  @override
  Future<void> exit() async {
    _isActive = false;
    _entranceDone = false;

    // Cancel any entrance Effects still in flight. Without this, an
    // OpacityEffect.to(1.0) queued in enter() keeps ticking after exit()
    // has forced opacity to 0 — next frame the effect overrides us and
    // the component fades back in on a section the user already left.
    // Spam-clicking navigation was stacking effects on each component
    // (the old code never removed them, it just fought via direct writes).
    for (final c in <Component>[
      cloudBackground,
      titleComponent,
      trailComponent,
      backButton,
      whiteOverlay,
      logoComponent,
      homeButton,
      audioToggle,
    ]) {
      for (final e in c.children.whereType<Effect>().toList()) {
        e.removeFromParent();
      }
    }
    // Cancel pending reflection-registration and entrance-complete timers.
    for (final t in children.whereType<TimerComponent>().toList()) {
      t.removeFromParent();
    }

    titleComponent.opacity = 0.0;
    cloudBackground.opacity = 0.0;
    trailComponent.opacity = 0.0;
    backButton.opacity = 0.0;
    whiteOverlay.opacity = 0.0;
    logoComponent.scale = Vector2.zero();
    logoComponent.priority = 10;
    homeButton.opacity = 0.0;
    audioToggle.opacity = 0.0;

    _audioSystem.stopBoldTextAudio();

    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;

    _resetVisuals();
  }

  @override
  void update(double dt) {
    if (!_isActive) return;

    _animTime += dt;

    // --- Ambient Lightning ---
    _ambientLightningTimer += dt;
    if (_ambientLightningTimer >= _nextLightningAt) {
      _ambientLightningTimer = 0.0;
      _nextLightningAt =
          _ambientLightningMinInterval +
              _rng.nextDouble() *
                  (_ambientLightningMaxInterval - _ambientLightningMinInterval);

      orchestrator.lightning.triggerFlash(0.15);
      _audioSystem.playSpatialThunder(0.15);
    }

    // --- Title breathe animation ---
    // Only once the entrance ScaleEffect has landed. Before that, the effect
    // owns scale and the breathe would either fight it (if child-update order
    // changes) or do visually nothing (current order) — either way, wasted
    // per-frame writes to a hot Flame property.
    if (_entranceDone) {
      final breathe = math.sin(_animTime * ContactSectionLayout.breatheFrequency) * ContactSectionLayout.breatheAmplitude;
      final baseScale = ContactSectionLayout.titleSettleScale;
      titleComponent.scale = Vector2.all(baseScale + baseScale * breathe);
    }
  }

  @override
  void onResize(Vector2 newSize) {
    screenSize = newSize;
    if (titleComponent.isLoaded && titleComponent.opacity == 0.0) {
      titleComponent.position = Vector2(
        screenSize.x / 2,
        screenSize.y * ContactSectionLayout.titleStartYRatio,
      );
    }
  }

  @override
  ScrollResult handleScroll(double delta) {
    return ScrollConsumed(0.0);
  }

  void _resetVisuals() {
    titleComponent.opacity = 0.0;
    titleComponent.scale = Vector2.all(ContactSectionLayout.titleInitialScale);
    titleComponent.position = Vector2(
      screenSize.x / 2,
      screenSize.y * ContactSectionLayout.titleStartYRatio,
    );
    titleComponent.showReflection = false;

    trailComponent.opacity = 0.0;
    trailComponent.setTargetScroll(0.0);
    trailComponent.updateTrailAnimation(0.0);

    backButton.opacity = 0.0;
    logoComponent.scale = Vector2.zero();
    homeButton.opacity = 0.0;
    audioToggle.opacity = 0.0;
  }

  void navigateBackToReact() {
    if (!_isActive) return;
    _isActive = false;

    if (kIsWeb) {
      try {
        final msg = <String, String>{'type': 'flutter-handoff'}.jsify();
        web.window.parent?.postMessage(msg, web.window.origin.toJS);
        assert(() {
          debugPrint('[Flutter Contact] postMessage sent: goto-react');
          return true;
        }());
      } catch (e) {
        // Dev-only log. In release builds, assert expressions are stripped
        // so this debugPrint doesn't ship. Previously gated only by kIsWeb
        // (true in both debug and release) which leaked console noise.
        assert(() {
          debugPrint('[Flutter Contact] postMessage error: $e');
          return true;
        }());
      }
    }
  }

  @override
  void dispose() {
    orchestrator.reflection.clearTargets();
    orchestrator.holdProgress = 0.0;
  }
}
