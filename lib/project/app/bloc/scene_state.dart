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

  const factory SceneState.boldText({@Default(1.0) double uiOpacity}) =
      BoldText;

  const factory SceneState.philosophy() = Philosophy;

  const factory SceneState.workExperience() = WorkExperience;

  const factory SceneState.experience() = Experience;

  const factory SceneState.testimonials() = Testimonials;

  const factory SceneState.contact() = Contact;
}
