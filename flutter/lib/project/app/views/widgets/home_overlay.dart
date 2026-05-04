import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/menu_drawer_cubit.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

import 'package:flutter_home_page/project/app/views/widgets/bouncing_arrow.dart';
import 'package:flutter_home_page/project/app/views/widgets/menu_drawer.dart';

class HomeOverlay extends StatelessWidget {
  final Animation<double> bounceAnimation;

  const HomeOverlay({super.key, required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBloc, SceneState>(
      builder: (context, state) {
        return state.maybeWhen(
          orElse: () => SizedBox.shrink(key: ValueKey("home_overlay")),
          title: () => _buildOverlay(context, 1.0, true),
          active: (uiOpacity, isArrowVisible) =>
              _buildOverlay(context, uiOpacity, isArrowVisible),
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context, double opacity, bool isArrowVisible) {
    return Stack(
      key: ValueKey("home_overlay_stack"),
      children: [
        // Top Right: Menu (now tap-routed to open the drawer — RAJ-38)
        Positioned(
          top: GameLayout.menuMargin,
          right: GameLayout.menuMargin,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.read<MenuDrawerCubit>().open(),
            child: _buildMenuCircle(),
          ),
        ),

        // Bottom: Animated Silver Arrow
        Positioned(
          bottom: GameLayout.arrowBottomMargin,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isArrowVisible ? opacity : 0.0,
                child: BouncingArrow(
                  key: ValueKey("bouncing_arrow"),
                  bounceAnimation: bounceAnimation,
                ),
              ),
            ],
          ),
        ),

        // Drawer (renders on top of everything when open — RAJ-38, RAJ-39).
        // Self-gates on MenuDrawerCubit state, so it's a no-op when closed.
        const MenuDrawer(),
      ],
    );
  }

  Widget _buildMenuCircle() {
    // Visual unchanged — transparent circle with thin white border. The
    // tap target is the parent GestureDetector. Three small dots inside
    // hint at interactivity (the circle was empty + decorative until M4).
    return Container(
      width: GameLayout.menuSize,
      height: GameLayout.menuSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: GameStyles.menuBorderAlpha),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: GameStyles.menuBorderAlpha),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
