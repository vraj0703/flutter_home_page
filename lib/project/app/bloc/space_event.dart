part of 'space_bloc.dart';

@immutable
sealed class SpaceEvent {}

final class Initialize extends SpaceEvent {}

final class Load extends SpaceEvent {}
