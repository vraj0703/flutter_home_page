# Architecture Simplification Refactor

## Phase 1: Dead Code Cleanup ⚡

- [x] Remove commented fields from `game_components.dart`
- [x] Remove commented registry calls from `game_component_factory.dart`
- [x] Remove unused `_triggeredSnaps` from `philosophy_section.dart`
- [x] Remove duplicate system update calls from `my_game.dart`
- [x] Strip debug `print()` statements across all files
- [x] `dart analyze` verification

## Phase 2: Kill Builder Pattern (Option B) 🔧

- [x] Read all 10 builder files to capture construction logic
- [x] Inline builder logic into `GameComponentFactory.initializeComponents()`
- [x] Delete 10 builder files + `ComponentRegistry` + `ComponentBuilder` + `ComponentIds`
- [x] `dart analyze` verification

## Phase 3: Eliminate `GameComponents` Record

- [x] Replace all `_gameComponents.X` with `_componentFactory.X` in `my_game.dart`
- [x] Delete `game_components.dart`
- [x] `dart analyze` verification

## Phase 4: Consolidate State Reactions

- [x] Move `logoAnimator.setTarget()` one-shot from `MyGame.update()` to `StatefulScene.listener`
- [x] Add `startLogoRemoval()` method to `MyGame` for clean API boundary
- [x] Slim `MyGame.update()` to per-frame-only logic
- [x] `dart analyze` verification

## Phase 5: Unify Scroll Paths

- [x] Absorb `ScrollOrchestrator` bindings into `SequenceRunner`
- [x] Delete `scroll_orchestrator.dart`
- [x] Update `GameComponentFactory` and `MyGame` references
- [x] `dart analyze` verification (Clean refactor, 0 errors, lingering warnings)

# Bug Fixes 🐞

- [x] **Fix Philosophy Scroll Transition**: User reports scrolling from Title doesn't enter the "bold text" sequence.
  - [x] Investigate `PhilosophySection` scroll logic.
  - [x] Check `SequenceRunner` scroll propagation.
  - [x] Verify `PhilosophyTextComponent` opacity/state updates.

# Design & Motion Polish 🎨

- [x] **Philosophy Trail Physics**: Upgrade from simple lerp to Spring Simulation for card scrolling.
- [x] **Visual Accent**: Add a subtle accent color (Neon Cyan/Amber) to the "Next" button.
- [x] **Shader Optimization**: Ensure `rain_shader` is paused/hidden when not active to save battery.
- [x] **Typography**: Check `BoldTextComponent` max-width for readability on large screens.

# Bug Fixes 🐛

- [x] **Philosophy Ghosting**: Ensure Philosophy components are fully hidden and paused when transitioning to Experience section.
- [x] **Audio Leak**: Reset thunder simulation state (`holdProgress`) on Philosophy exit to stop persistent sounds.

- [x] **Experience Physics**
  - [x] Create `ExperiencePageController` (porting `Reference Physics`)
  - [x] Wire `ExperiencePageController` to `ExperienceSection`
  - [x] Integrate `ExperienceContentComponent` with new controller
  - [x] Ensure smooth scroll handoff from `PhilosophySection`

- [x] **Bug Fixes (Post-Release)**
  - [x] **Reverse Scroll Title Visibility**: Ensure "Vishal Raj" title reappears when scrolling back to top.
  - [x] **Transition Lag**: Fix lag during first transition from Bold Text to Philosophy.
  - [x] **Performance**: Implemented **Progressive Warmup Strategy** (Mobile Flutter Engineer):
    - [x] Moved `warmUp` to run concurrently with the Splash Screen (non-blocking `onLoad`).
    - [x] Implemented "Ghost Rendering": `PhilosophySection` components render at `0.02` opacity during loading to force true GPU upload.
    - [x] Gated `gameReady` event to ensure the splash screen only dismisses after 300ms of true warmup.
