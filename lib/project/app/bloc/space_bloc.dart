import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;

part 'space_event.dart';

part 'space_state.dart';

class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  final Size screenSize;

  late FlutterGlPlugin three3dRender;

  three.WebGLRenderer? renderer;
  int? fboId;
  late double width;

  late double height;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;
  late three.Group group;
  late three.Texture texture;

  double dpr = 1.0;

  bool verbose = true;
  bool disposed = false;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  SpaceBloc(this.screenSize) : super(SpaceInitial()) {
    on<Initialize>(_initialize);
    on<Load>(_load);
  }

  FutureOr<void> _initialize(Initialize event, Emitter<SpaceState> emit) async {
    width = screenSize.width;
    height = screenSize.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
    };

    await three3dRender.initialize(options: options);
    Future.delayed(const Duration(milliseconds: 100));

    await three3dRender.prepareContext();
    Future.delayed(const Duration(milliseconds: 100));

    add(Load());
  }

  FutureOr<void> _load(Load event, Emitter<SpaceState> emit) async {
    _initRenderer();
    scene = three.Scene();
    camera = three.PerspectiveCamera(
      75,
      screenSize.width / screenSize.height,
      0.1,
      2000,
    );
    camera.position.set(0, 150, 1500);
    scene.add(camera);

    var light = three.PointLight(0xffffff, 0.8);
    camera.add(light);

    var loader = three.TextureLoader(null);
    texture = await loader.loadAsync("assets/planet.jpg", null);
    final geometry = three.SphereGeometry(200, 32, 32);
    final material = three.MeshStandardMaterial({
      'map': texture,
      'roughness': 0.4,
    });
    mesh = three.Mesh(geometry, material);
    scene.add(mesh);

    _animate();

    emit(SpaceLoaded());
  }

  void _render() {
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);
    gl.flush();
  }

  void _animate() {
    mesh.rotation.x += 0.005;
    mesh.rotation.z += 0.01;
    _render();

    Future.delayed(const Duration(milliseconds: 40), () {
      _animate();
    });
  }

  void dispose() {
    log(
      '[3D Debug] dispose: Disposing controllers and plugin.',
      name: 'Earth1',
    );
  }

  void _initRenderer() {
    Map<String, dynamic> options = {
      "width": screenSize.width,
      "height": screenSize.height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(screenSize.width, screenSize.height, false);
    renderer!.shadowMap.enabled = false;
    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat,
      });
      renderTarget = three.WebGLMultisampleRenderTarget(
        (screenSize.width * dpr).toInt(),
        (screenSize.height * dpr).toInt(),
        pars,
      );
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }
}
