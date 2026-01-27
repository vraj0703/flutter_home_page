part of 'scene_bloc.dart';

@freezed
class SceneState with _$SceneState {
  const factory SceneState.loading({
    @Default(false) bool isSvgReady,
    @Default(false) bool isGameReady,
  }) = Loading;

  const factory SceneState.logo() = Logo;

  const factory SceneState.logoOverlayRemoving() = LogoOverlayRemoving;

  const factory SceneState.titleLoading() = TitleLoading;

  const factory SceneState.title() = Title;

  const factory SceneState.active({@Default(1.0) double uiOpacity}) = Active;

  // Deprecated States (Kept temporarily if needed for immediate build fix, but usually safer to remove)
  // Logic is now in GameSections
}
