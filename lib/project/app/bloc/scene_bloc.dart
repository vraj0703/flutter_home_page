import 'dart:async';
import 'package:flame/events.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_home_page/project/app/interfaces/queuer.dart';
import 'package:flutter_home_page/project/app/interfaces/state_provider.dart';
import 'package:flutter_home_page/project/app/interfaces/section_manager.dart';
import 'package:flutter_home_page/project/app/models/scroll_result.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_event.dart';

part 'scene_state.dart';

part 'scene_bloc.freezed.dart';

class SceneBloc extends Bloc<SceneEvent, SceneState>
    implements Queuer, StateProvider {
  double _revealProgress = 0.0;
  List<SectionManager> _sections = [];
  int _currentIndex = 0;

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
    on<RegisterSections>(_onRegisterSections);
    on<NextSection>(_onNextSection);
    on<PreviousSection>(_onPreviousSection);
    on<UpdateSectionOffset>(_onUpdateSectionOffset);
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
      emit(const SceneState.boldText(uiOpacity: 1.0, offset: 0.0));
    }
  }

  FutureOr<void> _onRegisterSections(
    RegisterSections event,
    Emitter<SceneState> emit,
  ) {
    _sections = event.managers;
  }

  FutureOr<void> _onScrollSequence(
    OnScrollSequence event,
    Emitter<SceneState> emit,
  ) async {
    if (_sections.isEmpty) return;
    if (state is Loading ||
        state is Logo ||
        state is LogoOverlayRemoving ||
        state is TitleLoading) {
      return;
    }

    final currentOffset = state.mapOrNull(
      boldText: (s) => s.offset,
      philosophy: (s) => s.offset,
      workExperience: (s) => s.offset,
      experience: (s) => s.offset,
      testimonials: (s) => s.offset,
      contact: (s) => s.offset,
    );

    if (currentOffset == null) return;

    final currentManager = _sections[_currentIndex];

    final result = currentManager.handleScroll(currentOffset, event.delta);

    if (result is ScrollConsumed) {
      add(SceneEvent.updateSectionOffset(result.newOffset));
    } else if (result is ScrollOverflow) {
      add(SceneEvent.nextSection(overflow: result.overflowAmount));
    } else if (result is ScrollUnderflow) {
      add(SceneEvent.previousSection(underflow: result.underflowAmount));
    }
  }

  FutureOr<void> _onNextSection(NextSection event, Emitter<SceneState> emit) {
    if (_currentIndex < _sections.length - 1) {
      _currentIndex++;
      final baseOffset = _sections[_currentIndex].onActivate(false);
      final startOffset = baseOffset + event.overflow;
      _emitStateForIndex(_currentIndex, startOffset, emit);
    } else {
      // Stay at end if no more sections.
      // We can query onActivate(true) to get the 'end' if we really wanted to clamp,
      // but simpler to just do nothing or clamp to current offset.
      // Assuming handled by manager's handleScroll returning Consumed.
    }
  }

  FutureOr<void> _onPreviousSection(
    PreviousSection event,
    Emitter<SceneState> emit,
  ) {
    if (_currentIndex > 0) {
      _currentIndex--;
      // Ask manager where to start when entering from bottom
      final baseOffset = _sections[_currentIndex].onActivate(true);
      final startOffset = baseOffset + event.underflow;
      _emitStateForIndex(_currentIndex, startOffset, emit);
    } else {
      // Clamp at 0
      add(const SceneEvent.updateSectionOffset(0.0));
    }
  }

  FutureOr<void> _onUpdateSectionOffset(
    UpdateSectionOffset event,
    Emitter<SceneState> emit,
  ) {
    final offset = event.offset;
    _emitStateForIndex(_currentIndex, offset, emit);
    _sections[_currentIndex].onScroll(offset);
  }

  void _emitStateForIndex(int index, double offset, Emitter<SceneState> emit) {
    // Mapping Index -> State
    // 0: BoldText
    // 1: Philosophy
    // 2: WorkExperience (Title)
    // 3: Experience
    // 4: Testimonials
    // 5: Contact

    // We assume _sections is ordered correctly.
    // Creating state based on index.

    // NOTE: Ideally we'd store the TYPE in SectionManager or separate config.
    // implementation simplification: switch case on index.

    switch (index) {
      case 0:
        // Preserve uiOpacity from current state if it exists
        final currentOpacity = state.maybeMap(
          boldText: (s) => s.uiOpacity,
          orElse: () => 1.0,
        );
        emit(SceneState.boldText(offset: offset, uiOpacity: currentOpacity));
        break;
      case 1:
        emit(SceneState.philosophy(offset: offset));
        break;
      case 2:
        emit(SceneState.workExperience(offset: offset));
        break;
      case 3:
        emit(SceneState.experience(offset: offset));
        break;
      case 4:
        emit(SceneState.testimonials(offset: offset));
        break;
      case 5:
        emit(SceneState.contact(offset: offset));
        break;
    }
  }

  FutureOr<void> _onForceScrollOffset(
    ForceScrollOffset event,
    Emitter<SceneState> emit,
  ) {
    _currentIndex = 0;
    emit(const SceneState.boldText(offset: 0.0, uiOpacity: 1.0));
  }

  FutureOr<void> _updateUIOpacity(
    UpdateUIOpacity event,
    Emitter<SceneState> emit,
  ) {
    if (state is BoldText) {
      print("here ");
      final menuState = state as BoldText;
      final clampedOpacity = event.opacity.clamp(0.0, 1.0);
      if (menuState.uiOpacity != clampedOpacity) {
        emit(menuState.copyWith(uiOpacity: clampedOpacity));
      }
    }
  }

  @override
  void updateRevealProgress(double progress) {
    _revealProgress = progress;
  }
}
