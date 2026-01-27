import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/scroll_observer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_observer.dart';
import 'package:flutter_home_page/project/app/views/components/background/background_run_component.dart';
import 'package:flutter_home_page/project/app/views/components/philosophy/beach_background_component.dart';

class BackgroundController implements StateObserver {
  final BackgroundRunComponent component;
  final BeachBackgroundComponent beach;
  final Vector2 screenSize;

  BackgroundController({
    required this.component,
    required this.screenSize,
    required this.beach,
  });

  @override
  void onStateChange(SceneState state) {
    // TODO: implement onStateChange
  }
}
