import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_dart/three3d/loaders/index.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:flutter_gl/flutter_gl.dart';

class Earth1Planet extends StatefulWidget {
  const Earth1Planet({Key? key}) : super(key: key);

  @override
  _EarthPlanetState createState() => _EarthPlanetState();
}

class _EarthPlanetState extends State<Earth1Planet>
    with SingleTickerProviderStateMixin {
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

  // Constants for camera path calculation
  final double _baseRadius = 6.0;
  final double _spiralTightness = 40.0;

  @override
  void initState() {
    super.initState();
    manager = three.LoadingManager();
    _scrollController = ScrollController()
      ..addListener(() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        setState(() {
          _scrollProgress = maxScroll > 0 ? currentScroll / maxScroll : 0;
        });
      });

    _animationController =
        AnimationController(
            vsync: this,
            duration: const Duration(days: 99), // Effectively infinite
          )
          ..addListener(() {
            _animate();
          })
          ..repeat();
  }

  void _onRendererCreated() {
    // Manually create the renderer, scene, and camera as per three_dart documentation
    renderer = three.WebGLRenderer({
      'antialias': true,
      'alpha': true,
      'texture': flutterGlPlugin.textureId,
      'width':flutterGlPlugin.openGL.width,
      'height':flutterGlPlugin.openGL.height
    });
    renderer.setSize(flutterGlPlugin.openGL.width, flutterGlPlugin.openGL.height);
    renderer.setPixelRatio(flutterGlPlugin.openGL.dpr);
    renderer.setClearColor(three.Color.fromHex(0x000000), 0);

    scene = three.Scene();
    camera = three.PerspectiveCamera(
      75,
      flutterGlPlugin.openGL.width / flutterGlPlugin.openGL.height,
      0.1,
      2000,
    );

    // Set initial camera position
    camera.position.copy(_calculateCameraPosition(0.0));
    camera.lookAt(three.Vector3(0, 0, 0));

    // Add lighting
    scene.add(three.AmbientLight(0xffffff, 0.01));
    scene.add(three.DirectionalLight(0xffffff, 5)..position.set(0, 100, 150));

    // Create Earth mesh
    TextureLoader(manager).load('assets/planet.jpg', (texture) {
      _earth = three.Mesh(
        three.SphereGeometry(1.3, 64, 64),
        three.MeshBasicMaterial({'map': texture}),
      );
      _earth!.name = 'earth';
      scene.add(_earth!);
    });

    // Create stars background
    TextureLoader(manager).load('assets/stars.jpg', (texture) {
      _stars = three.Mesh(
        three.SphereGeometry(500, 64, 64),
        three.MeshBasicMaterial({'map': texture, 'side': three.BackSide}),
      );
      _stars?.name = 'stars';
      scene.add(_stars!);
    });
  }

  void _animate() {
    if (_earth == null) return;
    if (_stars == null) return;
    if (!mounted || !flutterGlPlugin.isInitialized) return;

    // Earth rotation
    _earth!.rotation.y += 0.001;

    // Calculate target camera position based on scroll progress
    final targetPosition = _calculateCameraPosition(_scrollProgress);

    // Calculate camera's local axes for parallax effect
    final lookDirection = three.Vector3()
      ..copy(targetPosition)
      ..normalize();
    final cameraRight = three.Vector3(0, 1, 0).cross(lookDirection).normalize();
    final cameraUp = three.Vector3()
      ..copy(lookDirection)
      ..cross(cameraRight)
      ..normalize();

    // Apply parallax offset based on pointer position
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

    // Smoothly interpolate the camera's position (lerp)
    camera.position.lerp(finalTargetPosition, 0.05);

    // Always look at the scene's origin
    camera.lookAt(three.Vector3(0, 0, 0));

    // Render the scene
    renderer.render(scene, camera);
    flutterGlPlugin.updateTexture(renderer.textures);
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
          // Initialize flutter_gl plugin with the available screen size
          flutterGlPlugin = FlutterGlPlugin();
          flutterGlPlugin
              .initialize(
                options: {
                  "width": constraints.maxWidth.toInt(),
                  "height": constraints.maxHeight.toInt(),
                  "dpr": MediaQuery.of(context).devicePixelRatio,
                },
              )
              .then((_) {
                _onRendererCreated();
              });

          return Stack(
            children: [
              // The Texture widget that displays the three_dart canvas
              if (flutterGlPlugin.isInitialized)
                Texture(textureId: flutterGlPlugin.textureId!),

              // Listener for pointer movement
              Listener(
                onPointerMove: (event) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    _pointerPosition = Offset(
                      (event.position.dx - size.width / 2) / (size.width / 2),
                      -(event.position.dy - size.height / 2) /
                          (size.height / 2),
                    );
                  });
                },
                child: Container(color: Colors.transparent),
              ),

              // The invisible scroll view
              SingleChildScrollView(
                controller: _scrollController,
                child: const SizedBox(height: 5000), // Controls scroll length
              ),
            ],
          );
        },
      ),
    );
  }
}
