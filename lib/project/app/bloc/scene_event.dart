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

  const factory SceneEvent.forceScrollOffset(double offset) = ForceScrollOffset;

  const factory SceneEvent.updateUIOpacity(double opacity) = UpdateUIOpacity;

  const factory SceneEvent.registerSections(List<SectionManager> managers) =
      RegisterSections;

  const factory SceneEvent.nextSection({@Default(0.0) double overflow}) =
      NextSection;

  const factory SceneEvent.previousSection({@Default(0.0) double underflow}) =
      PreviousSection;

  const factory SceneEvent.updateSectionOffset(double offset) =
      UpdateSectionOffset;
}
