import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/renderers/web_gl_render_target.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

part 'space_event.dart';

part 'space_state.dart';

class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  final Size screenSize;

  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  late double width;
  late double height;
  double dpr = 1.0;

  late three.Scene scene;
  late three.Scene godraysScene;

  late three.Camera camera;
  late three.Mesh planet;
  late three.Mesh backgroundSphere;
  late three.Mesh sun;
  late three.AmbientLight ambientLight;
  late three.DirectionalLight directionalLight;

  // Post-processing
  late three_jsm.EffectComposer composer;
  late three_jsm.ShaderPass godraysCombinePass;
  late three.WebGLRenderTarget godraysRenderTarget;

  final three.Clock _clock = three.Clock();
  double _scrollTarget = 0.0;
  double _scrollCurrent = 0.0;
  final _origin = three.Vector3(0, 0, 0);

  bool disposed = false;

  SpaceBloc(this.screenSize) : super(SpaceInitial()) {
    on<Initialize>(_initialize);
    on<Load>(_load);
    on<Scroll>(_onScroll);
  }

  FutureOr<void> _initialize(Initialize event, Emitter<SpaceState> emit) async {
    width = screenSize.width;
    height = screenSize.height;
    dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    three3dRender = FlutterGlPlugin();
    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
    };
    await three3dRender.initialize(options: options);
    await Future.delayed(const Duration(milliseconds: 100));
    await three3dRender.prepareContext();
    await Future.delayed(const Duration(milliseconds: 100));
    add(Load());
  }

  FutureOr<void> _onScroll(Scroll event, Emitter<SpaceState> emit) {
    _scrollTarget += event.scrollDelta * 0.0005;
    _scrollTarget = _scrollTarget.clamp(0.0, 1.0);
  }

  FutureOr<void> _load(Load event, Emitter<SpaceState> emit) async {
    _initRenderer();
    scene = three.Scene();
    godraysScene = three.Scene();

    camera = three.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.set(0, 0, 6);
    scene.add(camera);

    var loader = three.TextureLoader(null);

    final backgroundTexture = await loader.loadAsync("assets/stars.jpg");
    final backgroundGeometry = three.SphereGeometry(200, 64, 32);
    final backgroundMaterial = three.MeshBasicMaterial({'map': backgroundTexture, 'side': three.BackSide});
    backgroundSphere = three.Mesh(backgroundGeometry, backgroundMaterial);
    scene.add(backgroundSphere);

    ambientLight = three.AmbientLight(0xffffff, 0.5);
    scene.add(ambientLight);

    directionalLight = three.DirectionalLight(0xffffff, 2.0);
    directionalLight.position.set(2, 2, 8);
    scene.add(directionalLight);

    final sunGeometry = three.SphereGeometry(0.5, 32, 32);
    final sunMaterial = three.MeshBasicMaterial({'color': 0xffffff});
    sun = three.Mesh(sunGeometry, sunMaterial);
    sun.position.copy(directionalLight.position);
    scene.add(sun);

    final planetTexture = await loader.loadAsync("assets/planet.jpg");
    final planetGeometry = three.SphereGeometry(1.3, 32, 32);
    final planetMaterial = three.MeshStandardMaterial({'map': planetTexture, 'roughness': 0.4});
    planet = three.Mesh(planetGeometry, planetMaterial);
    scene.add(planet);

    final occluderMaterial = three.MeshBasicMaterial({'color': 0x000000});
    final occluder = three.Mesh(planetGeometry, occluderMaterial);
    godraysScene.add(occluder);

    _initPostProcessing();

    _animate();
    emit(SpaceLoaded());
  }

  void _initPostProcessing() {
    final size = renderer!.getSize(three.Vector2(0,0));
    final dpr = renderer!.getPixelRatio();
    final renderTargetOptions = WebGLRenderTargetOptions({
      'minFilter': three.LinearFilter,
      'magFilter': three.LinearFilter,
      'format': three.RGBAFormat
    });

    godraysRenderTarget = three.WebGLRenderTarget(
        (size.width * dpr * 0.5).toInt(),
        (size.height * dpr * 0.5).toInt(),
        renderTargetOptions
    );

    composer = three_jsm.EffectComposer(renderer!, godraysRenderTarget);

    // Pass 1: Render the main scene.
    final renderPass = three_jsm.RenderPass(scene, camera, null, null, null);
    composer.addPass(renderPass);

    // Pass 2: The custom God Rays shader pass.
    final godraysCombineMaterial = three.ShaderMaterial({
      'uniforms': {
        'tDiffuse': {'value': three.Texture()},
        'tOcclusion': {'value': godraysRenderTarget.texture},
        'lightPosition': {'value': three.Vector2(0.5, 0.5)},
        'exposure': {'value': 0.55},
        'decay': {'value': 0.9},
        'density': {'value': 0.96},
        'weight': {'value': 0.6},
        'clampMax': {'value': 1.0},
      },
      'vertexShader': _passThroughVertexShader,
      'fragmentShader': _godRaysCombineFragmentShader,
    });

    // CORRECTED: Use the standard ShaderPass constructor.
    godraysCombinePass = three_jsm.ShaderPass(godraysCombineMaterial, "tDiffuse");
    godraysCombinePass.renderToScreen = true;
    composer.addPass(godraysCombinePass);
  }

  void _render() {
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);
    gl.flush();
  }


  void _animate() {
    if (disposed) return;

    final delta = _clock.getDelta();
    _scrollCurrent += (_scrollTarget - _scrollCurrent) * 0.05;

    planet.rotation.y += 0.0005;
    backgroundSphere.rotation.y = _scrollCurrent * 0.2;
    backgroundSphere.rotation.x = _scrollCurrent * -0.1;

    // --- Camera Animation ---
    const double initialDistance = 6.0;
    const double distanceFactor = 40.0;
    const double yFactor = 34.6;

    final double progress = _scrollCurrent;
    final double angle = 2 * math.pi * progress;
    final double radius = initialDistance + progress * distanceFactor;

    final double x = math.sin(angle) * radius;
    final double z = math.cos(angle) * radius;
    final double y = -progress * yFactor;

    camera.position.set(x, y, z);
    camera.lookAt(_origin);

    // Update the sun's screen-space position for the God Rays shader.
    final sunPosition = three.Vector3().copy(sun.position);
    sunPosition.project(camera);
    godraysCombinePass.material.uniforms['lightPosition']['value'].x = (sunPosition.x + 1) / 2;
    godraysCombinePass.material.uniforms['lightPosition']['value'].y = (sunPosition.y + 1) / 2;

    // Step 1: Manually render the occluder scene to its texture.
    renderer!.setRenderTarget(godraysRenderTarget);
    renderer!.render(godraysScene, camera);
    renderer!.setRenderTarget(null);

    // Step 2: Render the full post-processing chain.
    composer.render(delta);

    Future.delayed(const Duration(milliseconds: 16),   _animate);
    _render();
  }

  @override
  Future<void> close() {
    dispose();
    return super.close();
  }

  void dispose() {
    log('[3D Debug] dispose: Disposing controllers and plugin.', name: 'SpaceBloc');
    disposed = true;
    renderer?.dispose();
    godraysRenderTarget.dispose();
    three3dRender.dispose();
  }

  void _initRenderer() {
    Map<String, dynamic> options = {
      "width": width.toInt(),
      "height": height.toInt(),
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.autoClear = false;
  }
}

// --- GLSL Shaders ---

const String _passThroughVertexShader = """
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
""";

const String _godRaysCombineFragmentShader = """
  varying vec2 vUv;
  uniform sampler2D tDiffuse;
  uniform sampler2D tOcclusion;
  uniform vec2 lightPosition;
  uniform float exposure;
  uniform float decay;
  uniform float density;
  uniform float weight;
  uniform float clampMax;
  
  const int SAMPLES = 60;

  void main() {
    vec2 texCoord = vUv;
    vec2 deltaTexCoord = texCoord - lightPosition;
    deltaTexCoord *= 1.0 / float(SAMPLES) * density;
    float illuminationDecay = 1.0;
    vec4 godrayColor = vec4(0.0);

    // Loop from the current pixel towards the light source, sampling the occlusion map
    for (int i = 0; i < SAMPLES; i++) {
      texCoord -= deltaTexCoord;
      vec4 sample1 = texture2D(tOcclusion, texCoord);
      sample1 *= illuminationDecay * weight;
      godrayColor += sample1;
      illuminationDecay *= decay;
    }
    
    // Clamp the final god rays color
    vec4 finalGodrays = clamp(godrayColor * exposure, 0.0, clampMax);

    // Get the original rendered scene color
    vec4 sceneColor = texture2D(tDiffuse, vUv);

    // Additively blend the god rays on top of the scene
    gl_FragColor = sceneColor + finalGodrays;
  }
""";
