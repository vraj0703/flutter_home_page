import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/views/my_game.dart';

/// Manages reflection texture generation for 3D-transformed cards.
/// Captures cards and text into a single texture for water shader distortion.
class ReflectionManager extends Component with HasGameReference<MyGame> {
  Image? reflectionTexture;
  bool _isProcessing = false;

  /// The resolution scale for the reflection (0.5 = 50% of screen size)
  /// Lower values are MUCH faster and look better for blurry water.
  final double _reflectionScale = 0.5;

  /// List of components to render in the reflection
  final List<Component> reflectionTargets = [];

  @override
  void render(Canvas canvas) {
    // This component doesn't draw to the screen itself
  }

  /// Asynchronously updates the reflection texture from registered components.
  /// Called every frame but processes in background to avoid blocking.
  Future<void> updateReflectionTexture() async {
    if (_isProcessing || !game.hasLayout) return;
    _isProcessing = true;

    try {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawColor(const Color(0x00000000), BlendMode.clear);

      canvas.scale(_reflectionScale);

      for (final target in reflectionTargets) {
        if ((target as dynamic).opacity > 0.01) {
          target.renderTree(canvas);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        (game.size.x * _reflectionScale).toInt(),
        (game.size.y * _reflectionScale).toInt(),
      );

      // Thread-safe swap of the texture
      final oldTexture = reflectionTexture;
      reflectionTexture = img;
      oldTexture?.dispose();
    } catch (e) {
      // Silently fail to prevent crashes during texture generation
    } finally {
      _isProcessing = false;
    }
  }

  /// Register a component to be included in the reflection
  void registerTarget(Component component) {
    if (!reflectionTargets.contains(component)) {
      reflectionTargets.add(component);
    }
  }

  /// Unregister a component from reflections
  void unregisterTarget(Component component) {
    reflectionTargets.remove(component);
  }

  /// Clear all registered targets (called on section exit)
  void clearTargets() {
    reflectionTargets.clear();
  }

  @override
  void onRemove() {
    reflectionTexture?.dispose();
    reflectionTargets.clear();
    super.onRemove();
  }
}
