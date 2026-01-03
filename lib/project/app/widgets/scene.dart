import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'stateful_scene.dart';

class FlameScene extends StatelessWidget {
  final VoidCallback onClick;

  const FlameScene({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        var bloc = SceneBloc();
        bloc.add(SceneEvent.initialize());
        return bloc;
      },
      child: Scaffold(body: StatefulScene(onClick: onClick)),
    );
  }
}
