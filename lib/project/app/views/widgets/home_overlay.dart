import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

import 'package:flutter_home_page/project/app/views/widgets/bouncing_arrow.dart';

class HomeOverlay extends StatelessWidget {
  final Animation<double> bounceAnimation;

  const HomeOverlay({super.key, required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      builder: (context, state) {
        return state.maybeWhen(
          orElse: () => SizedBox.shrink(key: ValueKey("home_overlay")),
          title: () => _buildOverlay(1.0),
          boldText: (uiOpacity) => _buildOverlay(uiOpacity),
          philosophy: () => _buildOverlay(0.0),
          workExperience: () => _buildOverlay(0.0),
          experience: () => _buildOverlay(0.0),
          testimonials: () => _buildOverlay(0.0),
          contact: () => _buildOverlay(0.0),
        );
      },
    );
  }

  Widget _buildOverlay(double opacity) {
    return Stack(
      key: ValueKey("home_overlay_stack"),
      children: [
        // Top Right: Menu
        Positioned(
          top: GameLayout.menuMargin,
          right: GameLayout.menuMargin,
          child: _buildMenuCircle(),
        ),

        // Bottom: Animated Silver Arrow
        Positioned(
          bottom: GameLayout.arrowBottomMargin,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: BouncingArrow(
                key: ValueKey("bouncing_arrow"),
                bounceAnimation: bounceAnimation,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCircle() {
    return Container(
      width: GameLayout.menuSize,
      height: GameLayout.menuSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: GameStyles.menuBorderAlpha),
        ),
      ),
      child: const SizedBox(),
    );
  }
}
