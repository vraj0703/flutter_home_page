import 'dart:async';
import 'package:flame/events.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_home_page/project/app/config/scroll_sequence_config.dart';

part 'scene_event.dart';

part 'scene_state.dart';

part 'scene_bloc.freezed.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState>
    implements Queuer, StateProvider {
  double _revealProgress = 0.0;
  double _globalScrollOffset = 0.0;

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
    on<ForceScrollOffset>(_onForceScrollOffset);
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
      emit(const SceneState.boldText());
    }
  }

  FutureOr<void> _onScrollSequence(
    OnScrollSequence event,
    Emitter<SceneState> emit,
  ) async {
    _globalScrollOffset += event.delta;

    // Ignore scroll sequence updates during intro states to prevent premature navigation
    if (state is Loading ||
        state is Logo ||
        state is LogoOverlayRemoving ||
        state is TitleLoading) {
      return;
    }

    // Boundary Checks based on ScrollSequenceConfig
    if (_globalScrollOffset < ScrollSequenceConfig.philosophyStart) {
      if (state is! BoldText) {
        emit(const SceneState.boldText());
      }
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.workExpTitleEntranceStart) {
      if (state is! Philosophy) {
        emit(const SceneState.philosophy());
      }
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.experienceEntranceStart) {
      if (state is! WorkExperience) {
        emit(const SceneState.workExperience());
      }
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.testimonialEntranceStart) {
      if (state is! Experience) {
        emit(const SceneState.experience());
      }
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.contactEntranceStart) {
      if (state is! Testimonials) {
        emit(const SceneState.testimonials());
      }
    } else {
      if (state is! Contact) {
        emit(const SceneState.contact());
      }
    }
  }

  FutureOr<void> _onForceScrollOffset(
    ForceScrollOffset event,
    Emitter<SceneState> emit,
  ) {
    _globalScrollOffset = event.offset;
    // Re-evaluate state based on new offset
    // Reuse logic by simulating a 0 delta event or extracting method
    // For now, simpler to copy-paste the checks or extract them.
    // Let's copy-paste for safety to avoid defining new method signature mid-refactor.
    if (_globalScrollOffset < ScrollSequenceConfig.philosophyStart) {
      emit(const SceneState.boldText());
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.workExpTitleEntranceStart) {
      emit(const SceneState.philosophy());
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.experienceEntranceStart) {
      emit(const SceneState.workExperience());
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.testimonialEntranceStart) {
      emit(const SceneState.experience());
    } else if (_globalScrollOffset <
        ScrollSequenceConfig.contactEntranceStart) {
      emit(const SceneState.testimonials());
    } else {
      emit(const SceneState.contact());
    }
  }

  FutureOr<void> _updateUIOpacity(
    UpdateUIOpacity event,
    Emitter<SceneState> emit,
  ) {
    if (state is BoldText) {
      final menuState = state as BoldText;
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
