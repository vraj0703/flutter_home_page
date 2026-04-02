# Project Architecture & Contribution Guide

This document serves as a comprehensive guide for AI agents and developers working on the `flutter_home_page` project. It outlines the core architecture, the "Linked Sequence" pattern, and step-by-step instructions for extending the application.

## 1. High-Level Architecture

The project is a **Flutter Flame** game that functions as a scroll-driven interactive portfolio. It relies on a custom "Linked Sequence" architecture where disparate "Sections" are stitched together to form a continuous user experience.

### Core Systems

- **`MyGame` (`lib/project/app/views/my_game.dart`)**: The entry point and composition root. It initializes systems, registers components, and orchestrates the global state.
- **`SceneBloc` (`lib/project/app/bloc/`)**: Manages high-level application state (`loading`, `logo`, `intro`, `active`). Use this for global UI changes (like showing/hiding the HUD).
- **`SequenceRunner` (`lib/project/app/system/sequence/sequence_runner.dart`)**: The heart of the implementation. It maintains the list of `GameSection`s and routes scroll input to the `_currentIndex`.
- **`GameComponentFactory` (`lib/project/app/system/registration/game_component_factory.dart`)**: A central factory for instantiating all visual components (`PositionComponent`s). It handles dependency injection and lifecycle initialization.
- **`GameComponents` (`lib/project/app/models/game_components.dart`)**: A data class (record-like) that holds references to all instantiated components, making them easy to pass around.

---

## 2. Key Concepts

### The "GameSection" Interface

Every major distinct scroll area (e.g., Bold Text, Philosophy, Work Experience) is a `GameSection`.

**Contract (`lib/project/app/interfaces/game_section.dart`):**

- **`warmUp()`**: Called before the section becomes active (e.g., when the previous section is finishing). Use this to reset positions or prepare opacity (usually `0.0`).
- **`enter()`**: Called when the section becomes the *active* recipient of input. Fade things in here.
- **`handleScroll(double delta)`**: The main loop. Update your internal progress.
  - Return `ScrollConsumed`: You handled it.
  - Return `ScrollOverflow`: User scrolled past your end. `SequenceRunner` will switch to **Next**.
  - Return `ScrollUnderflow`: User scrolled past your start (backwards). `SequenceRunner` will switch to **Previous**.
- **`exit()`**: Called when the section is no longer active. **CRITICAL**: You must hide/reset your components here to prevent "leaks" (ghost components visible in other sections).

---

## 3. Workflow: Adding a New Component

To add a new visual element (e.g., a "Floating Astronaut"):

### Step 1: Create the Component Class

Create `lib/project/app/views/components/astronaut/floating_astronaut_component.dart`.

```dart
class FloatingAstronautComponent extends PositionComponent with HasGameReference {
  // Implement onLoad, update, render
}
```

### Step 2: Register in Model

Update `lib/project/app/models/game_components.dart`:

```dart
class GameComponents {
  // ... existing
  final FloatingAstronautComponent astronaut; // Add this

  GameComponents({
    // ... existing
    required this.astronaut, // Add this
  });
}
```

### Step 3: Instantiate in Factory

Update `lib/project/app/system/registration/game_component_factory.dart`:

1. Add a generic getter or public final field.
2. Initialize it in `initializeComponents`.

```dart
late final FloatingAstronautComponent _astronaut;
FloatingAstronautComponent get astronaut => _astronaut;

Future<void> initializeComponents() async {
  // ...
  _astronaut = FloatingAstronautComponent();
  // ...
  _allComponents.add(_astronaut);
}
```

### Step 4: Inject in MyGame

Update `lib/project/app/views/my_game.dart`:
In `onLoad()`, when creating `_gameComponents`:

dart
_gameComponents = GameComponents(
  // ...
  astronaut: _componentFactory.astronaut,
);


Now it is available to be passed to any section!

---

## 4. Workflow: Adding a New Section

To add a new scroll section (e.g., "SpaceSection"):

### Step 1: Create the Section Class

Create `lib/project/app/sections/space_section.dart`.
Implement `GameSection`.

```dart
class SpaceSection implements GameSection {
  final FloatingAstronautComponent astronaut;
  Vector2 screenSize;
  
  double _scrollProgress = 0.0;
  static const double _maxHeight = 2000.0;

  SpaceSection({required this.astronaut, required this.screenSize});

  @override 
  VoidCallback? onComplete;
  @override 
  VoidCallback? onReverseComplete;

  @override
  Future<void> warmUp() async {
     astronaut.opacity = 0.0; // Prepare invisible
  }

  @override
  Future<void> enter() async {
     // Fade in
     astronaut.add(OpacityEffect.to(1.0, EffectController(duration: 0.5)));
  }

  @override
  Future<void> exit() async {
     // Clean up!
     astronaut.opacity = 0.0; 
  }

  @override
  ScrollResult handleScroll(double delta) {
    double newScroll = _scrollProgress + delta;
    
    if (newScroll > _maxHeight) {
       onComplete?.call();
       return ScrollOverflow(newScroll - _maxHeight);
    }
    if (newScroll < 0) {
       onReverseComplete?.call();
       return ScrollUnderflow(newScroll);
    }
    
    _scrollProgress = newScroll;
    _updateVisuals();
    return ScrollConsumed(newScroll);
  }
  
  void _updateVisuals() {
    // Move astronaut based on _scrollProgress
  }
  
  @override 
  void onResize(Vector2 newSize) => screenSize = newSize;
  
  @override
  void update(double dt) {}
}
```

### Step 2: Wire into Sequence

Update `lib/project/app/views/my_game.dart` inside `_initSequence()`:

```dart
void _initSequence() {
  // ... existing sections
  
  final spaceSection = SpaceSection(
    astronaut: _gameComponents.astronaut,
    screenSize: size,
  );
  
  // Add to the list!
  _sequenceRunner.init([boldSection, philSection, spaceSection]);
}
```

---

## 5. Architectural Rules & Best Practices

1. **Zero Math Dependencies**: `MyGame` should not know about internal scroll calculations. It just passes the `delta` to the `SequenceRunner`. The Section handles the math.
2. **Explicit Exit Cleanup**: Always assume your components will persist in the scene tree. You **MUST** hide them in `exit()` or `warmUp()` of the *neighboring* section.
3. **Use specific configs**: Put magic numbers in `lib/project/app/config/scroll_sequence_config.dart`.
4. **Components are Dumb**: Components should generally just render. Move logic to the `GameSection` or a dedicated `Controller` if complex.

## 6. Directory Structure Reference

- `sections/`: Contains `GameSection` implementations (logic).
- `views/components/`: Contains `Flame` components (rendering).
- `system/`:
  - `sequence/`: The runner logic.
  - `registration/`: The factory.
  - `scroll/`: Low-level scroll input handling.
