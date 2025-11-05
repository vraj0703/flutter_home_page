// --- Top-level function for Starfield Isolate ---
// This will run on a separate isolate.
// It only does the math and returns the raw position data.
import 'package:flutter_gl/native-array/index.dart';
import 'dart:math' as math;
import 'package:three_dart/three_dart.dart' as three;

Float32Array computeStarfieldData(Map<String, dynamic> params) {
  final int starCount = params['count'];
  final double spawnRadius = params['radius'];
  final random = math.Random();
  final positions = Float32Array(starCount * 3);

  for (int i = 0; i < starCount; i++) {
    final i3 = i * 3;
    final phi = random.nextDouble() * 2 * math.pi;
    final theta = math.acos((random.nextDouble() * 2) - 1);
    final r = 200 + random.nextDouble() * (spawnRadius - 200);

    positions[i3] = r * math.sin(theta) * math.cos(phi); // x
    positions[i3 + 1] = r * math.sin(theta) * math.sin(phi); // y
    positions[i3 + 2] = r * math.cos(theta); // z
  }

  return positions;
}

// --- Top-level function for Text Geometry Isolate ---
// This will run on a separate isolate.
// It generates, centers, bends, and calculates normals for the text.
three.BufferGeometry computeTextGeometryData(Map<String, dynamic> params) {
  // 1. Unpack parameters
  final three.Font font = params['font'];
  final String text = params['text'];
  final double curveRadiusX = params['curveRadiusX'];
  final double curveRadiusY = params['curveRadiusY'];
  final double curveRadiusZ = params['curveRadiusZ'];

  // 2. Create the Text Geometry (CPU HEAVY)
  final textGeometry = three.TextGeometry(text, {
    "font": font,
    "size": 15,
    "height": 5,
    "curveSegments": 10,
  });

  // 3. Center the Geometry
  textGeometry.computeBoundingBox();
  final centerOffset = three.Vector3(
    (textGeometry.boundingBox!.max.x - textGeometry.boundingBox!.min.x) * -0.5,
    (textGeometry.boundingBox!.max.y - textGeometry.boundingBox!.min.y) * -0.5,
    (textGeometry.boundingBox!.max.z - textGeometry.boundingBox!.min.z) * -0.5,
  );
  textGeometry.translate(centerOffset.x, centerOffset.y, centerOffset.z);

  // 4. Bend the Geometry (CPU HEAVY FOR-LOOP)
  final position = textGeometry.attributes['position'];
  final vertex = three.Vector3(0, 0, 0);

  for (int i = 0; i < position.count; i++) {
    vertex.fromBufferAttribute(position, i);
    final angleX = vertex.x / curveRadiusX;
    final angleY = vertex.y / curveRadiusY;
    final newX = math.sin(angleX) * curveRadiusX;
    final newY = math.sin(angleY) * curveRadiusY;
    final zDepth = (1 - math.cos(angleX)) * curveRadiusX +
        (1 - math.cos(angleY)) * curveRadiusY;
    final newZ = zDepth * curveRadiusZ;
    position.setXYZ(i, newX, newY, newZ);
  }

  // 5. Calculate Normals (CPU HEAVY)
  textGeometry.computeVertexNormals();

  return textGeometry;
}