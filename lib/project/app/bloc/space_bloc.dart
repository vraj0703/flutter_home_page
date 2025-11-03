import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

import 'bloom_pass.dart';
import 'effect_composer.dart';
import 'god_rays.dart';

part 'space_event.dart';

part 'space_state.dart';

class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  late Size screenSize;

  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  late double width;
  late double height;
  double dpr = 1.0;

  late three.Scene scene;
  late three.Scene godraysScene;

  late three.Camera camera;
  late three.Mesh planet;
  late three.Mesh occluder;
  late three.Mesh backgroundSphere;
  late three.Mesh sun;
  late three.Mesh sunOccluder;
  late three.Points stars;
  late three.AmbientLight ambientLight;
  late three.DirectionalLight directionalLight;

  // Post-processing
  late EffectComposer1 composer;
  late EffectComposer1 godraysComposer;

  late UnrealBloomPass1 bloomPass;
  late three_jsm.ShaderPass godRayGeneratePass;
  late three_jsm.ShaderPass godRayCombinePass;

  final three.Clock _clock = three.Clock();
  double _scrollTarget = 0.0;
  double _scrollCurrent = 0.0;
  final _origin = three.Vector3(0, 0, 0);
  var loader = three.TextureLoader(null);

  bool disposed = false;
  final scrollNotifier = ValueNotifier<double>(0.0);

  SpaceBloc() : super(SpaceInitial()) {
    on<Initialize>(_initialize);
    on<Load>(_load);
    on<Scroll>(_onScroll);
    on<Rotate>(_rotate);
  }

  FutureOr<void> _initialize(Initialize event, Emitter<SpaceState> emit) async {
    log('[3D Debug] _initialize', name: 'SpaceBloc');
    screenSize = event.screenSize;
    width = screenSize.width;
    height = screenSize.height;
    dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

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
    log('[3D Debug] _load', name: 'SpaceBloc');
    _initRenderer();
    scene = three.Scene();
    godraysScene = three.Scene();
    _initCamera();
    await _addBackground();
    _addLights();
    var sunGeometry = await _addSun();
    var planetGeometry = await _addPlanet();
    _addStarField();
    _addOccluders(planetGeometry, sunGeometry);
    _initPostProcessing();
    _animate();
    emit(SpaceLoaded());
  }

  void _initPostProcessing() {
    try {
      print('[3D Debug] _initPostProcessing');
      final size = renderer!.getSize(three.Vector2(0, 0));
      final dpr = renderer!.getPixelRatio();

      final three.Vector2 composerSize = three.Vector2(
        size.width * dpr,
        size.height * dpr,
      );

      final fAspect = (size.width * dpr) / (size.height * dpr);

      composer = EffectComposer1(renderer!, null);

      // Pass 1: Render the main scene.
      final renderPass = three_jsm.RenderPass(scene, camera, null, null, null);
      renderPass.clear = true;
      composer.addPass(renderPass);

      bloomPass = UnrealBloomPass1(
        composerSize, // Full screen resolution
        2, // strength: adjusted for visible glow
        1, // radius: softer, wider halo
        0.7, // threshold: only objects with high brightness (the sun) will bloom
      );
      composer.addPass(bloomPass);

      godraysComposer = EffectComposer1(renderer!, null);
      godraysComposer.renderToScreen = false;

      final godraysMaskPass = three_jsm.RenderPass(
        godraysScene,
        camera,
        null,
        null,
        null,
      );
      godraysMaskPass.clear = true;
      godraysComposer.addPass(godraysMaskPass);

      // Pass 2: Use the mask to generate god rays
      godRayGeneratePass = three_jsm.ShaderPass(
        godRaysGenerateShader,
        'tDiffuse',
      );
      godRayGeneratePass.uniforms['fAspect']['value'] = fAspect;
      godRayGeneratePass.needsSwap = false;
      godraysComposer.addPass(godRayGeneratePass);

      // Pass 3: Combine the bloomed scene with the god rays
      godRayCombinePass = three_jsm.ShaderPass(
        godRaysCombineShader,
        'tDiffuse',
      );

      // Read from renderTarget1, where the final rays are written.
      godRayCombinePass.uniforms['tGodRays']['value'] =
          godraysComposer.renderTarget1.texture;
      godRayCombinePass.renderToScreen = true;
      composer.addPass(godRayCombinePass);
    } on Exception catch (e) {
      print('[3D Debug] _initPostProcessing: $e');
    }
  }

  void _animate() {
    print('[3D Debug] _animate');
    if (disposed) return;

    final delta = _clock.getDelta();
    final elapsedTime = _clock.getElapsedTime();

    _scrollCurrent += (_scrollTarget - _scrollCurrent) * 0.05;
    scrollNotifier.value = _scrollCurrent;

    planet.rotation.y += 0.0005;
    occluder.rotation.y = planet.rotation.y;
    backgroundSphere.rotation.y = _scrollCurrent * 0.2;
    backgroundSphere.rotation.x = _scrollCurrent * -0.1;
    stars.rotation.y += 0.00007;

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

    // --- Update God Ray Uniforms ---
    // Keep the occluder sun's position in sync
    sunOccluder.position.copy(sun.position);

    // Update the sun's screen-space position for the God Rays shader
    final sunPosition = three.Vector3().copy(sun.position);
    sunPosition.project(camera);

    final sunScreenPos = three.Vector2(
      (sunPosition.x + 1) / 2,
      (sunPosition.y + 1) / 2,
    );
    // Update the uniform in the generate pass
    godRayGeneratePass.uniforms['vSunPositionScreen']['value'] = sunScreenPos;
    godRayGeneratePass.uniforms['fTime']['value'] = elapsedTime;

    // --- Render ---
    godraysComposer.render(delta);
    composer.render(delta);
    _render();

    Future.delayed(const Duration(milliseconds: 16), _animate);
  }

  void _render() {
    print('[3D Debug] _render');
    final gl = three3dRender.gl;

    gl.flush();
  }

  @override
  Future<void> close() {
    dispose();
    return super.close();
  }

  void dispose() {
    print('[3D Debug] dispose: Disposing controllers and plugin.');
    disposed = true;
    stars.geometry?.dispose();
    stars.material?.dispose();
    scrollNotifier.dispose();
    renderer?.dispose();
    three3dRender.dispose();
  }

  void _initRenderer() {
    print('[3D Debug] _initRenderer');
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

  FutureOr<void> _rotate(Rotate event, Emitter<SpaceState> emit) {
    backgroundSphere.quaternion.set(event.x, event.y, event.z, event.w);
    //backgroundSphere.rotation.set(event.x * three.Math.pi, event.y* three.Math.pi, event.z* three.Math.pi);
    _render();
  }

  _initCamera() {
    camera = three.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.set(0, 0, 6);
    scene.add(camera);
  }

  Future<void> _addBackground() async {
    final backgroundTexture = await loader.loadAsync("assets/stars.jpg");
    final backgroundGeometry = three.SphereGeometry(500, 64, 32);
    final backgroundMaterial = three.MeshBasicMaterial({
      'map': backgroundTexture,
      'side': three.BackSide,
    });
    backgroundSphere = three.Mesh(backgroundGeometry, backgroundMaterial);
    backgroundSphere.quaternion.set(-0.2, -0.5, 0.9, 0.4);
    scene.add(backgroundSphere);
  }

  _addLights() {
    ambientLight = three.AmbientLight(0xffffff, 0.05);
    scene.add(ambientLight);

    directionalLight = three.DirectionalLight(0xffffff, 1);
    directionalLight.position.set(0, 100, 150);
    scene.add(directionalLight);
  }

  Future<three.SphereGeometry> _addSun() async {
    final sunGeometry = three.SphereGeometry(12, 80, 80);
    final glowingMaterial = three.MeshStandardMaterial({
      'color': 0xffffff,
      'emissive': 0xffffff,
      // Emissive color also > 1
      'toneMapped': false,
      // Important: disable tone mapping for this material
    });
    glowingMaterial.emissiveIntensity = 2;
    sun = three.Mesh(sunGeometry, glowingMaterial);
    sun.position.copy(directionalLight.position);
    scene.add(sun);
    return sunGeometry;
  }

  Future<three.SphereGeometry> _addPlanet() async {
    final planetTexture = await loader.loadAsync("assets/planet.jpg");
    final planetGeometry = three.SphereGeometry(1.3, 256, 256);
    final planetMaterial = three.MeshStandardMaterial({
      'map': planetTexture,
      'roughness': 0.6,
      'metalness': 0.4,
    });
    planet = three.Mesh(planetGeometry, planetMaterial);
    scene.add(planet);
    return planetGeometry;
  }

  _addStarField() {
    // --- ADD STARFIELD ---
    final int starCount = 500;
    final positions = Float32Array(starCount * 3);
    final random = math.Random();
    final spawnRadius = 450.0; // Must be less than backgroundSphere (500)

    for (int i = 0; i < starCount; i++) {
      final i3 = i * 3;

      // Get a random point on a sphere, then move it out
      // This creates a more natural, less "boxy" distribution
      final phi = random.nextDouble() * 2 * math.pi;
      final theta = math.acos((random.nextDouble() * 2) - 1);

      // Give a random distance, but not from 0, so it's a thick shell
      final r = 200 + random.nextDouble() * (spawnRadius - 200);

      positions[i3] = r * math.sin(theta) * math.cos(phi); // x
      positions[i3 + 1] = r * math.sin(theta) * math.sin(phi); // y
      positions[i3 + 2] = r * math.cos(theta); // z
    }

    final starGeometry = three.BufferGeometry();
    starGeometry.setAttribute(
      'position',
      three.Float32BufferAttribute(positions, 3),
    );

    final starMaterial = three.PointsMaterial({
      'color': 0xffffff,
      'size': 1.0,
      'sizeAttenuation': true, // Stars far away are smaller
      'blending': three.AdditiveBlending, // Makes stars glow
      'transparent': true,
      'depthWrite': false, // Prevents render artifacts with transparency
    });

    stars = three.Points(starGeometry, starMaterial);
    scene.add(stars);
  }

  _addOccluders(
    three.SphereGeometry planetGeometry,
    three.SphereGeometry sunGeometry,
  ) {
    // --- Occluders (For God Ray Scene) ---
    // 1. Black Planet
    final occluderMaterial = three.MeshBasicMaterial({'color': 0x000000});
    occluder = three.Mesh(planetGeometry, occluderMaterial);
    godraysScene.add(occluder); // <-- Add to godraysScene

    // 2. White Sun
    final sunOcclusionMaterial = three.MeshBasicMaterial({
      'color': 0xffffff, // <-- White
      'toneMapped': false,
    });
    sunOccluder = three.Mesh(sunGeometry, sunOcclusionMaterial); // <-- ADDED
    sunOccluder.position.copy(sun.position); // <-- ADDED
    godraysScene.add(sunOccluder);
  }
}
