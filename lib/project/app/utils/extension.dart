import 'dart:ui';

/// An extension on the [Shadow] class to provide helpful utility methods.
extension ShadowExtension on Shadow {
  /// Creates a copy of this [Shadow] but with the given fields replaced with
  /// the new values.
  Shadow copyWith({Color? color, Offset? offset, double? blurRadius}) {
    return Shadow(
      color: color ?? this.color,
      offset: offset ?? this.offset,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }
}
