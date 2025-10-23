import 'dart:developer'; // Import the developer log
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_dart/three3d/loaders/index.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:flutter_gl/flutter_gl.dart';
import 'dart:async'; // Import for Completer

class Earth1Planet extends StatefulWidget {
  const Earth1Planet({Key? key}) : super(key: key);

  @override
  _EarthPlanetState createState() => _EarthPlanetState();
}

class _EarthPlanetState extends State<Earth1Planet>
    with SingleTickerProviderStateMixin {
  final Completer<void> _initCompleter = Completer<void>();
  bool _isRenderLoopActive = false;

  late FlutterGlPlugin flutterGlPlugin;
  late three.WebGLRenderer renderer;
  late three.Scene scene;
  late three.PerspectiveCamera camera;
  late three.LoadingManager manager;

  three.Object3D? _earth;
  three.Object3D? _stars;
  late AnimationController _animationController;
  late ScrollController _scrollController;

  double _scrollProgress = 0.0;
  Offset _pointerPosition = Offset.zero;

  final double _baseRadius = 6.0;
  final double _spiralTightness = 40.0;

  @override
  void initState() {
    super.initState();
    log(
      '[3D Debug] initState: Initializing state and controllers.',
      name: 'Earth1',
    );
    flutterGlPlugin = FlutterGlPlugin();

    // Add logging to the LoadingManager to see if textures load
    manager = three.LoadingManager(
      (url, itemsLoaded, itemsTotal) {
        log(
          '[3D Debug] LoadingManager.onLoad: All textures loaded.',
          name: 'Earth1',
        );
      },
      (url, itemsLoaded, itemsTotal) {
        log(
          '[3D Debug] LoadingManager.onProgress: Loading $url. Loaded $itemsLoaded of $itemsTotal.',
          name: 'Earth1',
        );
      },
      (url) {
        log(
          '[3D Debug] LoadingManager.onError: Error loading $url.',
          name: 'Earth1',
        );
      },
    );

    _scrollController = ScrollController()
      ..addListener(() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        setState(() {
          _scrollProgress = maxScroll > 0 ? currentScroll / maxScroll : 0;
        });
      });

    _animationController =
        AnimationController(vsync: this, duration: const Duration(days: 99))
          ..addListener(() {
            _animate();
          })
          ..repeat();
  }

  Future<void> _initialize(
    BuildContext context,
    BoxConstraints constraints,
  ) async {
    if (_initCompleter.isCompleted) return;
    log(
      '[3D Debug] _initialize: Starting renderer initialization.',
      name: 'Earth1',
    );

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    await flutterGlPlugin.initialize(
      options: {"width": width.toInt(), "height": height.toInt(), "dpr": dpr},
    );
    log(
      '[3D Debug] _initialize: flutterGlPlugin.initialize() completed.',
      name: 'Earth1',
    );

    while (!flutterGlPlugin.isInitialized) {
      log(
        '[3D Debug] _initialize: Waiting for flutterGlPlugin to be initialized...',
        name: 'Earth1',
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _onRendererCreated(width, height, dpr);

    log(
      '[3D Debug] _initialize: Initialization process complete.',
      name: 'Earth1',
    );
  }

  void _onRendererCreated(double width, double height, double dpr) {
    log(
      '[3D Debug] _onRendererCreated: Creating WebGLRenderer and Scene.',
      name: 'Earth1',
    );
    renderer = three.WebGLRenderer({
      'antialias': true,
      'alpha': true,
      'gl': flutterGlPlugin.gl,
      'width': width,
      'height': height,
    });
    renderer.setPixelRatio(dpr);
    renderer.setSize(width, height);
    renderer.setClearColor(three.Color.fromHex(0x000000), 0);

    scene = three.Scene();
    camera = three.PerspectiveCamera(75, width / height, 0.1, 2000);

    final initialCamPos = _calculateCameraPosition(0.0);
    camera.position.copy(initialCamPos);
    camera.lookAt(three.Vector3(0, 0, 0));
    log(
      '[3D Debug] _onRendererCreated: Camera initialized at position: ${initialCamPos.toArray()}',
      name: 'Earth1',
    );

    scene.add(three.AmbientLight(0xffffff, 0.2));
    scene.add(three.DirectionalLight(0xffffff, 5)..position.set(0, 100, 150));
    log(
      '[3D Debug] _onRendererCreated: Lighting added to scene.',
      name: 'Earth1',
    );

    _initCompleter.complete();
    TextureLoader(manager).load('assets/planet.jpg', (texture) {
      log(
        '[3D Debug] TextureLoader: planet.jpg successfully loaded.',
        name: 'Earth1',
      );
      _earth = three.Mesh(
        three.SphereGeometry(1.3, 64, 64),
        three.MeshStandardMaterial({'map': texture, 'roughness': 0.4}),
      );
      _earth!.name = 'earth';
      scene.add(_earth!);
      log('[3D Debug] SCENE: Earth object added to scene.', name: 'Earth1');
      TextureLoader(manager).load('assets/stars.jpg', (texture) {
        log(
          '[3D Debug] TextureLoader: stars.jpg successfully loaded.',
          name: 'Earth1',
        );
        _stars = three.Mesh(
          three.SphereGeometry(500, 64, 64),
          three.MeshBasicMaterial({'map': texture, 'side': three.BackSide}),
        );
        _stars?.name = 'stars';
        scene.add(_stars!);
        log('[3D Debug] SCENE: Stars object added to scene.', name: 'Earth1');
      });
    });
  }

  void _animate() {
    if (!_initCompleter.isCompleted) return;

    // Log once to confirm the loop is active, then stop.
    if (!_isRenderLoopActive) {
      log('[3D Debug] _animate: Render loop is now active.', name: 'Earth1');
      _isRenderLoopActive = true;
    }

    // Only perform rotation if the earth object has been loaded
    if (_earth != null) {
      _earth!.rotation.y += 0.001;
    } else {
      // Optional: Log if waiting, but only for the first few seconds
      if (_animationController.value < 0.05) {
        // Check for a bit longer
        log(
          '[3D Debug] _animate: Waiting for Earth object to load...',
          name: 'Earth1',
        );
      }
    }

    // Camera logic can run regardless of whether objects are loaded
    final targetPosition = _calculateCameraPosition(_scrollProgress);
    final lookDirection = three.Vector3()
      ..copy(camera.position)
      ..normalize().negate();
    final cameraRight = three.Vector3(0, 1, 0).cross(lookDirection).normalize();
    final cameraUp = three.Vector3()
      ..copy(lookDirection)
      ..cross(cameraRight);

    final parallaxOffsetX = cameraRight.clone().multiplyScalar(
      _pointerPosition.dx * 0.2,
    );
    final parallaxOffsetY = cameraUp.clone().multiplyScalar(
      _pointerPosition.dy * 0.2,
    );
    final finalTargetPosition = targetPosition
        .clone()
        .add(parallaxOffsetX)
        .add(parallaxOffsetY);

    camera.position.lerp(finalTargetPosition, 0.05);
    camera.lookAt(three.Vector3(0, 0, 0));

    // --- ALWAYS RENDER AND UPDATE ---
    // This is the most important change. These lines now run on every frame.
    renderer.render(scene, camera);
    flutterGlPlugin.updateTexture(
      flutterGlPlugin.textureId,
    ); // Corrected from .textures
  }

  three.Vector3 _calculateCameraPosition(double progress) {
    final double angle = math.pi * 2 * progress;
    final double radius = _baseRadius + progress * _spiralTightness;
    final double x = math.sin(angle) * radius;
    final double z = math.cos(angle) * radius;
    final double y = -progress * 34.6;
    return three.Vector3(x, y, z);
  }

  @override
  void dispose() {
    log(
      '[3D Debug] dispose: Disposing controllers and plugin.',
      name: 'Earth1',
    );
    _scrollController.dispose();
    _animationController.dispose();
    flutterGlPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          log('[3D Debug] build: LayoutBuilder running.', name: 'Earth1');
          return FutureBuilder<void>(
            future: _initialize(context, constraints),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  log(
                    '[3D Debug] FutureBuilder: Waiting for _initialize to complete.',
                    name: 'Earth1',
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                log(
                  '[3D Debug] FutureBuilder: FATAL ERROR during initialization: ${snapshot.error}',
                  name: 'Earth1',
                );
                return Center(
                  child: Text("Error initializing renderer: ${snapshot.error}"),
                );
              }

              log(
                '[3D Debug] FutureBuilder: Initialization complete. Building Stack with Texture.',
                name: 'Earth1',
              );
              return Stack(
                children: [
                  Texture(textureId: flutterGlPlugin.textureId!),
                  Listener(
                    onPointerMove: (event) {
                      final size = MediaQuery.of(context).size;
                      setState(() {
                        _pointerPosition = Offset(
                          (event.position.dx - size.width / 2) /
                              (size.width / 2),
                          -(event.position.dy - size.height / 2) /
                              (size.height / 2),
                        );
                      });
                    },
                    child: Container(color: Colors.transparent),
                  ),
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: const SizedBox(height: 5000),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
