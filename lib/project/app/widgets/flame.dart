import 'package:flutter/material.dart';
import 'reveal_animation.dart';

class FlameScene extends StatelessWidget {
  final VoidCallback onClick;

  const FlameScene({super.key, required this.onClick});

  @override
  Widget build(BuildContext context) {
    return RevealScene(onClick: onClick);
  }
}
