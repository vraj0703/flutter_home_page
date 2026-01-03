import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
                    offset: const Offset(0, 4), // Push shadow slightly down
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: SvgPicture.asset(
                        'assets/vectors/down_arrow.svg',
                        width: 30,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.7), // Shadow intensity
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),

                  // --- LAYER 2: THE SILVER ARROW ---
                  SvgPicture.asset(
                    'assets/vectors/down_arrow.svg',
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFC0C0C0), // Brushed Silver
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
