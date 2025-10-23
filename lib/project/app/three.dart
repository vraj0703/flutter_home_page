/*
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:three_dart/three3d/core/object_3d.dart';
import 'package:three_dart/three3d/objects/mesh.dart';
import 'package:three_dart/three3d/scenes/scene.dart' as three;

class EarthPlanet extends StatefulWidget {
  EarthPlanet({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _EarthPlanetState createState() => _EarthPlanetState();
}

class _EarthPlanetState extends State<EarthPlanet>
    with SingleTickerProviderStateMixin {
  late three.Scene _scene;
  Object3D? _earth;
  late Object3D _stars;
  late Object3D _sun;
  late AnimationController _controller;

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

  void createColoredSphereObject(
      Object parent,
      String name,
      double radius,
      int widthSegments,
      int heightSegments,
      bool backfaceCulling,
      Color color,
      ) async {
    final Mesh mesh = await generateSphereMesh(
      radius: radius,
      latSegments: heightSegments,
      lonSegments: widthSegments,
      color: color,
    );
    parent.add(
      Object(
        name: name,
        mesh: mesh,
        backfaceCulling: backfaceCulling,
        lighting: true,
      ),
    );
    _scene.update();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _scene.camera.target.x = 1.3;
    _scene.camera.target.y = 32;
    _scene.camera.target.z = 32;
    _scene.camera.zoom = 1;
    _scene.camera.far = 2e3;
    //_scene.camera.far =

    // model from https://free3d.com/3d-model/planet-earth-99065.html
    // _earth = Object(name: 'earth', scale: Vector3(10.0, 10.0, 10.0), backfaceCulling: true, fileName: 'assets/earth/earth.obj');

    // create by code
    _earth = Object(name: 'earth', position: Vector3(1.3, 32, 32));
    generateSphereObject(
      _earth!,
      'surface',
      16,
      64,
      64,
      true,
      'assets/planet.jpg',
    );
    _scene.world.add(_earth!);

    // texture from https://www.solarsystemscope.com/textures/
    _stars = Object(name: 'stars', position: Vector3(0, 0, 6));
    generateSphereObject(
      _stars,
      'surface',
      500,
      40,
      40,
      false,
      'assets/stars.jpg',
    );
    _scene.world.add(_stars);

    _sun = Object(
      name: 'sun',
      backfaceCulling: false,
      position: Vector3(0, 100, 150),
    );
    // Using the new createColoredSphereObject
    generateSphereObject(
      _sun,
      'surface',
      48,
      40,
      40,
      false,
      'assets/sun.jpg',
    ); // NEW: Using a bright yellow color
    _scene.world.add(_sun);
  }

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(
      duration: Duration(milliseconds: 120000),
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
            _scene.camera.position.x += pointerSignal.scrollDelta.dx * 0.05;
            _scene.camera.position.y += pointerSignal.scrollDelta.dy * 0.05;
            _scene.camera.position.z += pointerSignal.scrollDelta.dy * 0.05;
            _scene
                .update(); // Important: update the scene after changing a property
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
  String? texturePath,
  Color? color,
}) async {
  int count = (latSegments + 1) * (lonSegments + 1);
  List<Vector3> vertices = List<Vector3>.filled(count, Vector3.zero());
  List<Offset> texcoords = List<Offset>.filled(count, Offset.zero);
  List<Color> colors = List<Color>.filled(count, color ?? Colors.white);
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

  if (texturePath != null) {
    ui.Image? texture = await loadImageFromAsset(texturePath);
    return Mesh(
      vertices: vertices,
      indices: indices,
      texcoords: texcoords,
      texture: texture,
      texturePath: texturePath,
    );
  }

  var material = Material();
  material.ambient = Vector3(1.0, 1.0, 0.0); // Bright yellow base color
  material.diffuse = Vector3.all(0.0); // No reflection of external light
  material.specular = Vector3.all(0.0); // No specular highlights
  material.ke = Vector3(1.0, 1.0, 0.0); // Emits bright yellow light
  material.tf = Vector3.zero();
  material.mapKa = '';
  material.mapKd = '';
  material.mapKe = '';
  material.shininess = 0;
  material.ni = 0;
  material.opacity = 1.0;
  material.illum = 0;
  var mesh = Mesh(
    vertices: vertices,
    indices: indices,
    material: material,
    colors: colors,
  );
  return mesh;
}
*/
