part of 'scene_bloc.dart';

@freezed
class SceneState with _$SceneState {
  const factory SceneState.loading() = Loading;

  const factory SceneState.logo() = Logo;

  const factory SceneState.logoOverlayRemoving() = LogoOverlayRemoving;

  const factory SceneState.titleLoading() = TitleLoading;

  const factory SceneState.title() = Title;
}
