import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';

abstract class Queuer {
  queue({required SceneEvent event});
}
