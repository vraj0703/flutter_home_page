import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/game_section.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_system.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_effects/scroll_effect.dart';
import 'package:flutter_home_page/project/app/utils/logger_util.dart';

/// Orchestrates the execution of [GameSection]s in a linear sequence.
///
/// Replaces complex Bloc state logic with a simple "Run Until Done" pattern.
class SequenceRunner implements ScrollObserver {
  final ScrollSystem scrollSystem;
  List<GameSection> _sections = [];
  int _currentIndex = 0;
  bool _isActive = false;
  bool _isTransitioning = false;
  final Map<PositionComponent, List<ScrollEffect>> _bindings = {};

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

  /// Performs the ghost-render → warmUp → finalize cycle for a section.
  ///
  /// The short delay between warmUp and finalizeGhostRender gives the GPU
  /// pipeline one frame to compile any shaders triggered during warmUp.
  /// These delays are **awaited** (not fire-and-forget), so they block the
  /// calling async method and cannot outlive the caller.
  Future<void> _warmUpSectionPipeline(
    GameSection section, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    section.prepareGhostRender();
    await section.warmUp();
    await Future.delayed(delay);
    await section.finalizeGhostRender();
  }

  void _warmUpNextSection(int callingIndex) async {
    if (callingIndex != _currentIndex) return;
    if (callingIndex < _sections.length - 1) {
      await _warmUpSectionPipeline(
        _sections[callingIndex + 1],
        delay: const Duration(milliseconds: 300),
      );
    }
  }

  /// Proactively warms up all sections in the sequence.
  /// Should be called during game initialization to front-load compiled shaders and assets.
  /// [onProgress] reports 0.0–1.0 as each section completes.
  Future<void> warmUpAll({void Function(double)? onProgress}) async {
    for (int i = 0; i < _sections.length; i++) {
      await _warmUpSectionPipeline(
        _sections[i],
        delay: const Duration(milliseconds: 300),
      );
      onProgress?.call((i + 1) / _sections.length);
    }
  }

  /// Starts the sequence. Usually triggered by the first user interaction.
  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;
    if (_sections.isNotEmpty) {
      scrollSystem.setSnapRegions(_sections[_currentIndex].snapRegions);
      await _warmUpSectionPipeline(_sections[_currentIndex]);
      await _sections[_currentIndex].enter(scrollSystem);
    }
  }

  @override
  void onScroll(double scrollOffset) {
    if (!_isActive || _sections.isEmpty) return;
    _sections[_currentIndex].setScrollOffset(scrollOffset);

    // Apply bindings
    _bindings.forEach((component, effects) {
      for (final effect in effects) {
        effect.apply(component, scrollOffset);
      }
    });
  }

  /// Bind a component to a single effect (Absorbed from ScrollOrchestrator)
  void addBinding(PositionComponent component, ScrollEffect effect) {
    if (!_bindings.containsKey(component)) {
      _bindings[component] = [];
    }
    _bindings[component]!.add(effect);
  }

  /// Remove all effects for a component.
  void removeBinding(PositionComponent component) {
    _bindings.remove(component);
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
    // Prevent double triggers and structural transitions
    if (_isTransitioning || callingIndex != _currentIndex) return;

    if (_currentIndex < _sections.length - 1) {
      _isTransitioning = true;
      try {
        // 1. Exit old
        await _sections[_currentIndex].exit();
        scrollSystem.setBounds(null, null);
        scrollSystem.resetScroll(0.0); // Kill momentum immediately

        _currentIndex++;
        LoggerUtil.log(
          'SequenceRunner',
          'Advancing Section: $callingIndex -> $_currentIndex',
        );
        final nextSection = _sections[_currentIndex];

        // 2. Enter new
        await _warmUpSectionPipeline(nextSection);
        await nextSection.enter(scrollSystem);
      } finally {
        _isTransitioning = false;
      }
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
      final current = _sections[_currentIndex];
      scrollSystem.setSnapRegions(current.snapRegions);
      await _warmUpSectionPipeline(current);
      await current.enterReverse(scrollSystem);
    }
  }

  /// Manually advance to the next section.
  /// Useful for buttons or events that trigger a section change before scroll overflow.
  Future<void> advance() async {
    await _advanceSection(_currentIndex);
  }

  /// Manually return to the previous section.
  Future<void> previous() async {
    await _reverseSection(_currentIndex);
  }

  /// Jumps to a specific section index.
  Future<void> jumpToSection(int index) async {
    if (index < 0 || index >= _sections.length || index == _currentIndex) {
      return;
    }

    if (!_isActive) {
      _isActive = true;
    }

    // Exit current
    if (_sections.isNotEmpty) {
      await _sections[_currentIndex].exit();
      scrollSystem.setBounds(null, null);
      scrollSystem.resetScroll(0.0);
    }

    _currentIndex = index;
    final nextSection = _sections[_currentIndex];

    // Enter new
    scrollSystem.setSnapRegions(nextSection.snapRegions);
    await _warmUpSectionPipeline(nextSection);
    await nextSection.enter(scrollSystem);
  }

  Future<void> _reverseSection(int callingIndex) async {
    if (_isTransitioning || callingIndex != _currentIndex) return;

    if (_currentIndex > 0) {
      _isTransitioning = true;
      try {
        // 1. Exit current (which is now 'future')
        await _sections[_currentIndex].exit();
        scrollSystem.setBounds(null, null);
        scrollSystem.resetScroll(0.0); // Kill momentum immediately

        _currentIndex--;
        LoggerUtil.log(
          'SequenceRunner',
          'Reversing Section: $callingIndex -> $_currentIndex',
        );
        final prevSection = _sections[_currentIndex];

        // 2. Re-enter previous
        await prevSection.enterReverse(scrollSystem);
      } finally {
        _isTransitioning = false;
      }
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
