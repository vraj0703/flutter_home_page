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

class _SpaceScreenState extends State<_SpaceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieFadeController;
  bool _isSceneBuilt = false;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<SpaceBloc>(
      context,
      listen: false,
    ).add(Initialize(screenSize: widget.originalSize));

    _lottieFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750), // Fade duration
      value: 1.0, // Start at full opacity
    );
  }

  @override
  void dispose() {
    _lottieFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget now listens AND builds the UI
    return BlocListener<SpaceBloc, SpaceState>(
      // --- THIS IS THE FIX ---
      // The listener now correctly hears the SpaceLoaded state
      listener: (context, state) {
        if (state is SpaceLoaded) {
          // 1. BLoC is loaded. Call setState to build the
          //    3D scene *behind* the curtain (causes jank).
          setState(() {
            _isSceneBuilt = true;
          });

          // 2. Wait for the janky frame to finish
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 3. Now, start the smooth fade-out animation
            _lottieFadeController.reverse();
          });
        }
      },
      // --- END FIX ---
      child: Stack(
        children: [
          // --- Layer 1: The 3D Scene (Builds when ready) ---
          if (_isSceneBuilt) SpaceBuilder(child: widget.child),

          // --- Layer 2: The Lottie Curtain (Fades out) ---
          // Use a BlocBuilder to get loading messages
          BlocBuilder<SpaceBloc, SpaceState>(
            buildWhen: (prev, curr) =>
                curr is SpaceInitial || curr is SpaceLoading,
            builder: (context, state) {
              String? message;
              if (state is SpaceLoading) {
                message = state.message;
              }

              return IgnorePointer(
                // Ignore pointer when faded out
                ignoring: _isSceneBuilt && _lottieFadeController.value == 0.0,
                child: FadeTransition(
                  opacity: _lottieFadeController,
                  // Pass the message to the Lottie screen
                  child: LottieLoadingScreen(message: message),
                ),
              );
            },
          ),
        ],
      ),
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
  final String? message;

  const LottieLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      // The FadeTransition is now in the PARENT (_SpaceScreen)
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/wave_lottie.json', // Your asset path
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
