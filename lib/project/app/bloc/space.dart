import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:lottie/lottie.dart';

class SpaceScene extends StatelessWidget {
  final Widget child;

  const SpaceScene({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return BlocProvider<SpaceBloc>(
      create: (context) {
        var bloc = SpaceBloc();
        return bloc;
      },
      lazy: false,
      child: _SpaceScreen(originalSize: size, child: child),
    );
  }
}

class _SpaceScreen extends StatefulWidget {
  final Size originalSize;
  final Widget child;

  const _SpaceScreen({
    super.key,
    required this.child,
    required this.originalSize,
  });

  @override
  State<_SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<_SpaceScreen> {
  @override
  void initState() {
    super.initState();

    // --- THIS IS THE FIX ---
    // We add the Initialize event here, in initState, which runs
    // only ONCE when the widget is first added to the tree.
    // We use listen: false because we are not in a builder.
    BlocProvider.of<SpaceBloc>(
      context,
      listen: false,
    ).add(Initialize(screenSize: widget.originalSize));
  }

  @override
  Widget build(BuildContext context) {
    // The build method now *only* builds the UI.
    // It no longer sends events.
    // The LayoutBuilder was redundant, so we can remove it.
    return _Space(child: widget.child);
  }
}

class _Space extends StatelessWidget {
  final Widget child;

  const _Space({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        switch (state) {
          case SpaceLoading():
          case SpaceInitial():
            return const Center(child: CircularProgressIndicator());
          case SpaceLoaded():
            var bloc = BlocProvider.of<SpaceBloc>(context);
            // This Listener captures mouse wheel scroll and touch drag events
            // to control the camera animation.
            return SpaceBuilder(child: child);
        }
      },
    );
  }
}

class SpaceBuilder extends StatelessWidget {
  final Widget child;

  const SpaceBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<SpaceBloc>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Check if the size has *actually* changed
        if (newSize != bloc.screenSize && bloc.state is SpaceLoaded) {
          // Send event *after* the build to update the 3D camera
          WidgetsBinding.instance.addPostFrameCallback((_) {
            bloc.add(Resize(newSize));
          });
        }

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              bloc.add(Scroll(event.scrollDelta.dy));
            }
          },
          onPointerMove: (event) {
            bloc.add(Scroll(event.delta.dy));
          },
          child: Stack(
            children: [
              Container(
                // --- FIX #1: USE CONSTRAINTS ---
                // Use the *current* size from LayoutBuilder,
                // not the old size from the BLoC state.
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.black,

                // --- FIX #2: USE TEXTURE ---
                // This is far more performant and handles
                // resizing better than HtmlElementView.
                child: HtmlElementView(
                  viewType: bloc.three3dRender.textureId!.toString(),
                ),
                // --- Old Code ---
                // child: HtmlElementView(
                //   viewType: bloc.three3dRender.textureId!.toString(),
                // ),
              ),
              _PortfolioOverlays(bloc: bloc),
              child,
            ],
          ),
        );
      },
    );
  }
}

// --- 2. ADD ALL THE WIDGETS BELOW ---

/// Main overlay widget that listens to scroll changes
/// and orchestrates the fading of UI elements.
class _PortfolioOverlays extends StatelessWidget {
  final SpaceBloc bloc;

  const _PortfolioOverlays({required this.bloc});

  @override
  Widget build(BuildContext context) {
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
                child: const _ScrollPrompt(),
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
class _ScrollPrompt extends StatelessWidget {
  const _ScrollPrompt();

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
            _BlinkingArrow(),
          ],
        ),
      ),
    );
  }
}

/// A stateful widget for the blinking arrow animation
class _BlinkingArrow extends StatefulWidget {
  @override
  _BlinkingArrowState createState() => _BlinkingArrowState();
}

class _BlinkingArrowState extends State<_BlinkingArrow>
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
            _PortfolioButton(
              text: "Resume",
              onPressed: () {
                //log("My Resume clicked", name: "Portfolio");
              },
            ),
            _PortfolioButton(
              text: "Projects",
              onPressed: () {
                //log("My Works clicked", name: "Portfolio");
              },
            ),
            _PortfolioButton(
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
class _PortfolioButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PortfolioButton({required this.text, required this.onPressed});

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
  const LottieLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Use black to match the background of your 3D scene
      color: Colors.black,
      child: Center(
        child: Lottie.asset(
          'assets/wave_lottie.json', // <-- Your asset path
          width: 250,
          // Adjust the size as needed
          height: 250,
          fit: BoxFit.contain,
          animate: true,
          repeat: true,
        ),
      ),
    );
  }
}
