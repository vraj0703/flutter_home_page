part of 'space_bloc.dart';

@immutable
sealed class SpaceState {}

final class SpaceInitial extends SpaceState {}

final class SpaceLoaded extends SpaceState {}
