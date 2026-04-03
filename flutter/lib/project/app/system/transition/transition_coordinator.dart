import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/transition_context.dart';

/// Coordinates the seamless transition from contact to Experience section
/// with precise timing of audio, visual effects, and section lifecycle management.
class TransitionCoordinator {
  final TransitionContext game;
  bool _isTransitioning = false;

  TransitionCoordinator(this.game);


  /// Executes the return transition from Experience to contact (Scroll Up)
  Future<void> returnToContact() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    game.blockInput();

    // 1. Switch State back to Active (contact)
    game.queuer.queue(event: const SceneEvent.onScroll());

    // 2. Resume contact Runner in reverse mode
    // SequenceRunner handles the exit of current (Experience) and entry of previous (contact)
    await game.primarySequenceRunner.previous();

    // 3. Unblock
    game.unblockInput();
    _isTransitioning = false;
  }

  /// Triggers camera shake by adding a [_CameraShakeComponent] to the viewport.
  /// Tied to the component tree — auto-cleans up if the viewport is removed.
  // ignore: unused_element — retained for flash-back transition effect
  void _triggerCameraShake({
    required double intensity,
    required double duration,
  }) {
    game.camera.viewport.add(
      _CameraShakeComponent(
        intensity: intensity,
        duration: duration,
        viewfinder: game.camera.viewfinder,
      ),
    );
  }
}

/// Self-removing component that applies decaying random offsets to the camera
/// viewfinder. Lives in the viewport's component tree, so it is automatically
/// disposed if the viewport (or game) is removed — no orphaned timers.
class _CameraShakeComponent extends Component {
  final double intensity;
  final double duration;
  final Viewfinder viewfinder;
  final math.Random _random = math.Random();

  double _elapsed = 0.0;

  _CameraShakeComponent({
    required this.intensity,
    required this.duration,
    required this.viewfinder,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      // Shake complete — reset camera and self-remove
      viewfinder.position.setZero();
      removeFromParent();
      return;
    }

    // Decay intensity linearly over duration
    final progress = _elapsed / duration;
    final currentIntensity = intensity * (1.0 - progress);

    viewfinder.position.setFrom(
      Vector2(
        (_random.nextDouble() - 0.5) * currentIntensity,
        (_random.nextDouble() - 0.5) * currentIntensity,
      ),
    );
  }
}
