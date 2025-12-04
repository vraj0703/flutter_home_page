import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_home_page/project/app/widgets/flame.dart';
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
  bool _isSceneBuilt = false;
  bool _startFade = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SpaceBloc, SpaceState>(
      listener: (context, state) {
        if (state is SpaceLoaded) {
          // 1. First, call setState to build the 3D scene.
          //    This will cause the jank.
          setState(() {
            _isSceneBuilt = true;
          });

          // 2. Wait for that janky frame to finish.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 3. Now, call setState again to trigger the
            //    *smooth* fade-out animation.
            setState(() {
              _startFade = true;
            });
          });
        }
      },
      // Pass the flags down instead of the controller
      child: SpaceBuilder(
        isSceneBuilt: _isSceneBuilt,
        startFade: _startFade,
        child: widget.child,
      ),
    );
  }
}

class SpaceBuilder extends StatelessWidget {
  final Widget child;
  final bool isSceneBuilt;
  final bool startFade;

  const SpaceBuilder({
    super.key,
    required this.child,
    required this.isSceneBuilt,
    required this.startFade,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get current constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);

        // We wrap the *stack* in a BlocBuilder
        return BlocBuilder<SpaceBloc, SpaceState>(
          // This is the key optimization:
          // We only rebuild this-stack IF:
          // 1. We are moving from a "loading" state to "loaded" state
          // 2. We are in the "loaded" state and a resize happens
          buildWhen: (prev, curr) {
            // Build if we just finished loading
            if (prev is! SpaceLoaded && curr is SpaceLoaded) return true;
            // Build if a resize happened *after* we loaded
            if (curr is SpaceLoaded &&
                prev is SpaceLoaded &&
                prev.screenSize != curr.screenSize) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            // Get the bloc instance *inside* the builder
            final bloc = BlocProvider.of<SpaceBloc>(context, listen: false);

            // --- Optimized Resize Logic ---
            // This check now happens *inside* the builder
            // and *after* the state has already updated (if it did).
            if (state is SpaceLoaded && newSize != state.screenSize) {
              // The layout has changed. Tell the BLoC *after* this
              // build is finished. This is the correct use.
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
                  // The UI is built *directly* from the state.
                  // No more `setState`!
                  if (state is SpaceLoaded) ...[
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      color: Colors.black,
                      child: HtmlElementView(
                        // Use the textureId from the state
                        viewType: state.three3dRender.textureId!.toString(),
                      ),
                    ),
                    // Use context.read/watch inside your overlays
                    // instead of passing the bloc instance.
                    PortfolioOverlays(),
                    child,
                  ],

                  // 2. The AnimatedSwitcher (replaces _LoadingCurtains)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 750),
                    // This is the default fade transition
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    // This is the magic:
                    child: !startFade
                        // Key 1: If we haven't started the fade,
                        // show the Lottie screen.
                        ? FlameScene(
                            key: const ValueKey('loading'),
                            onClick: () {
                              BlocProvider.of<SpaceBloc>(
                                context,
                                listen: false,
                              ).add(
                                Initialize(
                                  screenSize: MediaQuery.sizeOf(context),
                                ),
                              );
                            },
                          )
                        // Key 2: If we *have* started the fade,
                        // tell the switcher to show an empty box.
                        : const SizedBox.shrink(key: ValueKey('loaded')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
