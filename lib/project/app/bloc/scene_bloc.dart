import 'dart:async';

import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/widgets/my_game.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_event.dart';

part 'scene_state.dart';

part 'scene_bloc.freezed.dart';

final revealProgressNotifier = ValueNotifier<double>(0.0);

class SceneBloc extends Bloc<SceneEvent, SceneState>
    implements Queuer, StateProvider {
  late final MyGame game;
  double _revealProgress = 0.0;
  late final void Function() _revealProgressListener;

  SceneBloc() : super(const SceneState.loading()) {
    on<Initialize>(_initialize);
    on<CloseCurtain>(_closeCurtain);
    on<TapDown>(_tapDown);
    on<TitleLoaded>(_titleLoaded);
    on<LoadTitle>(_loadTitle);

    game = MyGame(
      queuer: this,
      stateProvider: this,
      onStartExitAnimation: () => add(SceneEvent.closeCurtain()),
    );
    _revealProgressListener = () {
      _revealProgress = revealProgressNotifier.value;
    };
    // Add the listener using the variable
    revealProgressNotifier.addListener(_revealProgressListener);
  }

  @override
  SceneState sceneState() => state;

  @override
  double revealProgress() => _revealProgress;

  FutureOr<void> _titleLoaded(TitleLoaded event, Emitter<SceneState> emit) {
    emit(SceneState.title());
  }

  @override
  Future<void> close() async {
    revealProgressNotifier.removeListener(_revealProgressListener);
    super.close();
  }

  @override
  queue({required SceneEvent event}) {
    add(event);
  }

  FutureOr<void> _initialize(SceneEvent event, Emitter<SceneState> emit) async {
    await game.loaded;
    await Future.delayed(Duration(milliseconds: 600));
    emit(SceneState.logo());
  }

  FutureOr<void> _closeCurtain(CloseCurtain event, Emitter<SceneState> emit) {
    emit(SceneState.loading());
  }

  FutureOr<void> _tapDown(TapDown event, Emitter<SceneState> emit) async {
    if (state is Logo) {
      emit(SceneState.logoOverlayRemoving());
      game.loadTitleBackground();
    }
  }

  FutureOr<void> _loadTitle(LoadTitle event, Emitter<SceneState> emit) {
    emit(SceneState.titleLoading());
    game.animateToHeader();
  }
}
