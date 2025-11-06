import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_home_page/project/app/widgets/widgets.dart';

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

  const _SpaceScreen({required this.child, required this.originalSize});

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
      duration: const Duration(milliseconds: 500), // Fade duration
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

      child: SpaceBuilder(
        lottieFadeController: _lottieFadeController,
        isSceneBuilt: _isSceneBuilt,
        child: widget.child,
      ),
    );
  }
}

class _LoadingCurtains extends StatelessWidget {
  final AnimationController lottieFadeController;
  final bool isSceneBuilt;

  const _LoadingCurtains({
    required this.lottieFadeController,
    required this.isSceneBuilt,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      buildWhen: (prev, curr) => curr is SpaceInitial || curr is SpaceLoading,
      builder: (context, state) {
        String? message;
        if (state is SpaceLoading) {
          message = state.message;
        }

        return IgnorePointer(
          // Ignore pointer when faded out
          ignoring: isSceneBuilt && lottieFadeController.value == 0.0,
          child: FadeTransition(
            opacity: lottieFadeController,
            // Pass the message to the Lottie screen
            child: LottieLoadingScreen(message: message),
          ),
        );
      },
    );
  }
}

class SpaceBuilder extends StatelessWidget {
  final Widget child;
  final AnimationController lottieFadeController;
  final bool isSceneBuilt;

  const SpaceBuilder({
    super.key,
    required this.child,
    required this.lottieFadeController,
    required this.isSceneBuilt,
  });

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
              if (isSceneBuilt) ...[
                Container(
                  // Use the *current* size from LayoutBuilder,
                  // not the old size from the BLoC state.
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: Colors.black,

                  // This is far more performant and handles
                  // resizing better than HtmlElementView.
                  child: HtmlElementView(
                    viewType: bloc.three3dRender.textureId!.toString(),
                  ),
                ),
                PortfolioOverlays(bloc: bloc),
                child,
              ],
              if (!isSceneBuilt)
                _LoadingCurtains(
                  lottieFadeController: lottieFadeController,
                  isSceneBuilt: isSceneBuilt,
                ),
            ],
          ),
        );
      },
    );
  }
}
