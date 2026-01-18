import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_home_page/project/app/views/widgets/orbital_arcs_painter.dart';

class OrbitalArcsComponent extends PositionComponent with HasPaint {
  double rotation = 0.0;
  Color accentColor;
  double _opacity = 0.0;

  OrbitalArcsComponent({required this.accentColor, super.size});

  @override
  set opacity(double val) {
    _opacity = val;
  }

  @override
  void render(Canvas canvas) {
    // Custom paint logic
    final painter = OrbitalArcsPainter(
      rotation: rotation,
      accentColor: accentColor,
      opacity: _opacity,
    );
    painter.paint(canvas, size.toSize());
  }
}
