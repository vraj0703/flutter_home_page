import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/bloc/space_bloc.dart';

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
            return Center(child: CircularProgressIndicator());
          case SpaceLoaded():
            var bloc = BlocProvider.of<SpaceBloc>(context);
            /*ui.platformViewRegistry.registerViewFactory(
              bloc.flutterGlPlugin.textureId!.toString(),
                  (int viewId) => bloc.flutterGlPlugin.element,
            );*/
            return Stack(
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
            );
        }
      },
    );
  }
}
