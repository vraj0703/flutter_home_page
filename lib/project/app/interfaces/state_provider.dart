import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';

/// Read-only access to the current scene state and reveal progress.
///
/// In production, [SceneBloc] implements this directly. The abstraction
/// decouples game systems from BLoC internals, making them testable with
/// simple mock implementations. Systems that only need to *read* state
/// depend on this; systems that need to *write* events depend on [Queuer].
abstract class StateProvider {
  SceneState sceneState();

  double revealProgress();

  void updateRevealProgress(double progress);

  Stream<SceneState> get stream;

  void updateUIOpacity(double opacity);
}
