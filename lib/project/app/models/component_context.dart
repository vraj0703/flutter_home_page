import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/system/scroll/scroll_orchestrator.dart';

class ComponentContext {
  final Vector2 size;
  final StateProvider stateProvider;
  final Queuer queuer;
  final ScrollOrchestrator scrollOrchestrator;
  final Color Function() backgroundColorCallback;
  final Future<FragmentShader> Function(String path) loadShader;
  final Future<Image> Function(String path) loadImage;

  ComponentContext({
    required this.size,
    required this.stateProvider,
    required this.queuer,
    required this.scrollOrchestrator,
    required this.backgroundColorCallback,
    required this.loadShader,
    required this.loadImage,
  });
}
