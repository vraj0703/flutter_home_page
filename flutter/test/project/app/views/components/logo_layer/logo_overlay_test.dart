import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/views/components/logo_layer/logo_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

/// RAJ-82: logo overlay clean-up.
///
/// 1. Vertical bouncy lines removed — only the two horizontal lines remain.
/// 2. The TAP text + horizontal lines anchor to the bottom of the screen with
///    [GameLayout.logoOverlayBottomMargin] padding, instead of the centre.
class _FakeStateProvider implements StateProvider {
  @override
  SceneState sceneState() => const SceneState.logo();

  @override
  double revealProgress() => 1.0;

  @override
  void updateRevealProgress(double progress) {}

  @override
  Stream<SceneState> get stream => const Stream.empty();

  @override
  void updateUIOpacity(double opacity) {}
}

class _NoopQueuer implements Queuer {
  @override
  queue({required SceneEvent event}) {}
}

void main() {
  group('LogoOverlayComponent (RAJ-82)', () {
    test('onGameResize anchors the component to the bottom with padding', () {
      final component = LogoOverlayComponent(
        stateProvider: _FakeStateProvider(),
        queuer: _NoopQueuer(),
      );
      final gameSize = Vector2(1920, 1080);

      component.onGameResize(gameSize);

      expect(component.position.x, equals(gameSize.x / 2));
      expect(
        component.position.y,
        equals(gameSize.y - GameLayout.logoOverlayBottomMargin),
      );
    });

    test(
      'onGameResize stays bottom-anchored when the viewport changes',
      () {
        final component = LogoOverlayComponent(
          stateProvider: _FakeStateProvider(),
          queuer: _NoopQueuer(),
        );

        component.onGameResize(Vector2(800, 600));
        expect(component.position.y,
            equals(600 - GameLayout.logoOverlayBottomMargin));

        component.onGameResize(Vector2(1280, 720));
        expect(component.position.y,
            equals(720 - GameLayout.logoOverlayBottomMargin));
      },
    );
  });
}
