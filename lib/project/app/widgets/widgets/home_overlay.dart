import 'package:flutter/material.dart';

import 'bouncing_arrow.dart';

class HomeOverlay extends StatelessWidget {
  final ValueNotifier<bool> showOverlayNotifier;
  final ValueNotifier<bool> showArrowNotifier;
  final Animation<double> bounceAnimation;

  const HomeOverlay({
    super.key,
    required this.showOverlayNotifier,
    required this.showArrowNotifier,
    required this.bounceAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showOverlayNotifier,
      builder: (context, show, child) {
        return AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: !show,
            child: Stack(
              children: [
                // Top Right: Menu
                Positioned(top: 40, right: 40, child: _buildMenuCircle()),

                // Bottom: Animated Silver Arrow
                Positioned(
                  bottom: 60, // Adjusted height
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: showArrowNotifier,
                      builder: (context, showArrow, child) {
                        return AnimatedOpacity(
                          opacity: showArrow ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: BouncingArrow(
                            bounceAnimation: bounceAnimation,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
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
