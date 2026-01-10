import 'dart:async';
import 'package:flame/events.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_event.dart';

part 'scene_state.dart';

part 'scene_bloc.freezed.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState>
    implements Queuer, StateProvider {
  double _revealProgress = 0.0;

  late SvgAssetLoader downArrowLoader;

  SceneBloc() : super(const SceneState.loading()) {
    on<Initialize>(_initialize);
    on<GameReady>(_gameReady);
    on<CloseCurtain>(_closeCurtain);
    on<TapDown>(_tapDown);
    on<LoadTitle>(_loadTitle);
    on<TitleLoaded>(_titleLoaded);
    on<OnScroll>(_onScroll);
    on<OnScrollSequence>(_onScrollSequence);
    on<UpdateUIOpacity>(_updateUIOpacity);
  }

  @override
  SceneState sceneState() => state;

  @override
  double revealProgress() => _revealProgress;

  @override
  void updateUIOpacity(double opacity) {
    add(SceneEvent.updateUIOpacity(opacity));
  }

  @override
  queue({required SceneEvent event}) {
    add(event);
  }

  FutureOr<void> _initialize(Initialize event, Emitter<SceneState> emit) async {
    downArrowLoader = SvgAssetLoader('assets/vectors/down_arrow.svg');
    svg.cache.putIfAbsent(
      downArrowLoader.cacheKey(null),
      () => downArrowLoader.loadBytes(null),
    );

    // Mark SVG as ready
    if (state is Loading) {
      final currentState = state as Loading;
      final newState = currentState.copyWith(isSvgReady: true);
      emit(newState);
      await _checkReadiness(newState, emit);
    }
  }

  FutureOr<void> _gameReady(GameReady event, Emitter<SceneState> emit) async {
    if (state is Loading) {
      final currentState = state as Loading;
      final newState = currentState.copyWith(isGameReady: true);
      emit(newState);
      await _checkReadiness(newState, emit);
    }
  }

  FutureOr<void> _checkReadiness(
    Loading state,
    Emitter<SceneState> emit,
  ) async {
    if (state.isSvgReady && state.isGameReady) {
      // Optional delay for effect, similar to original code
      await Future.delayed(const Duration(milliseconds: 600));
      emit(const SceneState.logo());
    }
  }

  FutureOr<void> _closeCurtain(CloseCurtain event, Emitter<SceneState> emit) {
    emit(SceneState.loading());
  }

  FutureOr<void> _tapDown(TapDown event, Emitter<SceneState> emit) async {
    if (state is Logo) {
      emit(const SceneState.logoOverlayRemoving());
    }
  }

  FutureOr<void> _loadTitle(LoadTitle event, Emitter<SceneState> emit) {
    emit(const SceneState.titleLoading());
  }

  FutureOr<void> _titleLoaded(TitleLoaded event, Emitter<SceneState> emit) {
    emit(SceneState.title());
  }

  FutureOr<void> _onScroll(OnScroll event, Emitter<SceneState> emit) {
    if (state is Title) {
      emit(const SceneState.menu());
    }
  }

  FutureOr<void> _onScrollSequence(
    OnScrollSequence event,
    Emitter<SceneState> emit,
  ) {
    // Scroll sequence logic to be implemented or handled by UI
  }

  FutureOr<void> _updateUIOpacity(
    UpdateUIOpacity event,
    Emitter<SceneState> emit,
  ) {
    if (state is Menu) {
      final menuState = state as Menu;
      if (menuState.uiOpacity != event.opacity) {
        emit(menuState.copyWith(uiOpacity: event.opacity));
      }
    }
  }

  @override
  void updateRevealProgress(double progress) {
    _revealProgress = progress;
  }
}
