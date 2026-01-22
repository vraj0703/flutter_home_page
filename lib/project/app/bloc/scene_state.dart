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

  const factory SceneState.boldText({
    @Default(1.0) double uiOpacity,
    @Default(0.0) double offset,
  }) = BoldText;

  const factory SceneState.philosophy({@Default(0.0) double offset}) =
      Philosophy;

  const factory SceneState.workExperience({@Default(0.0) double offset}) =
      WorkExperience;

  const factory SceneState.experience({@Default(0.0) double offset}) =
      Experience;

  const factory SceneState.testimonials({@Default(0.0) double offset}) =
      Testimonials;

  const factory SceneState.contact({@Default(0.0) double offset}) = Contact;
}
