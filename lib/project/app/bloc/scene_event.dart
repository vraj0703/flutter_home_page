part of 'scene_bloc.dart';

@freezed
class SceneEvent with _$SceneEvent {
  const factory SceneEvent.initialize() = Initialize;

  const factory SceneEvent.closeCurtain() = CloseCurtain;

  const factory SceneEvent.tapDown(TapDownEvent tapDownEvent) = TapDown;

  const factory SceneEvent.loadTitle() = LoadTitle;

  const factory SceneEvent.titleLoaded() = TitleLoaded;

  const factory SceneEvent.gameReady() = GameReady;

  const factory SceneEvent.onScroll() = OnScroll;

  const factory SceneEvent.onScrollSequence(double delta) = OnScrollSequence;
}
