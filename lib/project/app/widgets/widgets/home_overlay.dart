import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';

import 'bouncing_arrow.dart';

class HomeOverlay extends StatelessWidget {
  final Animation<double> bounceAnimation;

  const HomeOverlay({super.key, required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      builder: (context, state) {
        return state.maybeWhen(
          orElse: () => SizedBox.shrink(key: ValueKey("home_overlay")),
          title: () => Stack(
            key: ValueKey("home_overlay_stack"),
            children: [
              // Top Right: Menu
              Positioned(top: 40, right: 40, child: _buildMenuCircle()),

              // Bottom: Animated Silver Arrow
              Positioned(
                bottom: 60, // Adjusted height
                left: 0,
                right: 0,
                child: Center(
                  child: BouncingArrow(
                    key: ValueKey("bouncing_arrow"),
                    bounceAnimation: bounceAnimation,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCircle() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: const SizedBox(),
    );
  }
}
