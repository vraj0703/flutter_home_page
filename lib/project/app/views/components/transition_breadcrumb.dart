import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' as material;

class TransitionBreadcrumb extends TextComponent {
  String breadcrumbText = "";

  TransitionBreadcrumb()
      : super(
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const material.TextStyle(
              fontSize: 14.0,
              color: material.Color(0xCCFFFFFF),
              fontFamily: 'Inter',
              fontWeight: material.FontWeight.w500,
              letterSpacing: 2.0,
            ),
          ),
        );

  void setBreadcrumb(String text) {
    breadcrumbText = text;
    this.text = text;
  }
}
