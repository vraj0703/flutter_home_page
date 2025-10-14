// import 'dart:math' as math;
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:three_dart/three3d/scenes/scene.dart';
// import 'package:three_dart/three_dart.dart' as three;
//
// void main() {
//   runApp(const PlanetApp());
// }
//
// class PlanetApp extends StatelessWidget {
//   const PlanetApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Planet Scroll Animation',
//       theme: ThemeData.dark(),
//       home: const EarthPlanet(),
//     );
//   }
// }
//
// class EarthPlanet extends StatefulWidget {
//   const EarthPlanet({Key? key}) : super(key: key);
//
//   @override
//   _EarthPlanetState createState() => _EarthPlanetState();
// }
//
// class _EarthPlanetState extends State<EarthPlanet> {
//   late three.Object3D _earth;
//   late three.Object3D _stars;
//   late three.PointLight _light;
//   late Scene _scene;
//
//   double _totalScrollDelta = 0.0;
//   final double _maxScroll = 3000.0;
//
//   void _onThreeJsCreated() {
//     _scene.background = three.Color(0x000000);
//     _scene.camera.position.z = 16;
//
//     // Correctly create a PointLight
//     _light = three.PointLight(0xffffff, 1.5);
//     _light.name = 'light';
//     _scene.add(_light);
//
//     // Create planet from geometry and material
//     final earthGeometry = three.SphereGeometry(1.3, 32, 32);
//     final earthMaterial = three.MeshStandardMaterial({
//       'map': three.TextureLoader().load('assets/planet.jpg'),
//       'roughness': 0.4,
//     });
//     _earth = three.Mesh(earthGeometry, earthMaterial);
//     _earth.name = 'earth';
//     _scene.add(_earth);
//
//     // Create background stars from geometry and material
//     final starsGeometry = three.SphereGeometry(500, 16, 16);
//     final starsMaterial = three.MeshBasicMaterial({
//       'map': three.TextureLoader().load('assets/background.jpg'),
//       'side': three.BackSide,
//     });
//     _stars = three.Mesh(starsGeometry, starsMaterial);
//     _stars.name = 'stars';
//     _stars.rotation.y = math.pi / 2; // Apply rotation from React code
//     _scene.add(_stars);
//
//     _updateAnimation();
//   }
//
//   void _updateAnimation() {
//     if (!three.mounted) return;
//
//     final scrollProgress = (_totalScrollDelta / _maxScroll).clamp(0.0, 1.0);
//
//     // Animate planet scale: grows from 1x to a larger size
//     final newScale = 1.0 + scrollProgress * 10.0;
//     _earth.scale.set(newScale, newScale, newScale);
//
//     // Animate planet rotation on Y-axis
//     _earth.rotation.y = scrollProgress * math.pi * 3;
//
//     // Animate light (sun) position
//     final sunAngle = (scrollProgress * 2.2 * math.pi) - (math.pi / 1.5);
//     _light.position.x = math.cos(sunAngle) * 12;
//     _light.position.y = math.sin(sunAngle) * 6;
//     _light.position.z = math.sin(sunAngle) * 12;
//
//     three.render();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Listener(
//         onPointerSignal: (pointerSignal) {
//           if (pointerSignal is PointerScrollEvent) {
//             setState(() {
//               _totalScrollDelta += pointerSignal.scrollDelta.dy;
//               _totalScrollDelta = _totalScrollDelta.clamp(0.0, _maxScroll);
//               _updateAnimation();
//             });
//           }
//         },
//         child: Three(onThreeJsCreated: _onThreeJsCreated),
//       ),
//     );
//   }
// }
