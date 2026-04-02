# Project Directory Structure Map

This document maps out the `lib/` directory structure of the Flutter Flame interactive portfolio. The project follows a highly organized, decoupled architecture dividing logic, state, and presentation.

## `lib/project/app/`

The core application code is categorized into distinct domains:

### 1. `/bloc` (State Management)
Contains the `SceneBloc` and `SceneState` definitions using `flutter_bloc` and `freezed`.
- **Purpose**: Manages the high-level macro states (e.g., `loading`, `logo`, `title`, `active`) and bridges the gap between Flutter UI overlays and Flame Game logic.

### 2. `/config` (Constants & Configuration)
- **Purpose**: Centralized files for magic numbers, layout dimensions (`game_layout.dart`), text strings (`game_strings.dart`), and global theming (`game_styles.dart`).
- **Data**: Mock data or static data sources (e.g., `game_data.dart`).

### 3. `/curves` (Animation Math)
- **Purpose**: Custom easing equations (Spring, Elastic, Bezier) used to drive the cinematic, physics-based motion throughout the experience.

### 4. `/interfaces` (Contracts)
- **Purpose**: Defines core abstractions to maintain loose coupling.
- **Key File**: `game_section.dart` defines the standard lifecycle (`warmUp`, `enter`, `handleScroll`, `exit`) that all scrollable sections must implement.

### 5. `/models` (Data Structures)
- **Purpose**: Plain Dart records/classes representing data entities (`ExperienceNode`, `PhilosophyCardData`, `ScrollResult`).

### 6. `/sections` (The Sequence Modules)
- **Purpose**: Contains the distinct "Levels" or chapters of the portfolio.
- **Contents**: `bold_text_section.dart`, `philosophy_section.dart`, `experience_section.dart`. These classes do not render directly; they orchestrate the behaviors and scrolling of components defined in `/views`.

### 7. `/system` (Engine Core)
The beating heart of the custom game loop.
- **`/animator`**: Standalone animation orchestrators (e.g., Logo Animator).
- **`/audio`**: Spatial and triggered audio management.
- **`/cursor`**: Tracks mouse input and applies parallax to registered UI elements.
- **`/input`**: Centralized routing for scroll, tap, and hover events.
- **`/scroll`**: The custom physics-based scroll system and effect orchestrator (`parallax.dart`, `opacity.dart`).
- **`/sequence`**: Contains the `SequenceRunner`, which manages the lifecycles of the `GameSection` instances based on scroll progression.
- **`/registration`**: `GameComponentFactory.dart`, the dependency injection hub that instantiates all visual components.

### 8. `/views` (Presentation Layer)
- **`my_game.dart`**: The `FlameGame` instance. Wires up components, systems, and the sequence runner.
- **`/components`**: The actual Flame `PositionComponent` instances (rendering nodes). Grouped by section/feature (e.g., `/bold_text`, `/philosophy`, `/experience`, `/hero_title`).
- **`stateful_scene.dart`**: The Flutter Widget boundary that overlays the Flame canvas (e.g., loading screens, black curtains).

---

## Architectural Flow Summary

1. **Boot**: `main.dart` -> `StatefulScene` -> `MyGame` instantiated.
2. **Setup**: `MyGame` uses `GameComponentFactory` to create all visuals (`/views/components`).
3. **Sequencing**: `MyGame` instantiates implementations of `GameSection` (`/sections`) and passes them to the `SequenceRunner` (`/system/sequence`).
4. **Interaction**: User scrolls -> `GameInputController` -> `SequenceRunner` tracks progress -> Currently active `GameSection` updates its respective visual components.
