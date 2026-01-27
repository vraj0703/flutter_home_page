import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';

/// Orchestrates the execution of [GameSection]s in a linear sequence.
///
/// Replaces complex Bloc state logic with a simple "Run Until Done" pattern.
class SequenceRunner {
  List<GameSection> _sections = [];
  int _currentIndex = 0;
  bool _isActive = false;

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
    }
  }

  /// Starts the sequence. Usually triggered by the first user interaction.
  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;
    if (_sections.isNotEmpty) {
      await _sections[_currentIndex].warmUp();
      await _sections[_currentIndex].enter();
    }
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

  Future<void> _advanceSection(int callingIndex) async {
    // Prevent double triggers
    if (callingIndex != _currentIndex) return;

    if (_currentIndex < _sections.length - 1) {
      // 1. Exit old
      await _sections[_currentIndex].exit();

      _currentIndex++;
      final nextSection = _sections[_currentIndex];

      // 2. Enter new
      await nextSection.warmUp();
      await nextSection.enter();

      // Notify UI listener if needed (e.g., via Bloc event)
      // _onSectionChanged(_currentIndex);
    } else {
      // End of game sequence
    }
  }

  Future<void> _reverseSection(int callingIndex) async {
    if (callingIndex != _currentIndex) return;

    if (_currentIndex > 0) {
      // 1. Exit current (which is now 'future')
      await _sections[_currentIndex].exit();

      _currentIndex--;
      final prevSection = _sections[_currentIndex];

      // 2. Re-enter previous
      await prevSection.warmUp();
      // We might need a specific enterReverse() or just enter() with config
      await prevSection.enter();
    }
  }
}
