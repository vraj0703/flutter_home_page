# SceneState Usage Analysis

This document maps how the current `SceneState` is used across the application. This is critical for ensuring no functionality is lost when we migrate to the single `Active` state.

## 1. StatefulScene (`lib/project/app/views/stateful_scene.dart`)

**Role**: Handles high-level UI transitions (Curtain, Loading Text).

| State | Action |
| :--- | :--- |
| `loading` | Reverses `_revealController` (closes curtain). |
| `logo` | Stops blinking, forwards `_revealController` (opens curtain). |
| `logoOverlayRemoving` | Plays enter sound, loads title background. |
| `titleLoading` | Calls `_game.enterTitle()`. |
| `title` | Plays bouncy arrow sound, activates cursor system. |
| `boldText` | Adds `BoldText` scroll bindings. |
| `philosophy` | Adds `Philosophy` bindings. |

## 2. HomeOverlay (`lib/project/app/views/widgets/home_overlay.dart`)

**Role**: Controls visibility of the "Menu" (Top Right) and "Bouncing Arrow" (Bottom).

| State | Overlay Visibility |
| :--- | :--- |
| `title` | Visible (Opacity 1.0) |
| `boldText` | Visible (Dynamic Opacity from state) |
| `philosophy`+ | Hidden (Opacity 0.0) |
| `orElse` | Hidden (SizedBox.shrink) |

## 3. MyGame (`lib/project/app/views/my_game.dart`)

**Role**: Detailed game logic, cursor behavior, and layout.

### `update(dt)`

Checks state to decide if **Parallax** should be enabled for the cursor.

* `boldText` -> `contact`: Parallax Enabled.
* `title` -> `loading`: Parallax Disabled.

### `onGameResize(size)`

Updates layout targets for the Logo Animator based on state.

* `logo`: Snaps logo to center.
* `boldText` -> `contact`: Updates "Menu Layout" targets (Top Left logo).

### `_handleStateChange` (Internal Map in Listener)

* `logoOverlayRemoving`: Triggers logo animation to top-left.
* `boldText`: **Adds Bindings** for Title Parallax/Fade.

## Migration Strategy

We will replace these distinct states with logic inside `SequenceRunner` or `GameSection`.

* **Curtain/Loading**: Managed by `IntroSection` (or kept in `Loading`/`Intro` state).
* **Menu/Arrow Visibility**: `BoldTextSection` will explicitly tell the UI to show/hide these via a simplified Bloc event (e.g., `UpdateOverlay(opacity)`).
* **Cursor Parallax**: `SequenceRunner` will tell `CursorSystem` to enable parallax when entering the first interactive section.
