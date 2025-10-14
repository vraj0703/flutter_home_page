import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:three_dart/three3d/lights/light.dart';
import 'package:three_dart/three3d/lights/point_light.dart';

class EarthPlanet extends StatefulWidget {
  EarthPlanet({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _EarthPlanetState createState() => _EarthPlanetState();
}

class _EarthPlanetState extends State<EarthPlanet>
    with SingleTickerProviderStateMixin {
  late Scene _scene;
  Object? _earth;
  late Object _stars;
  late PointLight _light;
  late AnimationController _controller;
  final double _maxScroll = 3000.0;

  void generateSphereObject(
    Object parent,
    String name,
    double radius,
    int widthSegments,
    int heightSegments,
    bool backfaceCulling,
    String texturePath,
  ) async {
    final Mesh mesh = await generateSphereMesh(
      radius: radius,
      latSegments: heightSegments,
      lonSegments: widthSegments,
      texturePath: texturePath,
    );
    parent.add(
      Object(name: name, mesh: mesh, backfaceCulling: backfaceCulling),
    );
    _scene.updateTexture();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _scene.camera.position.z = 16;

    // model from https://free3d.com/3d-model/planet-earth-99065.html
    // _earth = Object(name: 'earth', scale: Vector3(10.0, 10.0, 10.0), backfaceCulling: true, fileName: 'assets/earth/earth.obj')
    _scene.light.position.setFrom(Vector3(10, 10, 10));

    // create by code
    _earth = Object(name: 'earth');
    generateSphereObject(
      _earth!,
      'surface',
      1.3,
      32,
      32,
      true,
      'assets/planet.jpg',
    );
    _scene.world.add(_earth!);

    // texture from https://www.solarsystemscope.com/textures/
    _stars = Object(name: 'stars');
    generateSphereObject(
      _stars,
      'surface',
      500,
      16,
      16,
      false,
      'assets/stars.jpg',
    );
    _scene.world.add(_stars);
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            duration: Duration(milliseconds: 30000),
            vsync: this,
          )
          ..addListener(() {
            if (_earth != null) {
              _earth!.rotation.y = _controller.value * 360;
              _earth!.updateTransform();
              _scene.update();
            }
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            // Adjust camera z position based on scroll delta
            // _scene.camera.position.z += pointerSignal.scrollDelta.dy * 0.05;
            //_scene.update(); // Important: update the scene after changing a property

            if (_earth == null) return;

            // Calculate scroll progress from 0.0 to 1.0
            final scrollProgress = (pointerSignal.scrollDelta.dy).clamp(
              0.0,
              1.0,
            );

            // Animate planet scale: grows from 1x to 6x
            final newScale = 1.0 + scrollProgress * 5.0;
            _earth!.scale.setValues(newScale, newScale, newScale);

            // Animate planet rotation on Y-axis
            _earth!.rotation.y =
                scrollProgress * 360 * 1.5; // flutter_cube uses degrees

            /* // Animate light (sun) position in an arc
              final sunAngle = (scrollProgress * 2.2 * math.pi) - (math.pi / 1.5);
              _light.position.x = math.cos(sunAngle) * 12;
              _light.position.y = math.sin(sunAngle) * 6;
              _light.position.z = math.sin(sunAngle) * 12;*/

            _earth!.updateTransform();
            //_light.updateTransform();
            _scene.update();
          }
        },
        child: Cube(onSceneCreated: _onSceneCreated),
      ),
    );
  }
}

Future<Mesh> generateSphereMesh({
  num radius = 0.5,
  int latSegments = 32,
  int lonSegments = 64,
  required String texturePath,
}) async {
  int count = (latSegments + 1) * (lonSegments + 1);
  List<Vector3> vertices = List<Vector3>.filled(count, Vector3.zero());
  List<Offset> texcoords = List<Offset>.filled(count, Offset.zero);
  List<Polygon> indices = List<Polygon>.filled(
    latSegments * lonSegments * 2,
    Polygon(0, 0, 0),
  );

  int i = 0;
  for (int y = 0; y <= latSegments; ++y) {
    final double v = y / latSegments;
    final double sv = math.sin(v * math.pi);
    final double cv = math.cos(v * math.pi);
    for (int x = 0; x <= lonSegments; ++x) {
      final double u = x / lonSegments;
      vertices[i] = Vector3(
        radius * math.cos(u * math.pi * 2.0) * sv,
        radius * cv,
        radius * math.sin(u * math.pi * 2.0) * sv,
      );
      texcoords[i] = Offset(1.0 - u, 1.0 - v);
      i++;
    }
  }

  i = 0;
  for (int y = 0; y < latSegments; ++y) {
    final int base1 = (lonSegments + 1) * y;
    final int base2 = (lonSegments + 1) * (y + 1);
    for (int x = 0; x < lonSegments; ++x) {
      indices[i++] = Polygon(base1 + x, base1 + x + 1, base2 + x);
      indices[i++] = Polygon(base1 + x + 1, base2 + x + 1, base2 + x);
    }
  }

  ui.Image texture = await loadImageFromAsset(texturePath);
  final Mesh mesh = Mesh(
    vertices: vertices,
    texcoords: texcoords,
    indices: indices,
    texture: texture,
    texturePath: texturePath,
  );
  return mesh;
}
