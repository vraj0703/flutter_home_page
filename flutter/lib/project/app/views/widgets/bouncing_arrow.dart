import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/scene_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_home_page/project/app/config/game_layout.dart';
import 'package:flutter_home_page/project/app/config/game_styles.dart';

class BouncingArrow extends StatelessWidget {
  final Animation<double> bounceAnimation;

  const BouncingArrow({super.key, required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, bounceAnimation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // We use a Stack to layer the shadow behind the arrow
              Stack(
                alignment: Alignment.center,
                children: [
                  // --- LAYER 1: THE SHADOW ---
                  Transform.translate(
                    offset: const Offset(
                      GameLayout.arrowShadowOffsetX,
                      GameLayout.arrowShadowOffsetY,
                    ),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: GameStyles.arrowShadowBlur,
                        sigmaY: GameStyles.arrowShadowBlur,
                      ),
                      child: SvgPicture(
                        BlocProvider.of<SceneBloc>(context).downArrowLoader,
                        width: GameLayout.arrowSize,
                        height: GameLayout.arrowSize,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(
                            alpha: 0.7,
                          ),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),

                  // --- LAYER 2: THE SILVER ARROW ---
                  SvgPicture(
                    BlocProvider.of<SceneBloc>(context).downArrowLoader,
                    width: GameLayout.arrowSize,
                    height: GameLayout.arrowSize,
                    colorFilter: const ColorFilter.mode(
                      GameStyles.arrowColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: GameLayout.arrowSpacing),
            ],
          ),
        );
      },
    );
  }
}
