# Codebase Knowledge & Architecture Summary

## Overview

The `flutter_home_page` is a high-performance interactive portfolio website built using **Flutter** and the **Flame Game Engine**. It leverages a unique "Linked Sequence" architecture where the user interface is a continuous, scroll-driven game scene rather than a traditional web page.

## Key Architectural Patterns

### 1. The flame_scene Entry Point

- **Dependency Injection**: Uses `BlocProvider` to inject `SceneBloc` at the root.
- **Layering**:
  - **Bottom**: `GameWidget` (Flame Engine) - Renders the heavy visuals.
  - **Middle**: `HomeOverlay` - Interactive Flutter widgets (Menu, UI).
  - **Top**: `StatefulScene` overlays - Curtain animations, Loading text.

### 2. Scroll-Driven Game Loop (`MyGame`)

- **Decoupling**: `MyGame` does not move components directly. It feeds `scrollDelta` into the `ScrollSystem`.
- **System**:
  - `ScrollSystem`: Maintains global scroll physics (inertia, snapping).
  - `ScrollOrchestrator`: Listens to `ScrollSystem` and applies `ScrollEffects` (Parallax, Opacity, Move) to registered components.
  - **Zero Math**: Components are "dumb" and only render; they don't calculate their own position based on scroll.

### 3. Linked Sequence Architecture

The content is divided into autonomous `GameSection`s managed by `SequenceRunner`.

- **GameSection Interface**:
  - `warmUp()`: Prepares resources.
  - `enter()`: Becomes active.
  - `handleScroll()`: Consumes scroll or returns `Overflow`/`Underflow` to switch sections.
  - `exit()`: Cleans up.
- **Current Sections**:
  1. **BoldTextSection**: "Crafting Clarity" sequence.
  2. **PhilosophySection**: Peeling card stack mechanism.
  3. **ExperienceSection**: Orbital/Circular selection interface.

### 4. Component Management

- **Factory Pattern**: `GameComponentFactory` handles all instantiation and dependency injection.
- **Component Record**: `GameComponents` is a typed record passing all references, avoiding global singletons.

## Current State & Challenges

- **State Complexity**: The app currently uses a mix of explicit Bloc states (`Logo`, `Title`, `Philosophy`, `Experience`) and the `SequenceRunner`. The documentation (`state_usage_analysis.md`) suggests a migration to a single `Active` state where `SequenceRunner` manages the sub-state, to simplify the logic.
- **Performance**: Heavy usage of shaders and partial repaints.
- **Scalability**: Adding new sections is streamlined via the `GameSection` interface, but requires strict adherence to the "Exit/Cleanup" rules to avoid visual leaks.

## Documentation Status

The `documentations` folder contains detailed breakdowns:

- `architecture_overview.md`: High-level mental model.
- `project_architecture_guide.md`: Developer guide for adding components/sections.
- `flow_chart.md`: Sequence diagrams of the initialization and loop.
- `state_usage_analysis.md`: Analysis of the current state machine and migration plan.
