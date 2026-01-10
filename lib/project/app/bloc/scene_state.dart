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

  const factory SceneState.menu({@Default(1.0) double uiOpacity}) = Menu;
}
