import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:ui' as ui;

class HomeOverlay extends StatefulWidget {
  final Widget child;
  final ValueNotifier<bool> showOverlayNotifier;

  const HomeOverlay({
    super.key,
    required this.child,
    required this.showOverlayNotifier,
  });

  @override
  State<HomeOverlay> createState() => _HomeOverlayState();
}

class _HomeOverlayState extends State<HomeOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the Bounce Animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // Continuous loop

    // 2. Define the vertical offset (bounces 15 pixels down)
    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOutQuad, // Smooth "floating" motion
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        ValueListenableBuilder<bool>(
          valueListenable: widget.showOverlayNotifier,
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
                    Positioned(
                      top: 40,
                      right: 40,
                      child: _buildMenuCircle(),
                    ),

                    // Bottom: Animated Silver Arrow
                    Positioned(
                      bottom: 60, // Adjusted height
                      left: 0,
                      right: 0,
                      child: Center(child: _buildBouncingArrow()),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCircle() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const SizedBox(),
    );
  }

  Widget _buildBouncingArrow() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
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
                      imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: SvgPicture.asset(
                        'assets/images/down_arrow.svg',
                        width: 30,
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.7), // Shadow intensity
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