import 'package:vector_math/vector_math_64.dart';

void main() {
  Vector2 a = Vector2(0, 0);
  a.lerp(Vector2(10, 10), 0.5);
  print(a);
}
