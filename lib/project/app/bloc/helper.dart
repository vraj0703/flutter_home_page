// --- Top-level function for Starfield Isolate ---
// This will run on a separate isolate.
// It only does the math and returns the raw position data.
import 'package:flutter_gl/native-array/index.dart';
import 'dart:math' as math;

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
