import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:lottie/lottie.dart';

/// Main overlay widget that listens to scroll changes
/// and orchestrates the fading of UI elements.
class PortfolioOverlays extends StatelessWidget {
  const PortfolioOverlays({super.key});

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SpaceBloc>(context, listen: false);
    // Use ValueListenableBuilder to react to scroll changes from the BLoC
    return ValueListenableBuilder<double>(
      valueListenable: bloc.scrollNotifier,
      builder: (context, scrollValue, _) {
        // --- Animation Logic ---
        // State 1: Fades out between 0.0 and 0.2 scroll progress
        final promptOpacity = (1.0 - (scrollValue / 0.2)).clamp(0.0, 1.0);

        // State 2: Button Animation (Fade in 0.2 -> 0.5, Fade out 0.5 -> 0.7)
        double buttonsOpacity;
        if (scrollValue < 0.2) {
          buttonsOpacity = 0.0; // Before fade in starts
        } else if (scrollValue <= 0.5) {
          // Fade IN: Ramps up from 0.0 to 1.0 as scroll goes from 0.2 to 0.5
          buttonsOpacity = ((scrollValue - 0.2) / 0.3).clamp(0.0, 1.0);
        } else if (scrollValue <= 0.7) {
          // Fade OUT: Ramps down from 1.0 to 0.0 as scroll goes from 0.5 to 0.7
          buttonsOpacity = (1.0 - ((scrollValue - 0.5) / 0.2)).clamp(0.0, 1.0);
        } else {
          buttonsOpacity = 0.0; // After fade out ends
        }

        return Stack(
          children: [
            // State 1: "Scroll to know more"
            // Use IgnorePointer to prevent it from blocking interactions when invisible
            IgnorePointer(
              ignoring: promptOpacity == 0,
              child: Opacity(
                opacity: promptOpacity,
                child: const ScrollPrompt(),
              ),
            ),

            // State 2: Portfolio Buttons
            IgnorePointer(
              ignoring: buttonsOpacity == 0,
              child: Opacity(
                opacity: buttonsOpacity,
                child: const _PortfolioButtons(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- STATE 1 WIDGETS ---

/// The "Scroll to know more" text and blinking arrow
class ScrollPrompt extends StatelessWidget {
  const ScrollPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Scroll to know more",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.none, // Remove underline from stack
              ),
            ),
            const SizedBox(height: 8),
            BlinkingArrow(),
          ],
        ),
      ),
    );
  }
}

/// A stateful widget for the blinking arrow animation
class BlinkingArrow extends StatefulWidget {
  const BlinkingArrow({super.key});

  @override
  BlinkingArrowState createState() => BlinkingArrowState();
}

class BlinkingArrowState extends State<BlinkingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(
        Icons.keyboard_arrow_down,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

// --- STATE 2 WIDGETS ---

/// The row of portfolio buttons
class _PortfolioButtons extends StatelessWidget {
  const _PortfolioButtons();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: Wrap(
          spacing: 16, // Horizontal spacing
          runSpacing: 16, // Vertical spacing for smaller screens
          alignment: WrapAlignment.center,
          children: [
            PortfolioButton(
              text: "Resume",
              onPressed: () {
                //log("My Resume clicked", name: "Portfolio");
              },
            ),
            PortfolioButton(
              text: "Projects",
              onPressed: () {
                //log("My Works clicked", name: "Portfolio");
              },
            ),
            PortfolioButton(
              text: "Testimonials",
              onPressed: () {
                //log("Testimonials clicked", name: "Portfolio");
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single, reusable outlined button
class PortfolioButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PortfolioButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style:
          OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 14,
              decoration: TextDecoration.none, // Remove underline
            ),
          ).copyWith(
            // Add a subtle hover effect
            overlayColor: WidgetStateProperty.all(
              Colors.white.withOpacity(0.1),
            ),
          ),
      child: Text(text),
    );
  }
}

class LottieLoadingScreen extends StatelessWidget {
  final String? message;

  const LottieLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      // The FadeTransition is now in the PARENT (_SpaceScreen)
      child: Center(
        child: Stack(
          children: [
            Lottie.asset(
              'assets/calming_circle_white.json', // Your asset path
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              animate: true,
              repeat: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom clipper that creates a "curtain opening" effect.
///
/// It draws two rectangles that retract from the center of the screen
/// towards the top and bottom edges as `revealProgress` goes from 0.0 to 1.0.
class CurtainClipper extends CustomClipper<Path> {
  final double revealProgress;

  CurtainClipper({required this.revealProgress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = size.height / 2;
    // The height of the opening slit, grows with progress.
    final openHeight = size.height * revealProgress;

    // Top curtain part
    path.addRect(Rect.fromLTWH(0, 0, size.width, center - openHeight / 2));

    // Bottom curtain part
    path.addRect(
      Rect.fromLTWH(
        0,
        center + openHeight / 2,
        size.width,
        center - openHeight / 2,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    oldClipper as CurtainClipper;
    // Reclip whenever the progress changes to drive the animation.
    return oldClipper.revealProgress != revealProgress;
  }
}
