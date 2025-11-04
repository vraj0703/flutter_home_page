import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

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
  late three.MeshStandardMaterial myNameTextMaterial; // <-- Back to Standard

  // --- ADD/UPDATE THESE ---
  late three.Texture myNameTexture; // For your 'diffuse.jpg'
  late three.Texture myNameNormalMap;
  late three.Texture myNameRoughnessMap; // From 'glossiness.png'
  late three.Texture myNameAlphaMap; // From 'opacity.png'

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
    on<Resize>(_onResize);
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
    await _addMyName();
    var sunGeometry = await _addSun();
    var planetGeometry = await _addPlanet();
    _addStarField();
    _addOccluders(planetGeometry, sunGeometry);
    _initPostProcessing();
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    emit(SpaceLoaded());
  }

  FutureOr<void> _onResize(Resize event, Emitter<SpaceState> emit) async {
    if (state is! SpaceLoaded) return; // Don't resize if not loaded

    log('[3D Debug] Resizing...', name: 'SpaceBloc');

    screenSize = event.newSize;
    width = screenSize.width;
    height = screenSize.height;
    // You might need to re-check DPR, but size is the main thing
    var dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    // 1. Update Camera
    camera.aspect = width / height;
    camera.updateProjectionMatrix();

    // 2. Update Renderer
    renderer?.setSize(width, height, false);

    // 3. Update Composers
    final size = renderer!.getSize(three.Vector2(0, 0));
    final composerSize = three.Vector2(size.width * dpr, size.height * dpr);
    final fAspect = (size.width * dpr) / (size.height * dpr);

    composer.setSize(composerSize.width.toInt(), composerSize.height.toInt());
    godraysComposer.setSize(
      composerSize.width.toInt(),
      composerSize.height.toInt(),
    );
    bloomPass.setSize(composerSize.width.toInt(), composerSize.height.toInt());

    // 4. Update Shader Uniforms
    godRayGeneratePass.uniforms['fAspect']['value'] = fAspect;
  }

  // This is your new "game loop" entry point
  void _onFrame(Duration timeStamp) {
    if (disposed) return;

    _updateAndRender(); // Call your existing animation logic

    // The scheduler will call _onFrame again for the next frame.
    // We don't need to schedule it ourselves.
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

  void _updateAndRender() {
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

    // --- ADD THIS BLOCK (Text Animation) ---
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
    //SchedulerBinding.instance.cancelFrameCallbackWithId(_onFrame);
    disposed = true;

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
    //composer.dispose();
    //godraysComposer.dispose();
    bloomPass.dispose();
    //godRayGeneratePass.dispose();
    //godRayCombinePass.dispose();
    // The render passes added to composers are usually disposed by the composer.

    // Dispose Renderer and Plugin
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

  Future<void> _addMyName() async {
    // 1. Load the 3D font
    final font = await three.FontLoader(
      null,
    ).loadAsync('assets/bigblue.json');

    // 2. Load ALL your textures
    // !! Assumes you still have diffuse.jpg for color !!
    myNameTexture = await loader.loadAsync("assets/decal_opacity.png");
    myNameNormalMap = await loader.loadAsync("assets/decal_normal.png");
    myNameRoughnessMap = await loader.loadAsync("assets/decal_glossiness.png");

    // 3. Create the Text Geometry
    final textGeometry = three.TextGeometry('Vishal Raj', {
      "font": font,
      "size": 12,
      "height": 0.2,
      "curveSegments": 12,
    });

    // 4. Center the Geometry
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

    // 5. --- NEW: BEND THE GEOMETRY (Ellipsoidal) ---
    // This version adds curveRadiusZ as a depth multiplier

    // Tweak these radii: Larger = less curve
    final curveRadiusX = 50.0; // Horizontal curve
    final curveRadiusY = 150.0;  // Vertical curve
    final curveRadiusZ = 2.0;   // <-- NEW: Depth multiplier. 1.0 = normal

    final position = textGeometry.attributes['position'];
    final vertex = three.Vector3(0, 0, 0);

    for (int i = 0; i < position.count; i++) {
      vertex.fromBufferAttribute(position, i); // Get vertex (x, y, z)

      // Calculate angles for X and Y
      final angleX = vertex.x / curveRadiusX;
      final angleY = vertex.y / curveRadiusY;

      // --- FIX: Calculate newX AND newY ---
      final newX = math.sin(angleX) * curveRadiusX;
      final newY = math.sin(angleY) * curveRadiusY; // <-- This creates the Y-bend

      // Calculate the new Z depth from both curves
      final zDepth = (1 - math.cos(angleX)) * curveRadiusX +
          (1 - math.cos(angleY)) * curveRadiusY;

      // Apply the new Z-depth multiplier
      final newZ = zDepth * curveRadiusZ;

      // Set the new, curved position
      position.setXYZ(i, newX, newY, newZ); // <-- Use newY here
    }

    // We changed the vertices, so we must re-calculate the normals
    textGeometry.computeVertexNormals();

    // 5. Create the new PBR material
    myNameTextMaterial = three.MeshStandardMaterial({
      'map': myNameTexture,
      'normalMap': myNameNormalMap,
      'roughnessMap': myNameRoughnessMap,
      'transparent': true, // <-- Still needed for the 'opacity' fade animation
      'opacity': 0.0,
      'metalness': 0.7,
    });
    // 6. Create the final Mesh object
    myNameText = three.Mesh(textGeometry, myNameTextMaterial);

    // 7. Set its static position
    myNameText.position.set(0, 200, 150);

    // 9. ADD 3 SpotLights (Adjusted for curve)

    // Common settings
    final double intensity = 8.0;
    final double distance = 50.0;
    final double angle = math.pi / 2.2;
    final double penumbra = 0.8;
    final double decay = 1.0;

    // Light 1: Bottom Center
    final lightCenter = three.SpotLight(
        0xffffff, intensity, distance, angle, penumbra, decay);
    // Position: Moved CLOSER to light the "deep" center
    lightCenter.position.set(0, -25, 15); // <-- z was 20
    myNameText.add(lightCenter);

    // Light 2: Bottom Left
    final lightLeft = three.SpotLight(
        0xffffff, intensity, distance, angle, penumbra, decay);
    // Position: Moved FURTHER to light the "shallow" edge
    lightLeft.position.set(-20, -20, 25); // <-- z was 20
    myNameText.add(lightLeft);

    // Light 3: Bottom Right
    final lightRight = three.SpotLight(
        0xffffff, intensity, distance, angle, penumbra, decay);
    // Position: Moved FURTHER to light the "shallow" edge
    lightRight.position.set(20, -20, 25); // <-- z was 20
    myNameText.add(lightRight);

    // --- Aim the lights (no change needed here) ---
    myNameText.add(lightCenter.target!);
    lightLeft.target!.position.set(-20, 0, 0);
    myNameText.add(lightLeft.target!);
    lightRight.target!.position.set(20, 0, 0);
    myNameText.add(lightRight.target!);

    scene.add(myNameText);
  }
}
