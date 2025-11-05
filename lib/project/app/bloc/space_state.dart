part of 'space_bloc.dart';

@immutable
sealed class SpaceState {}

final class SpaceInitial extends SpaceState {}

final class SpaceLoading extends SpaceState {
  final String message;

  SpaceLoading(this.message);
}

final class SpaceLoaded extends SpaceState {}
