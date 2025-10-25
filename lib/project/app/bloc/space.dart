import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';
import 'package:flutter/gestures.dart';

class SpaceScene extends StatelessWidget {
  const SpaceScene({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = MediaQuery.sizeOf(context);
        return BlocProvider<SpaceBloc>(
          create: (context) {
            var bloc = SpaceBloc(size);
            bloc.add(Initialize());
            return bloc;
          },
          lazy: false,
          child: _Space(),
        );
      },
    );
  }
}

class _Space extends StatelessWidget {
  const _Space({super.key});

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
                    child: Builder(
                      builder: (BuildContext context) {
                        return HtmlElementView(
                          viewType: bloc.three3dRender.textureId!.toString(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
