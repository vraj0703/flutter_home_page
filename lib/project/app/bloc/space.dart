import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:flutter/gestures.dart';

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

class _SpaceScreen extends StatelessWidget {
  final Size originalSize;
  final Widget child;

  const _SpaceScreen({
    super.key,
    required this.child,
    required this.originalSize,
  });

  @override
  Widget build(BuildContext context) {
    var size = originalSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        BlocProvider.of<SpaceBloc>(context).add(Initialize(screenSize: size));
        return _Space(child: child);
      },
    );
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
          case SpaceInitial():
            return const Center(child: CircularProgressIndicator());
          case SpaceLoaded():
            var bloc = BlocProvider.of<SpaceBloc>(context);
            // This Listener captures mouse wheel scroll and touch drag events
            // to control the camera animation.
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
                    width: bloc.screenSize.width,
                    height: bloc.screenSize.height,
                    color: Colors.black,
                    child: HtmlElementView(
                      viewType: bloc.three3dRender.textureId!.toString(),
                    ),
                  ),
                  child,
                ],
              ),
            );
        }
      },
    );
  }
}
