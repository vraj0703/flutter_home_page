part of 'space_bloc.dart';

@immutable
sealed class SpaceEvent {}

final class Initialize extends SpaceEvent {}

final class Load extends SpaceEvent {}

// Event to handle scroll/drag input from the UI
final class Scroll extends SpaceEvent {
  final double scrollDelta;
  Scroll(this.scrollDelta);
}