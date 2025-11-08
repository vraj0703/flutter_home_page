import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

import 'bloom_pass.dart';
import 'effect_composer.dart';
import 'god_rays.dart';
import 'helper.dart';

part 'space_event.dart';

part 'space_state.dart';

class SpaceBloc extends Bloc<SpaceEvent, SpaceState> {
  static const int LAYER_SCENE = 0;
  static const int LAYER_TEXT = 1;

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

  late three.Mesh myNameText;
  late three.MeshStandardMaterial myNameTextMaterial;
  late three.Texture myNameNormalMap;
  late three.Font _font;

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
  final _sunPosition = three.Vector3();
  final _sunScreenPos = three.Vector2();

  bool disposed = false;
  final scrollNotifier = ValueNotifier<double>(0.0);
  late final AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;

  SpaceBloc() : super(SpaceInitial()) {
    on<Initialize>(_initialize);
    on<Load>(_load);
    on<Scroll>(_onScroll);
    on<Resize>(_onResize);
  }

  FutureOr<void> _initialize(Initialize event, Emitter<SpaceState> emit) async {
    log('[3D Debug] _initialize', name: 'SpaceBloc');
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    screenSize = event.screenSize;
    width = screenSize.width;
    height = screenSize.height;
    dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    await Future.delayed(Duration.zero);
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
    if (!_isAudioPlaying && state is SpaceLoaded) {
      // User has interacted, so we can now safely play audio
      _audioPlayer.play(AssetSource('audio/space_ambient.mp3'));
      _isAudioPlaying = true; // Set flag so this only runs once
    }
    _scrollTarget += event.scrollDelta * 0.0005;
    _scrollTarget = _scrollTarget.clamp(0.0, 1.0);
  }

  FutureOr<void> _load(Load event, Emitter<SpaceState> emit) async {
    log('[3D Debug] _load', name: 'SpaceBloc');
    final stopwatch = Stopwatch();

    // --- Stage 1: Init & Load Assets ---
    stopwatch.start();
    emit(SpaceLoading("Initializing renderer..."));
    await Future.delayed(Duration.zero);
    await _initRenderer();
    log(
      '[3D Debug] ⏱️ _initRenderer took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'SpaceBloc',
    );
    stopwatch.reset();

    scene = three.Scene();
    godraysScene = three.Scene();
    _initCamera();
    _addLights();

    emit(SpaceLoading("Loading assets..."));
    // Load ALL assets in parallel
    await Future.wait([
      _addBackground(),
      Future.microtask(() async {
        _font = await three.FontLoader(
          null,
        ).loadAsync('assets/fonts/pixel_code.json');
      }),
      loader
          .loadAsync("assets/decal_normal.png")
          .then((map) => myNameNormalMap = map),
    ]);
    var sunGeometry = await _addSun();
    var planetGeometry = await _addPlanet();

    // --- Stage 2: Build Starfield (Uses Isolate) ---
    emit(SpaceLoading("Generating starfield..."));
    stopwatch.start();
    final starfieldData = await compute(computeStarfieldData, {
      'count': 500,
      'radius': 450.0,
    });
    _addStarField(starfieldData);
    log(
      '[3D Debug] ⏱️ Starfield (compute + build) took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'SpaceBloc',
    );
    stopwatch.reset();

    // --- Stage 3: Build Text ---
    emit(SpaceLoading("Creating 3D text..."));
    await Future.delayed(Duration.zero); // Let UI update

    stopwatch.start();
    final textGeometry = await _createMyNameGeometry();
    emit(SpaceLoading("Bending text geometry..."));
    log(
      '[3D Debug] ⏱️ _createMyNameGeometry took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'SpaceBloc',
    );
    stopwatch.reset();

    await Future.delayed(Duration.zero); // Let UI update
    stopwatch.start();
    final bentGeometry = await _bendMyNameGeometry(textGeometry);
    log(
      '[3D Debug] ⏱️ _bendMyNameGeometry took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'SpaceBloc',
    );
    stopwatch.reset();

    _attachMyNameMesh(bentGeometry); // This is fast

    // --- Stage 4: Scene & Shaders ---
    emit(SpaceLoading("Assembling scene..."));
    await Future.delayed(Duration.zero);
    _addOccluders(planetGeometry, sunGeometry);

    emit(SpaceLoading("Compiling shaders..."));
    stopwatch.start();
    await _initPostProcessing();
    log(
      '[3D Debug] ⏱️ _initPostProcessing (TOTAL) took: ${stopwatch.elapsedMilliseconds}ms',
      name: 'SpaceBloc',
    );
    stopwatch.reset();

    // Done
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    emit(SpaceLoaded(screenSize: screenSize, three3dRender: three3dRender));
  }

  FutureOr<void> _onResize(Resize event, Emitter<SpaceState> emit) async {
    if (state is! SpaceLoaded) return; // Don't resize if not loaded

    log('[3D Debug] Resizing...', name: 'SpaceBloc');

    screenSize = event.newSize;
    width = screenSize.width;
    height = screenSize.height;
    dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    if (width <= 0 || height <= 0) {
      log('[3D Debug] Invalid resize dimensions, skipping.', name: 'SpaceBloc');
      return;
    }

    camera.aspect = width / height;
    camera.updateProjectionMatrix();

    renderer?.setPixelRatio(dpr);
    renderer?.setSize(width, height, false);

    composer.setPixelRatio(dpr);
    composer.setSize(width.toInt(), height.toInt());

    godraysComposer.setPixelRatio(dpr);
    godraysComposer.setSize(width.toInt(), height.toInt());
    bloomPass.setSize(width.toInt(), height.toInt());

    final physicalWidth = (width * dpr).toInt();
    final physicalHeight = (height * dpr).toInt();
    final fAspect = physicalWidth / physicalHeight;

    three3dRender.element.width = physicalWidth;
    three3dRender.element.height = physicalHeight;

    godRayGeneratePass.uniforms['fAspect']['value'] = fAspect;
  }

  void _onFrame(Duration timeStamp) {
    if (disposed) return;
    _updateAndRender();
  }

  Future<void> _initPostProcessing() async {
    try {
      final stopwatch = Stopwatch();
      final size = renderer!.getSize(three.Vector2(0, 0));
      final dpr = renderer!.getPixelRatio();
      final composerSize = three.Vector2(size.width * dpr, size.height * dpr);
      final fAspect = (size.width * dpr) / (size.height * dpr);

      await Future.delayed(Duration.zero); // Yield before first heavy pass
      stopwatch.start();
      composer = EffectComposer1(renderer!, null);
      final renderPass = three_jsm.RenderPass(scene, camera, null, null, null);
      renderPass.clear = true;
      await composer.addPass(renderPass);
      log(
        '[3D Debug] ⏱️   - Pass: Render took: ${stopwatch.elapsedMilliseconds}ms',
        name: 'SpaceBloc',
      );
      stopwatch.reset();

      await Future.delayed(Duration.zero); // Yield before bloom
      stopwatch.start();
      bloomPass = UnrealBloomPass1(composerSize, 2, 1, 0.7);
      await composer.addPass(bloomPass);
      log(
        '[3D Debug] ⏱️   - Pass: Bloom took: ${stopwatch.elapsedMilliseconds}ms',
        name: 'SpaceBloc',
      );
      stopwatch.reset();

      await Future.delayed(Duration.zero); // Yield before godrays composer
      stopwatch.start();
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
      await godraysComposer.addPass(godraysMaskPass);
      log(
        '[3D Debug] ⏱️   - Pass: Godrays Mask took: ${stopwatch.elapsedMilliseconds}ms',
        name: 'SpaceBloc',
      );
      stopwatch.reset();

      await Future.delayed(Duration.zero); // Yield before shader 1
      stopwatch.start();
      godRayGeneratePass = three_jsm.ShaderPass(
        godRaysGenerateShader,
        'tDiffuse',
      );
      godRayGeneratePass.uniforms['fAspect']['value'] = fAspect;
      godRayGeneratePass.needsSwap = false;
      await godraysComposer.addPass(godRayGeneratePass);
      log(
        '[3D Debug] ⏱️   - Pass: Godrays Generate took: ${stopwatch.elapsedMilliseconds}ms',
        name: 'SpaceBloc',
      );
      stopwatch.reset();

      await Future.delayed(Duration.zero); // Yield before shader 2
      stopwatch.start();
      godRayCombinePass = three_jsm.ShaderPass(
        godRaysCombineShader,
        'tDiffuse',
      );
      godRayCombinePass.uniforms['tGodRays']['value'] =
          godraysComposer.renderTarget1.texture;
      godRayCombinePass.renderToScreen = true;
      await composer.addPass(godRayCombinePass);
      log(
        '[3D Debug] ⏱️   - Pass: Godrays Combine took: ${stopwatch.elapsedMilliseconds}ms',
        name: 'SpaceBloc',
      );
      stopwatch.reset();
    } on Exception catch (e) {
      print('[3D Debug] _initPostProcessing: $e');
    }
  }

  Future<three.BufferGeometry> _createMyNameGeometry() async {
    final textGeometry = three.TextGeometry('Vishal Raj', {
      "font": _font,
      "size": 15,
      "height": 5,
      "curveSegments": 40,
    });

    // Center the Geometry
    await Future.microtask(() {
      textGeometry.computeBoundingBox();
      final centerOffset = three.Vector3(
        (textGeometry.boundingBox!.max.x - textGeometry.boundingBox!.min.x) *
            -0.5,
        (textGeometry.boundingBox!.max.y - textGeometry.boundingBox!.min.y) *
            -0.5,
        (textGeometry.boundingBox!.max.z - textGeometry.boundingBox!.min.z) *
            -0.5,
      );
      textGeometry.translate(centerOffset.x, centerOffset.y, centerOffset.z);
    });
    return textGeometry;
  }

  Future<three.BufferGeometry> _bendMyNameGeometry(
    three.BufferGeometry textGeometry,
  ) async {
    // 1. Get the position attribute
    final positionAttribute =
        textGeometry.attributes['position'] as three.Float32BufferAttribute;

    // 2. Call compute() with the raw data
    final bentPositions = await compute(_computeBending, {
      'positions': positionAttribute.array, // Send the Float32Array
      'curveRadiusX': 200.0,
      'curveRadiusY': 150.0,
      'curveRadiusZ': 4.0,
    });

    // 3. Update the geometry's attribute with the new data (fast)
    textGeometry.setAttribute(
      'position',
      three.Float32BufferAttribute(bentPositions, 3),
    );

    // 4. Run computeVertexNormals()
    // This is now much faster because it's the only sync work.
    await Future.microtask(() {
      textGeometry.computeVertexNormals();
    });
    return textGeometry;
  }

  Float32Array _computeBending(Map<String, dynamic> params) {
    // 1. Unpack parameters
    final Float32Array positions = params['positions'];
    final double curveRadiusX = params['curveRadiusX'];
    final double curveRadiusY = params['curveRadiusY'];
    final double curveRadiusZ = params['curveRadiusZ'];

    // 2. Perform the heavy for-loop math
    for (int i = 0; i < positions.length ~/ 3; i++) {
      final i3 = i * 3;
      final double x = positions[i3];
      final double y = positions[i3 + 1];
      // We don't need z from the original position

      final angleX = x / curveRadiusX;
      final angleY = y / curveRadiusY;

      final newX = math.sin(angleX) * curveRadiusX;
      final newY = math.sin(angleY) * curveRadiusY;

      final zDepth =
          (1 - math.cos(angleX)) * curveRadiusX +
          (1 - math.cos(angleY)) * curveRadiusY;

      final newZ = zDepth * curveRadiusZ;

      // 3. Update the array
      positions[i3] = newX;
      positions[i3 + 1] = newY;
      positions[i3 + 2] = newZ;
    }

    // 4. Return the modified array
    return positions;
  }

  void _attachMyNameMesh(three.BufferGeometry textGeometry) {
    myNameTextMaterial = three.MeshStandardMaterial({
      'alphaMap': myNameNormalMap,
      'transparent': true,
      'opacity': 0.0,
      'emissive': 0xFFFFFF,
    });

    myNameText = three.Mesh(textGeometry, myNameTextMaterial);
    myNameText.position.set(0, 200, 150);

    scene.add(myNameText);
  }

  void _updateAndRender() {
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

    double textProgress;
    final scrollValue = _scrollCurrent;

    if (scrollValue < 0.2) {
      textProgress = 0.0;
    } else if (scrollValue <= 0.5) {
      // Fade IN: 0.2 -> 0.5
      textProgress = ((scrollValue - 0.2) / 0.3).clamp(0.0, 1.0);
    } else if (scrollValue <= 0.7) {
      // Fade OUT: 0.5 -> 0.7
      textProgress = (1.0 - ((scrollValue - 0.5) / 0.2)).clamp(0.0, 1.0);
    } else {
      textProgress = 0.0;
    }

    // Apply the progress to opacity and scale
    myNameText.material.opacity = textProgress;
    myNameText.scale.set(textProgress, textProgress, textProgress);

    // Make the 3D text always face the camera
    myNameText.lookAt(camera.position);

    // Update the sun's screen-space position for the God Rays shader
    _sunPosition.copy(sun.position);
    _sunPosition.project(camera);

    _sunScreenPos.set((_sunPosition.x + 1) / 2, (_sunPosition.y + 1) / 2);
    // Update the uniform in the generate pass
    godRayGeneratePass.uniforms['vSunPositionScreen']['value'] = _sunScreenPos;
    godRayGeneratePass.uniforms['fTime']['value'] = elapsedTime;

    // --- Render ---
    godraysComposer.render(delta);
    composer.render(delta);
  }

  @override
  Future<void> close() {
    dispose();
    return super.close();
  }

  void dispose() {
    disposed = true;

    _audioPlayer.stop();
    _audioPlayer.dispose();
    // Dispose Notifier
    scrollNotifier.dispose();

    // Dispose Geometries
    planet.geometry?.dispose();
    sun.geometry?.dispose();
    backgroundSphere.geometry?.dispose();
    stars.geometry?.dispose();
    myNameText.geometry?.dispose();
    // occluder and sunOccluder share geometry, so they are already covered.

    // Dispose Materials
    planet.material?.dispose();
    sun.material?.dispose();
    backgroundSphere.material?.dispose();
    stars.material?.dispose();
    myNameText.material?.dispose();
    occluder.material?.dispose();
    sunOccluder.material?.dispose();

    // Dispose Textures (if you have references to them)
    // The loader caches textures, but if you have a direct reference:
    // (await loader.loadAsync("..."))
    // You should dispose them.
    // e.g., (backgroundSphere.material as three.MeshBasicMaterial).map?.dispose();
    // (planet.material as three.MeshStandardMaterial).map?.dispose();

    // Dispose Post-Processing
    composer.renderer.dispose();
    godraysComposer.renderer.dispose();
    bloomPass.dispose();
    godRayGeneratePass.material.dispose();
    godRayGeneratePass.scene.dispose();
    godRayCombinePass.material.dispose();
    // The render passes added to composers are usually disposed by the composer.

    // Dispose Renderer and Plugin
    renderer?.dispose();
    three3dRender.dispose();
  }

  Future<void> _initRenderer() async {
    await Future.microtask(() {
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
    });
  }

  _initCamera() {
    camera = three.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.set(0, 0, 6);
    camera.layers.enableAll();
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
    backgroundSphere.layers.set(LAYER_SCENE);
    backgroundSphere.quaternion.set(-0.2, -0.5, 0.9, 0.4);
    scene.add(backgroundSphere);
  }

  _addLights() {
    ambientLight = three.AmbientLight(0xffffff, 0.05);
    ambientLight.layers.set(LAYER_SCENE);
    scene.add(ambientLight);

    directionalLight = three.DirectionalLight(0xffffff, 1);
    directionalLight.position.set(0, 100, 150);
    directionalLight.layers.set(LAYER_SCENE);
    scene.add(directionalLight);
  }

  Future<three.SphereGeometry> _addSun() async {
    final sunGeometry = three.SphereGeometry(13, 80, 80);
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
    sun.layers.set(LAYER_SCENE);
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
    planet.layers.set(LAYER_SCENE);
    scene.add(planet);
    return planetGeometry;
  }

  _addStarField(starfieldData) {
    final starGeometry = three.BufferGeometry();
    starGeometry.setAttribute(
      'position',
      three.Float32BufferAttribute(starfieldData, 3),
    );

    final starMaterial = three.PointsMaterial({
      'color': 0xffffff,
      'size': 1.0,
      'sizeAttenuation': true,
      'blending': three.AdditiveBlending,
      'transparent': true,
      'depthWrite': false,
    });

    stars = three.Points(starGeometry, starMaterial);
    stars.layers.set(LAYER_SCENE);
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
