import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';

/// Defines the contract for a distinct section of the game experience.
///
/// Each section (e.g., BoldText, Philosophy) acts as a self-contained unit
/// that handles its own entrance, interaction, and exit logic.
abstract class GameSection {
  /// Callback triggered when the section completes its forward sequence (e.g., exit finished).
  VoidCallback? onComplete;

  /// Callback triggered when the section completes its reverse sequence (scrolling back up).
  VoidCallback? onReverseComplete;

  /// Callback triggered when the section is nearing its end, allowing the next section
  /// to pre-warm resources (e.g. compile shaders) before becoming fully visible.
  VoidCallback? onWarmUpNextSection;

  /// Pre-loads resources, compiles shaders, or performs heavy calculations
  /// before the section becomes visible.
  Future<void> warmUp();

  /// Starts the entrance animation logic (forward).
  /// The section configures the [scrollSystem] (e.g. reset to 0, set snap regions)
  /// and becomes visible.
  Future<void> enter(ScrollSystem scrollSystem);

  /// Starts the entrance animation logic (reverse).
  /// The section configures the [scrollSystem] (e.g. set to max extent, set snap regions)
  /// and becomes visible.
  Future<void> enterReverse(ScrollSystem scrollSystem);

  /// Starts the exit animation logic.
  /// The section should cleanup and hide itself after this.
  Future<void> exit();

  /// Handle screen resize.
  void onResize(Vector2 newSize);

  /// Per-frame update logic.
  /// [dt] is the delta time in seconds.
  void update(double dt);

  /// The snap regions for this section.
  /// Each Vector2 represents a region: x = start, y = end.
  /// If the scroll offset falls within this range, the system should snap to the end (y).
  List<Vector2> get snapRegions;

  /// The maximum scroll extent for this section.
  /// Used for clamping logic at the end of the sequence or for reverse entry.
  double get maxScrollExtent;

  /// Handles manual scroll offset updates (e.g. from ScrollSystem physics).
  void setScrollOffset(double offset);

  /// Handles scroll input directed to this section.
  ///
  /// Returns [ScrollResult] to indicate if the scroll was consumed,
  /// or if it overflowed/underflowed to the next/previous section.
  ScrollResult handleScroll(double delta);
}
