import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter_home_page/project/app/config/game_curves.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/system/audio/game_audio_system.dart';
import 'package:flutter_home_page/project/app/system/cursor/game_cursor_system.dart';
import 'package:flutter_home_page/project/app/system/animator/game_logo_animator.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_title.dart';
import 'package:flutter_home_page/project/app/views/components/hero_title/cinematic_secondary_title.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';

/// Manages the intro flow from logo → title → active state.
///
/// Extracted from [MyGame] to reduce its responsibility. Each method
/// corresponds to a state-transition side-effect triggered by the
/// [SceneBloc] listener in [StatefulScene].
class IntroFlowController {
  final LogoOverlayComponent _logoOverlay;
  final CinematicTitleComponent _cinematicTitle;
  final CinematicSecondaryTitleComponent _cinematicSecondaryTitle;
  final BackgroundRunComponent _backgroundRun;
  final GameAudioSystem _audioSystem;
  final GameCursorSystem _cursorSystem;
  final GameLogoAnimator _logoAnimator;
  final Queuer _queuer;
  final FlameGame _game;

  IntroFlowController({
    required LogoOverlayComponent logoOverlay,
    required CinematicTitleComponent cinematicTitle,
    required CinematicSecondaryTitleComponent cinematicSecondaryTitle,
    required BackgroundRunComponent backgroundRun,
    required GameAudioSystem audioSystem,
    required GameCursorSystem cursorSystem,
    required GameLogoAnimator logoAnimator,
    required Queuer queuer,
    required FlameGame game,
  })  : _logoOverlay = logoOverlay,
        _cinematicTitle = cinematicTitle,
        _cinematicSecondaryTitle = cinematicSecondaryTitle,
        _backgroundRun = backgroundRun,
        _audioSystem = audioSystem,
        _cursorSystem = cursorSystem,
        _logoAnimator = logoAnimator,
        _queuer = queuer,
        _game = game;

  /// Shows the bouncing-line overlay on the logo. Called on [SceneState.logo].
  void loadBouncingLines() {
    _logoOverlay.opacity = 1.0;
  }

  /// Fades in the background shader. Called on [SceneState.logoOverlayRemoving].
  void loadTitleBackground() {
    _backgroundRun.add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: 2.0, curve: GameCurves.backgroundFade),
      ),
    );
  }

  /// One-shot: sets the logo animator target for the logo→title shrink.
  /// Called on [SceneState.logoOverlayRemoving].
  void startLogoRemoval() {
    _logoAnimator.setTarget(
      position: GameLayout.logoRemovingTargetVector,
      scale: GameLayout.logoRemovingScale,
    );
  }

  /// Starts the cinematic title entry sequence after a configured delay.
  /// Uses a [TimerComponent] tied to the game tree so it auto-cleans up.
  /// Called on [SceneState.titleLoading].
  void enterTitle() {
    _game.add(
      TimerComponent(
        period: ScrollSequenceConfig.enterTitleDelayDuration.inMilliseconds /
            1000.0,
        removeOnFinish: true,
        onTick: () {
          _audioSystem.playTitleLoaded();
          _cinematicTitle.show(() {
            _cinematicSecondaryTitle.show(
              () => _queuer.queue(event: SceneEvent.titleLoaded()),
            );
          });
        },
      ),
    );
  }

  /// Activates cursor-following parallax on titles. Called on [SceneState.title].
  void activateTitleCursorSystem(Vector2 gameSize) {
    _cursorSystem.activate(gameSize / 2);
  }

  /// Hides the cinematic titles. Called when transitioning away from
  /// Title/BoldText states to prevent visual bleed into later sections.
  void hideTitles() {
    _cinematicTitle.opacity = 0.0;
    _cinematicTitle.hide();
    _cinematicSecondaryTitle.hide();
  }
}
