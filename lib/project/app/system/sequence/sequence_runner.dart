import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';

/// Orchestrates the execution of [GameSection]s in a linear sequence.
///
/// Replaces complex Bloc state logic with a simple "Run Until Done" pattern.
class SequenceRunner implements ScrollObserver {
  final ScrollSystem scrollSystem;
  List<GameSection> _sections = [];
  int _currentIndex = 0;
  bool _isActive = false;

  SequenceRunner({required this.scrollSystem});

  /// Get currently active section (null if not started)
  GameSection? get currentSection =>
      _isActive && _sections.isNotEmpty ? _sections[_currentIndex] : null;

  /// Access to full list of sections (for lookahead/transition logic)
  List<GameSection> get sections => _sections;

  /// Initializes the runner with the defined chain of sections.
  void init(List<GameSection> sections) {
    _sections = sections;
    _currentIndex = 0;
    _isActive = false;

    // Link callbacks
    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      section.onComplete = () => _advanceSection(i);
      section.onReverseComplete = () => _reverseSection(i);
      section.onWarmUpNextSection = () => _warmUpNextSection(i);
    }
  }

  void _warmUpNextSection(int callingIndex) {
    if (callingIndex != _currentIndex) return;
    if (callingIndex < _sections.length - 1) {
      _sections[callingIndex + 1].warmUp();
    }
  }

  /// Proactively warms up all sections in the sequence.
  /// Should be called during game initialization to front-load compiled shaders and assets.
  Future<void> warmUpAll() async {
    for (final section in _sections) {
      await section.warmUp();
    }
  }

  /// Starts the sequence. Usually triggered by the first user interaction.
  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;
    if (_sections.isNotEmpty) {
      scrollSystem.setSnapRegions(_sections[_currentIndex].snapRegions);
      await _sections[_currentIndex].warmUp();
      await _sections[_currentIndex].enter(scrollSystem);
    }
  }

  @override
  void onScroll(double scrollOffset) {
    if (!_isActive || _sections.isEmpty) return;
    _sections[_currentIndex].setScrollOffset(scrollOffset);
  }

  /// Routes scroll input to the current active section.
  void handleScroll(double delta) {
    if (!_isActive || _sections.isEmpty) return;

    final currentSection = _sections[_currentIndex];
    final result = currentSection.handleScroll(delta);

    // If logic returns explicit overflow (legacy support or rigorous physics),
    // we could handle it here. For now, we rely on the section calling [onComplete].
    if (result is ScrollOverflow) {
      // Ideally, the section should have called onComplete before or during this.
      // However, we can use this as a failsafe or momentum transfer mechanism.
    }
  }

  /// Updates the current section's frame logic.
  void update(double dt) {
    if (!_isActive || _sections.isEmpty) return;
    _sections[_currentIndex].update(dt);
  }

  void onResize(Vector2 newSize) {
    for (var section in _sections) {
      section.onResize(newSize);
    }
  }

  /// Callback triggered when the sequence reaches the end of the last section.
  VoidCallback? onSequenceComplete;

  /// Stops the runner and exits the current section.
  Future<void> stop() async {
    if (!_isActive) return;
    _isActive = false;
    if (_sections.isNotEmpty) {
      await _sections[_currentIndex].exit();
    }
  }

  Future<void> _advanceSection(int callingIndex) async {
    // Prevent double triggers
    if (callingIndex != _currentIndex) return;

    if (_currentIndex < _sections.length - 1) {
      // 1. Exit old
      await _sections[_currentIndex].exit();

      // RE-VERIFY index after async operation to prevent race conditions
      if (_currentIndex != callingIndex) return;

      _currentIndex++;
      final nextSection = _sections[_currentIndex];

      // 2. Enter new
      // Section configures the system itself (reset to 0, snap regions, etc)
      await nextSection.warmUp();
      await nextSection.enter(scrollSystem);

      // Notify UI listener if needed (e.g., via Bloc event)
      // _onSectionChanged(_currentIndex);
    } else {
      // End of game sequence
      if (onSequenceComplete != null) {
        onSequenceComplete!();
      } else {
        // Default behavior: Clamp to max
        final currentSection = _sections[_currentIndex];
        scrollSystem.resetScroll(currentSection.maxScrollExtent);
      }
    }
  }

  /// Callback triggered when the sequence tries to reverse past the first section.
  VoidCallback? onSequenceReverse;

  /// Resumes the runner in reverse, starting at the end of the current (last) section.
  Future<void> resumeReverse() async {
    if (_isActive) return;
    _isActive = true;
    _currentIndex = _sections.length - 1;
    if (_sections.isNotEmpty) {
      scrollSystem.setSnapRegions(_sections[_currentIndex].snapRegions);
      await _sections[_currentIndex].warmUp();
      await _sections[_currentIndex].enterReverse(scrollSystem);
    }
  }

  Future<void> _reverseSection(int callingIndex) async {
    if (callingIndex != _currentIndex) return;

    if (_currentIndex > 0) {
      // 1. Exit current (which is now 'future')
      await _sections[_currentIndex].exit();

      // RE-VERIFY index after async operation
      if (_currentIndex != callingIndex) return;

      _currentIndex--;
      final prevSection = _sections[_currentIndex];

      // 2. Re-enter previous
      // Section configures the system itself (reset to Max, snap regions, etc)
      await prevSection.warmUp();
      await prevSection.enterReverse(scrollSystem);
    } else {
      // Start of game sequence
      if (onSequenceReverse != null) {
        onSequenceReverse!();
      } else {
        // Default behavior: Clamp to 0
        scrollSystem.resetScroll(0.0);
      }
    }
  }
}
