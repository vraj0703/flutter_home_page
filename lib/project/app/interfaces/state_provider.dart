import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';

abstract class StateProvider {
  SceneState sceneState();

  double revealProgress();

  void updateRevealProgress(double progress);

  void updateUIOpacity(double opacity);

  Stream<SceneState> get stream;
}
