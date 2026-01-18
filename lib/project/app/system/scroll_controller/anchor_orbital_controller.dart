import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/config/anchor_config.dart';
import 'package:flutter_home_page/project/app/curves/spring_curve.dart';
import 'package:flutter_home_page/project/app/curves/exponential_ease_out.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/views/components/anchor/anchor_ring_component.dart';

/// State machine controller for the Orbital Anchor Ring.
/// Manages position, scale, color, and animation behavior across scroll sections.
enum AnchorState {
  dormant,
  awakening,
  followingText,
  orbitingPhilosophy,
  dramaticOrbit,
  multiOrbit,
  carouselOrbit,
  pulseGrid,
  zoomOut,
}

class AnchorOrbitalController implements ScrollObserver {
  final AnchorRingComponent component;
  final Vector2 screenSize;
  final Vector2 screenCenter;

  AnchorState _currentState = AnchorState.dormant;
  Vector2 _targetPosition = Vector2.zero();
  double _targetScale = 1.0;

  // Smooth curves for transitions
  static const springCurve = SpringCurve(
    mass: AnchorConfig.springMass,
    stiffness: AnchorConfig.springStiffness,
    damping: AnchorConfig.springDamping,
  );
  static const exponentialEaseOut = ExponentialEaseOut();

  // Orbit animation state
  double _orbitPhase = 0.0;
  double _orbitSpeed = AnchorConfig.rotationSpeedMedium;

  AnchorOrbitalController({
    required this.component,
    required this.screenSize,
  }) : screenCenter = screenSize / 2 {
    // Start at screen center
    _targetPosition = screenCenter.clone();
    component.position = screenCenter.clone();
    component.opacity = AnchorConfig.opacityHidden;
    component.scale = Vector2.all(AnchorConfig.scaleAwakening);
  }

  @override
  void onScroll(double scrollOffset) {
    _updateState(scrollOffset);
    _updateAnimations(scrollOffset);
  }

  void _updateState(double scrollOffset) {
    if (scrollOffset < AnchorConfig.dormantEnd) {
      _currentState = AnchorState.dormant;
    } else if (scrollOffset < AnchorConfig.awakeningEnd) {
      _currentState = AnchorState.awakening;
    } else if (scrollOffset < AnchorConfig.orbitingPhilosophyStart) {
      _currentState = AnchorState.followingText;
    } else if (scrollOffset < AnchorConfig.orbitingPhilosophyEnd) {
      _currentState = AnchorState.orbitingPhilosophy;
    } else if (scrollOffset < AnchorConfig.dramaticOrbitEnd) {
      _currentState = AnchorState.dramaticOrbit;
    } else if (scrollOffset < AnchorConfig.multiOrbitEnd) {
      _currentState = AnchorState.multiOrbit;
    } else if (scrollOffset < AnchorConfig.carouselOrbitEnd) {
      _currentState = AnchorState.carouselOrbit;
    } else if (scrollOffset < AnchorConfig.pulseGridEnd) {
      _currentState = AnchorState.pulseGrid;
    } else if (scrollOffset < AnchorConfig.zoomOutEnd) {
      _currentState = AnchorState.zoomOut;
    }
  }

  void _updateAnimations(double scrollOffset) {
    switch (_currentState) {
      case AnchorState.dormant:
        _animateDormant();
        break;
      case AnchorState.awakening:
        _animateAwakening(scrollOffset);
        break;
      case AnchorState.followingText:
        _animateFollowingText(scrollOffset);
        break;
      case AnchorState.orbitingPhilosophy:
        _animateOrbitingPhilosophy(scrollOffset);
        break;
      case AnchorState.dramaticOrbit:
        _animateDramaticOrbit(scrollOffset);
        break;
      case AnchorState.multiOrbit:
        _animateMultiOrbit(scrollOffset);
        break;
      case AnchorState.carouselOrbit:
        _animateCarouselOrbit(scrollOffset);
        break;
      case AnchorState.pulseGrid:
        _animatePulseGrid(scrollOffset);
        break;
      case AnchorState.zoomOut:
        _animateZoomOut(scrollOffset);
        break;
    }

    // Apply smooth position and scale transitions
    _applyTransitions();
  }

  void _animateDormant() {
    _targetPosition = screenCenter.clone();
    _targetScale = AnchorConfig.scaleAwakening;
    component.opacity = AnchorConfig.opacityHidden;
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
  }

  void _animateAwakening(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.awakeningStart) /
            (AnchorConfig.awakeningEnd - AnchorConfig.awakeningStart))
        .clamp(0.0, 1.0);
    final curvedT = exponentialEaseOut.transform(t);

    // Fade in gently
    component.opacity = AnchorConfig.opacityAwakening * curvedT;

    // Small ring at center
    _targetPosition = screenCenter.clone();
    _targetScale = AnchorConfig.scaleAwakening;

    // Soft white color
    component.setColor(AnchorConfig.colorSoftWhite);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
  }

  void _animateFollowingText(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.followingTextStart) /
            (AnchorConfig.followingTextEnd - AnchorConfig.followingTextStart))
        .clamp(0.0, 1.0);
    final curvedT = exponentialEaseOut.transform(t);

    // Grow slightly
    component.opacity = AnchorConfig.opacityVisible;
    _targetScale = AnchorConfig.scaleFollowing;

    // Follow the bold text (which moves horizontally during drift)
    // Position slightly above and right of center
    final offsetX = math.sin(t * math.pi) * 100; // Subtle horizontal sway
    _targetPosition = screenCenter + Vector2(offsetX, -80);

    component.setColor(AnchorConfig.colorSoftWhite);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
  }

  void _animateOrbitingPhilosophy(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.orbitingPhilosophyStart) /
            (AnchorConfig.orbitingPhilosophyEnd -
                AnchorConfig.orbitingPhilosophyStart))
        .clamp(0.0, 1.0);

    // Circular orbit around center
    _orbitPhase = t * math.pi * 4; // 2 full rotations
    final radius = AnchorConfig.orbitRadiusPhilosophy;
    _targetPosition = screenCenter +
        Vector2(
          math.cos(_orbitPhase) * radius,
          math.sin(_orbitPhase) * radius,
        );

    component.opacity = AnchorConfig.opacityVisible;
    _targetScale = AnchorConfig.scaleOrbiting;

    // Golden color for philosophy
    component.setColor(AnchorConfig.colorGolden);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
  }

  void _animateDramaticOrbit(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.dramaticOrbitStart) /
            (AnchorConfig.dramaticOrbitEnd - AnchorConfig.dramaticOrbitStart))
        .clamp(0.0, 1.0);

    // Fast, large orbit - HERO MOMENT
    _orbitPhase = t * math.pi * 8; // 4 full rotations (fast!)
    final radius = AnchorConfig.orbitRadiusDramatic;
    _targetPosition = screenCenter +
        Vector2(
          math.cos(_orbitPhase) * radius,
          math.sin(_orbitPhase) * radius,
        );

    component.opacity = AnchorConfig.opacityDramatic;
    _targetScale = AnchorConfig.scaleDramatic;

    // Cyan color with particle trail
    component.setColor(AnchorConfig.colorCyan);
    component.setParticlesEnabled(true);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
    component.setGlowIntensity(1.5);
  }

  void _animateMultiOrbit(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.multiOrbitStart) /
            (AnchorConfig.multiOrbitEnd - AnchorConfig.multiOrbitStart))
        .clamp(0.0, 1.0);

    // Enable multi-orbit mode (3-5 rings)
    component.setMultiOrbitMode(true, ringCount: AnchorConfig.multiOrbitCount);

    // Position at center
    _targetPosition = screenCenter.clone();

    component.opacity = AnchorConfig.opacityVisible;
    _targetScale = AnchorConfig.scaleMulti;

    component.setColor(AnchorConfig.colorPurple);
    component.setParticlesEnabled(false);
    component.setRainbowMode(false);
    component.setGlowIntensity(1.0);
  }

  void _animateCarouselOrbit(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.carouselOrbitStart) /
            (AnchorConfig.carouselOrbitEnd - AnchorConfig.carouselOrbitStart))
        .clamp(0.0, 1.0);

    // Gentler circular orbit
    _orbitPhase = t * math.pi * 3; // 1.5 rotations
    final radius = AnchorConfig.orbitRadiusCarousel;
    _targetPosition = screenCenter +
        Vector2(
          math.cos(_orbitPhase) * radius,
          math.sin(_orbitPhase) * radius,
        );

    component.opacity = AnchorConfig.opacityVisible;
    _targetScale = AnchorConfig.scaleCarousel;

    // Warm gold color
    component.setColor(AnchorConfig.colorWarmGold);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
    component.setGlowIntensity(1.0);
  }

  void _animatePulseGrid(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.pulseGridStart) /
            (AnchorConfig.pulseGridEnd - AnchorConfig.pulseGridStart))
        .clamp(0.0, 1.0);

    // Pulsing at center
    final pulse = 1.0 + (0.2 * math.sin(t * math.pi * 10)); // 5 pulses
    _targetScale = AnchorConfig.scalePulse * pulse;

    _targetPosition = screenCenter.clone();

    component.opacity = AnchorConfig.opacityVisible;

    // Matrix green
    component.setColor(AnchorConfig.colorMatrixGreen);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setRainbowMode(false);
    component.setGlowIntensity(1.2);
  }

  void _animateZoomOut(double scrollOffset) {
    final t = ((scrollOffset - AnchorConfig.zoomOutStart) /
            (AnchorConfig.zoomOutEnd - AnchorConfig.zoomOutStart))
        .clamp(0.0, 1.0);
    final curvedT = springCurve.transform(t);

    // Massive scale increase - THE REVEAL
    _targetScale = 1.0 + (curvedT * (AnchorConfig.scaleZoomOutMax - 1.0));

    // Stay at center
    _targetPosition = screenCenter.clone();

    // Fade out as it zooms
    component.opacity = 1.0 - (curvedT * 0.7); // Keep some visibility

    // Rainbow shimmer
    component.setColor(AnchorConfig.colorsRainbow[0]); // Base color
    component.setRainbowMode(true);
    component.setParticlesEnabled(false);
    component.setMultiOrbitMode(false);
    component.setGlowIntensity(2.0);
  }

  void _applyTransitions() {
    // Smooth position interpolation
    final positionDelta = _targetPosition - component.position;
    final positionDistance = positionDelta.length;

    if (positionDistance > 1.0) {
      final lerpFactor =
          (AnchorConfig.positionLerpSpeed * 0.016).clamp(0.0, 1.0);
      component.position += positionDelta * lerpFactor;
    } else {
      component.position = _targetPosition.clone();
    }

    // Smooth scale interpolation
    final scaleDelta = _targetScale - component.scale.x;
    if (scaleDelta.abs() > 0.01) {
      final lerpFactor =
          (AnchorConfig.scaleTransitionSpeed * 0.016).clamp(0.0, 1.0);
      final newScale = component.scale.x + (scaleDelta * lerpFactor);
      component.scale = Vector2.all(newScale);
    } else {
      component.scale = Vector2.all(_targetScale);
    }
  }
}
