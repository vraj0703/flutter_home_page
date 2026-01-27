import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';

/// Defines the contract for a distinct section of the game experience.
///
/// Each section (e.g., BoldText, Philosophy) acts as a self-contained unit
/// that handles its own entrance, interaction, and exit logic.
abstract class GameSection {
  /// Callback triggered when the section completes its forward sequence (e.g., exit finished).
  VoidCallback? onComplete;

  /// Callback triggered when the section completes its reverse sequence (scrolling back up).
  VoidCallback? onReverseComplete;

  /// Pre-loads resources, compiles shaders, or performs heavy calculations
  /// before the section becomes visible.
  Future<void> warmUp();

  /// Starts the entrance animation logic.
  /// The section should become visible and interactive after this.
  Future<void> enter();

  /// Starts the exit animation logic.
  /// The section should cleanup and hide itself after this.
  Future<void> exit();

  /// Handle screen resize.
  void onResize(Vector2 newSize);

  /// Per-frame update logic.
  /// [dt] is the delta time in seconds.
  void update(double dt);

  /// Handles scroll input directed to this section.
  ///
  /// Returns [ScrollResult] to indicate if the scroll was consumed,
  /// or if it overflowed/underflowed to the next/previous section.
  ScrollResult handleScroll(double delta);
}
