// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SceneEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent()';
}


}

/// @nodoc
class $SceneEventCopyWith<$Res>  {
$SceneEventCopyWith(SceneEvent _, $Res Function(SceneEvent) __);
}


/// Adds pattern-matching-related methods to [SceneEvent].
extension SceneEventPatterns on SceneEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initialize value)?  initialize,TResult Function( CloseCurtain value)?  closeCurtain,TResult Function( TapDown value)?  tapDown,TResult Function( LoadTitle value)?  loadTitle,TResult Function( TitleLoaded value)?  titleLoaded,TResult Function( GameReady value)?  gameReady,TResult Function( OnScroll value)?  onScroll,TResult Function( OnScrollSequence value)?  onScrollSequence,TResult Function( ForceScrollOffset value)?  forceScrollOffset,TResult Function( UpdateUIOpacity value)?  updateUIOpacity,TResult Function( RegisterSections value)?  registerSections,TResult Function( NextSection value)?  nextSection,TResult Function( PreviousSection value)?  previousSection,TResult Function( UpdateSectionOffset value)?  updateSectionOffset,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case CloseCurtain() when closeCurtain != null:
return closeCurtain(_that);case TapDown() when tapDown != null:
return tapDown(_that);case LoadTitle() when loadTitle != null:
return loadTitle(_that);case TitleLoaded() when titleLoaded != null:
return titleLoaded(_that);case GameReady() when gameReady != null:
return gameReady(_that);case OnScroll() when onScroll != null:
return onScroll(_that);case OnScrollSequence() when onScrollSequence != null:
return onScrollSequence(_that);case ForceScrollOffset() when forceScrollOffset != null:
return forceScrollOffset(_that);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that);case RegisterSections() when registerSections != null:
return registerSections(_that);case NextSection() when nextSection != null:
return nextSection(_that);case PreviousSection() when previousSection != null:
return previousSection(_that);case UpdateSectionOffset() when updateSectionOffset != null:
return updateSectionOffset(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initialize value)  initialize,required TResult Function( CloseCurtain value)  closeCurtain,required TResult Function( TapDown value)  tapDown,required TResult Function( LoadTitle value)  loadTitle,required TResult Function( TitleLoaded value)  titleLoaded,required TResult Function( GameReady value)  gameReady,required TResult Function( OnScroll value)  onScroll,required TResult Function( OnScrollSequence value)  onScrollSequence,required TResult Function( ForceScrollOffset value)  forceScrollOffset,required TResult Function( UpdateUIOpacity value)  updateUIOpacity,required TResult Function( RegisterSections value)  registerSections,required TResult Function( NextSection value)  nextSection,required TResult Function( PreviousSection value)  previousSection,required TResult Function( UpdateSectionOffset value)  updateSectionOffset,}){
final _that = this;
switch (_that) {
case Initialize():
return initialize(_that);case CloseCurtain():
return closeCurtain(_that);case TapDown():
return tapDown(_that);case LoadTitle():
return loadTitle(_that);case TitleLoaded():
return titleLoaded(_that);case GameReady():
return gameReady(_that);case OnScroll():
return onScroll(_that);case OnScrollSequence():
return onScrollSequence(_that);case ForceScrollOffset():
return forceScrollOffset(_that);case UpdateUIOpacity():
return updateUIOpacity(_that);case RegisterSections():
return registerSections(_that);case NextSection():
return nextSection(_that);case PreviousSection():
return previousSection(_that);case UpdateSectionOffset():
return updateSectionOffset(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initialize value)?  initialize,TResult? Function( CloseCurtain value)?  closeCurtain,TResult? Function( TapDown value)?  tapDown,TResult? Function( LoadTitle value)?  loadTitle,TResult? Function( TitleLoaded value)?  titleLoaded,TResult? Function( GameReady value)?  gameReady,TResult? Function( OnScroll value)?  onScroll,TResult? Function( OnScrollSequence value)?  onScrollSequence,TResult? Function( ForceScrollOffset value)?  forceScrollOffset,TResult? Function( UpdateUIOpacity value)?  updateUIOpacity,TResult? Function( RegisterSections value)?  registerSections,TResult? Function( NextSection value)?  nextSection,TResult? Function( PreviousSection value)?  previousSection,TResult? Function( UpdateSectionOffset value)?  updateSectionOffset,}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case CloseCurtain() when closeCurtain != null:
return closeCurtain(_that);case TapDown() when tapDown != null:
return tapDown(_that);case LoadTitle() when loadTitle != null:
return loadTitle(_that);case TitleLoaded() when titleLoaded != null:
return titleLoaded(_that);case GameReady() when gameReady != null:
return gameReady(_that);case OnScroll() when onScroll != null:
return onScroll(_that);case OnScrollSequence() when onScrollSequence != null:
return onScrollSequence(_that);case ForceScrollOffset() when forceScrollOffset != null:
return forceScrollOffset(_that);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that);case RegisterSections() when registerSections != null:
return registerSections(_that);case NextSection() when nextSection != null:
return nextSection(_that);case PreviousSection() when previousSection != null:
return previousSection(_that);case UpdateSectionOffset() when updateSectionOffset != null:
return updateSectionOffset(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function()?  closeCurtain,TResult Function( TapDownEvent tapDownEvent)?  tapDown,TResult Function()?  loadTitle,TResult Function()?  titleLoaded,TResult Function()?  gameReady,TResult Function()?  onScroll,TResult Function( double delta)?  onScrollSequence,TResult Function( double offset)?  forceScrollOffset,TResult Function( double opacity)?  updateUIOpacity,TResult Function( List<SectionManager> managers)?  registerSections,TResult Function( double overflow)?  nextSection,TResult Function( double underflow)?  previousSection,TResult Function( double offset)?  updateSectionOffset,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case CloseCurtain() when closeCurtain != null:
return closeCurtain();case TapDown() when tapDown != null:
return tapDown(_that.tapDownEvent);case LoadTitle() when loadTitle != null:
return loadTitle();case TitleLoaded() when titleLoaded != null:
return titleLoaded();case GameReady() when gameReady != null:
return gameReady();case OnScroll() when onScroll != null:
return onScroll();case OnScrollSequence() when onScrollSequence != null:
return onScrollSequence(_that.delta);case ForceScrollOffset() when forceScrollOffset != null:
return forceScrollOffset(_that.offset);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that.opacity);case RegisterSections() when registerSections != null:
return registerSections(_that.managers);case NextSection() when nextSection != null:
return nextSection(_that.overflow);case PreviousSection() when previousSection != null:
return previousSection(_that.underflow);case UpdateSectionOffset() when updateSectionOffset != null:
return updateSectionOffset(_that.offset);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function()  closeCurtain,required TResult Function( TapDownEvent tapDownEvent)  tapDown,required TResult Function()  loadTitle,required TResult Function()  titleLoaded,required TResult Function()  gameReady,required TResult Function()  onScroll,required TResult Function( double delta)  onScrollSequence,required TResult Function( double offset)  forceScrollOffset,required TResult Function( double opacity)  updateUIOpacity,required TResult Function( List<SectionManager> managers)  registerSections,required TResult Function( double overflow)  nextSection,required TResult Function( double underflow)  previousSection,required TResult Function( double offset)  updateSectionOffset,}) {final _that = this;
switch (_that) {
case Initialize():
return initialize();case CloseCurtain():
return closeCurtain();case TapDown():
return tapDown(_that.tapDownEvent);case LoadTitle():
return loadTitle();case TitleLoaded():
return titleLoaded();case GameReady():
return gameReady();case OnScroll():
return onScroll();case OnScrollSequence():
return onScrollSequence(_that.delta);case ForceScrollOffset():
return forceScrollOffset(_that.offset);case UpdateUIOpacity():
return updateUIOpacity(_that.opacity);case RegisterSections():
return registerSections(_that.managers);case NextSection():
return nextSection(_that.overflow);case PreviousSection():
return previousSection(_that.underflow);case UpdateSectionOffset():
return updateSectionOffset(_that.offset);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function()?  closeCurtain,TResult? Function( TapDownEvent tapDownEvent)?  tapDown,TResult? Function()?  loadTitle,TResult? Function()?  titleLoaded,TResult? Function()?  gameReady,TResult? Function()?  onScroll,TResult? Function( double delta)?  onScrollSequence,TResult? Function( double offset)?  forceScrollOffset,TResult? Function( double opacity)?  updateUIOpacity,TResult? Function( List<SectionManager> managers)?  registerSections,TResult? Function( double overflow)?  nextSection,TResult? Function( double underflow)?  previousSection,TResult? Function( double offset)?  updateSectionOffset,}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case CloseCurtain() when closeCurtain != null:
return closeCurtain();case TapDown() when tapDown != null:
return tapDown(_that.tapDownEvent);case LoadTitle() when loadTitle != null:
return loadTitle();case TitleLoaded() when titleLoaded != null:
return titleLoaded();case GameReady() when gameReady != null:
return gameReady();case OnScroll() when onScroll != null:
return onScroll();case OnScrollSequence() when onScrollSequence != null:
return onScrollSequence(_that.delta);case ForceScrollOffset() when forceScrollOffset != null:
return forceScrollOffset(_that.offset);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that.opacity);case RegisterSections() when registerSections != null:
return registerSections(_that.managers);case NextSection() when nextSection != null:
return nextSection(_that.overflow);case PreviousSection() when previousSection != null:
return previousSection(_that.underflow);case UpdateSectionOffset() when updateSectionOffset != null:
return updateSectionOffset(_that.offset);case _:
  return null;

}
}

}

/// @nodoc


class Initialize implements SceneEvent {
  const Initialize();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Initialize);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.initialize()';
}


}




/// @nodoc


class CloseCurtain implements SceneEvent {
  const CloseCurtain();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CloseCurtain);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.closeCurtain()';
}


}




/// @nodoc


class TapDown implements SceneEvent {
  const TapDown(this.tapDownEvent);
  

 final  TapDownEvent tapDownEvent;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TapDownCopyWith<TapDown> get copyWith => _$TapDownCopyWithImpl<TapDown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TapDown&&(identical(other.tapDownEvent, tapDownEvent) || other.tapDownEvent == tapDownEvent));
}


@override
int get hashCode => Object.hash(runtimeType,tapDownEvent);

@override
String toString() {
  return 'SceneEvent.tapDown(tapDownEvent: $tapDownEvent)';
}


}

/// @nodoc
abstract mixin class $TapDownCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $TapDownCopyWith(TapDown value, $Res Function(TapDown) _then) = _$TapDownCopyWithImpl;
@useResult
$Res call({
 TapDownEvent tapDownEvent
});




}
/// @nodoc
class _$TapDownCopyWithImpl<$Res>
    implements $TapDownCopyWith<$Res> {
  _$TapDownCopyWithImpl(this._self, this._then);

  final TapDown _self;
  final $Res Function(TapDown) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tapDownEvent = null,}) {
  return _then(TapDown(
null == tapDownEvent ? _self.tapDownEvent : tapDownEvent // ignore: cast_nullable_to_non_nullable
as TapDownEvent,
  ));
}


}

/// @nodoc


class LoadTitle implements SceneEvent {
  const LoadTitle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadTitle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.loadTitle()';
}


}




/// @nodoc


class TitleLoaded implements SceneEvent {
  const TitleLoaded();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleLoaded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.titleLoaded()';
}


}




/// @nodoc


class GameReady implements SceneEvent {
  const GameReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.gameReady()';
}


}




/// @nodoc


class OnScroll implements SceneEvent {
  const OnScroll();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnScroll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.onScroll()';
}


}




/// @nodoc


class OnScrollSequence implements SceneEvent {
  const OnScrollSequence(this.delta);
  

 final  double delta;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnScrollSequenceCopyWith<OnScrollSequence> get copyWith => _$OnScrollSequenceCopyWithImpl<OnScrollSequence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnScrollSequence&&(identical(other.delta, delta) || other.delta == delta));
}


@override
int get hashCode => Object.hash(runtimeType,delta);

@override
String toString() {
  return 'SceneEvent.onScrollSequence(delta: $delta)';
}


}

/// @nodoc
abstract mixin class $OnScrollSequenceCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $OnScrollSequenceCopyWith(OnScrollSequence value, $Res Function(OnScrollSequence) _then) = _$OnScrollSequenceCopyWithImpl;
@useResult
$Res call({
 double delta
});




}
/// @nodoc
class _$OnScrollSequenceCopyWithImpl<$Res>
    implements $OnScrollSequenceCopyWith<$Res> {
  _$OnScrollSequenceCopyWithImpl(this._self, this._then);

  final OnScrollSequence _self;
  final $Res Function(OnScrollSequence) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? delta = null,}) {
  return _then(OnScrollSequence(
null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class ForceScrollOffset implements SceneEvent {
  const ForceScrollOffset(this.offset);
  

 final  double offset;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForceScrollOffsetCopyWith<ForceScrollOffset> get copyWith => _$ForceScrollOffsetCopyWithImpl<ForceScrollOffset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForceScrollOffset&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneEvent.forceScrollOffset(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $ForceScrollOffsetCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $ForceScrollOffsetCopyWith(ForceScrollOffset value, $Res Function(ForceScrollOffset) _then) = _$ForceScrollOffsetCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$ForceScrollOffsetCopyWithImpl<$Res>
    implements $ForceScrollOffsetCopyWith<$Res> {
  _$ForceScrollOffsetCopyWithImpl(this._self, this._then);

  final ForceScrollOffset _self;
  final $Res Function(ForceScrollOffset) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(ForceScrollOffset(
null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class UpdateUIOpacity implements SceneEvent {
  const UpdateUIOpacity(this.opacity);
  

 final  double opacity;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUIOpacityCopyWith<UpdateUIOpacity> get copyWith => _$UpdateUIOpacityCopyWithImpl<UpdateUIOpacity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUIOpacity&&(identical(other.opacity, opacity) || other.opacity == opacity));
}


@override
int get hashCode => Object.hash(runtimeType,opacity);

@override
String toString() {
  return 'SceneEvent.updateUIOpacity(opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $UpdateUIOpacityCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $UpdateUIOpacityCopyWith(UpdateUIOpacity value, $Res Function(UpdateUIOpacity) _then) = _$UpdateUIOpacityCopyWithImpl;
@useResult
$Res call({
 double opacity
});




}
/// @nodoc
class _$UpdateUIOpacityCopyWithImpl<$Res>
    implements $UpdateUIOpacityCopyWith<$Res> {
  _$UpdateUIOpacityCopyWithImpl(this._self, this._then);

  final UpdateUIOpacity _self;
  final $Res Function(UpdateUIOpacity) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? opacity = null,}) {
  return _then(UpdateUIOpacity(
null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class RegisterSections implements SceneEvent {
  const RegisterSections(final  List<SectionManager> managers): _managers = managers;
  

 final  List<SectionManager> _managers;
 List<SectionManager> get managers {
  if (_managers is EqualUnmodifiableListView) return _managers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_managers);
}


/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterSectionsCopyWith<RegisterSections> get copyWith => _$RegisterSectionsCopyWithImpl<RegisterSections>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterSections&&const DeepCollectionEquality().equals(other._managers, _managers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_managers));

@override
String toString() {
  return 'SceneEvent.registerSections(managers: $managers)';
}


}

/// @nodoc
abstract mixin class $RegisterSectionsCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $RegisterSectionsCopyWith(RegisterSections value, $Res Function(RegisterSections) _then) = _$RegisterSectionsCopyWithImpl;
@useResult
$Res call({
 List<SectionManager> managers
});




}
/// @nodoc
class _$RegisterSectionsCopyWithImpl<$Res>
    implements $RegisterSectionsCopyWith<$Res> {
  _$RegisterSectionsCopyWithImpl(this._self, this._then);

  final RegisterSections _self;
  final $Res Function(RegisterSections) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? managers = null,}) {
  return _then(RegisterSections(
null == managers ? _self._managers : managers // ignore: cast_nullable_to_non_nullable
as List<SectionManager>,
  ));
}


}

/// @nodoc


class NextSection implements SceneEvent {
  const NextSection({this.overflow = 0.0});
  

@JsonKey() final  double overflow;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextSectionCopyWith<NextSection> get copyWith => _$NextSectionCopyWithImpl<NextSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextSection&&(identical(other.overflow, overflow) || other.overflow == overflow));
}


@override
int get hashCode => Object.hash(runtimeType,overflow);

@override
String toString() {
  return 'SceneEvent.nextSection(overflow: $overflow)';
}


}

/// @nodoc
abstract mixin class $NextSectionCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $NextSectionCopyWith(NextSection value, $Res Function(NextSection) _then) = _$NextSectionCopyWithImpl;
@useResult
$Res call({
 double overflow
});




}
/// @nodoc
class _$NextSectionCopyWithImpl<$Res>
    implements $NextSectionCopyWith<$Res> {
  _$NextSectionCopyWithImpl(this._self, this._then);

  final NextSection _self;
  final $Res Function(NextSection) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? overflow = null,}) {
  return _then(NextSection(
overflow: null == overflow ? _self.overflow : overflow // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class PreviousSection implements SceneEvent {
  const PreviousSection({this.underflow = 0.0});
  

@JsonKey() final  double underflow;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreviousSectionCopyWith<PreviousSection> get copyWith => _$PreviousSectionCopyWithImpl<PreviousSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreviousSection&&(identical(other.underflow, underflow) || other.underflow == underflow));
}


@override
int get hashCode => Object.hash(runtimeType,underflow);

@override
String toString() {
  return 'SceneEvent.previousSection(underflow: $underflow)';
}


}

/// @nodoc
abstract mixin class $PreviousSectionCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $PreviousSectionCopyWith(PreviousSection value, $Res Function(PreviousSection) _then) = _$PreviousSectionCopyWithImpl;
@useResult
$Res call({
 double underflow
});




}
/// @nodoc
class _$PreviousSectionCopyWithImpl<$Res>
    implements $PreviousSectionCopyWith<$Res> {
  _$PreviousSectionCopyWithImpl(this._self, this._then);

  final PreviousSection _self;
  final $Res Function(PreviousSection) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? underflow = null,}) {
  return _then(PreviousSection(
underflow: null == underflow ? _self.underflow : underflow // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class UpdateSectionOffset implements SceneEvent {
  const UpdateSectionOffset(this.offset);
  

 final  double offset;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateSectionOffsetCopyWith<UpdateSectionOffset> get copyWith => _$UpdateSectionOffsetCopyWithImpl<UpdateSectionOffset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateSectionOffset&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneEvent.updateSectionOffset(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $UpdateSectionOffsetCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $UpdateSectionOffsetCopyWith(UpdateSectionOffset value, $Res Function(UpdateSectionOffset) _then) = _$UpdateSectionOffsetCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$UpdateSectionOffsetCopyWithImpl<$Res>
    implements $UpdateSectionOffsetCopyWith<$Res> {
  _$UpdateSectionOffsetCopyWithImpl(this._self, this._then);

  final UpdateSectionOffset _self;
  final $Res Function(UpdateSectionOffset) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(UpdateSectionOffset(
null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$SceneState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState()';
}


}

/// @nodoc
class $SceneStateCopyWith<$Res>  {
$SceneStateCopyWith(SceneState _, $Res Function(SceneState) __);
}


/// Adds pattern-matching-related methods to [SceneState].
extension SceneStatePatterns on SceneState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Loading value)?  loading,TResult Function( Logo value)?  logo,TResult Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult Function( TitleLoading value)?  titleLoading,TResult Function( Title value)?  title,TResult Function( BoldText value)?  boldText,TResult Function( Philosophy value)?  philosophy,TResult Function( WorkExperience value)?  workExperience,TResult Function( Experience value)?  experience,TResult Function( Testimonials value)?  testimonials,TResult Function( Contact value)?  contact,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case BoldText() when boldText != null:
return boldText(_that);case Philosophy() when philosophy != null:
return philosophy(_that);case WorkExperience() when workExperience != null:
return workExperience(_that);case Experience() when experience != null:
return experience(_that);case Testimonials() when testimonials != null:
return testimonials(_that);case Contact() when contact != null:
return contact(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Loading value)  loading,required TResult Function( Logo value)  logo,required TResult Function( LogoOverlayRemoving value)  logoOverlayRemoving,required TResult Function( TitleLoading value)  titleLoading,required TResult Function( Title value)  title,required TResult Function( BoldText value)  boldText,required TResult Function( Philosophy value)  philosophy,required TResult Function( WorkExperience value)  workExperience,required TResult Function( Experience value)  experience,required TResult Function( Testimonials value)  testimonials,required TResult Function( Contact value)  contact,}){
final _that = this;
switch (_that) {
case Loading():
return loading(_that);case Logo():
return logo(_that);case LogoOverlayRemoving():
return logoOverlayRemoving(_that);case TitleLoading():
return titleLoading(_that);case Title():
return title(_that);case BoldText():
return boldText(_that);case Philosophy():
return philosophy(_that);case WorkExperience():
return workExperience(_that);case Experience():
return experience(_that);case Testimonials():
return testimonials(_that);case Contact():
return contact(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Loading value)?  loading,TResult? Function( Logo value)?  logo,TResult? Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult? Function( TitleLoading value)?  titleLoading,TResult? Function( Title value)?  title,TResult? Function( BoldText value)?  boldText,TResult? Function( Philosophy value)?  philosophy,TResult? Function( WorkExperience value)?  workExperience,TResult? Function( Experience value)?  experience,TResult? Function( Testimonials value)?  testimonials,TResult? Function( Contact value)?  contact,}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case BoldText() when boldText != null:
return boldText(_that);case Philosophy() when philosophy != null:
return philosophy(_that);case WorkExperience() when workExperience != null:
return workExperience(_that);case Experience() when experience != null:
return experience(_that);case Testimonials() when testimonials != null:
return testimonials(_that);case Contact() when contact != null:
return contact(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isSvgReady,  bool isGameReady)?  loading,TResult Function()?  logo,TResult Function()?  logoOverlayRemoving,TResult Function()?  titleLoading,TResult Function()?  title,TResult Function( double uiOpacity,  double offset)?  boldText,TResult Function( double offset)?  philosophy,TResult Function( double offset)?  workExperience,TResult Function( double offset)?  experience,TResult Function( double offset)?  testimonials,TResult Function( double offset)?  contact,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.isSvgReady,_that.isGameReady);case Logo() when logo != null:
return logo();case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case BoldText() when boldText != null:
return boldText(_that.uiOpacity,_that.offset);case Philosophy() when philosophy != null:
return philosophy(_that.offset);case WorkExperience() when workExperience != null:
return workExperience(_that.offset);case Experience() when experience != null:
return experience(_that.offset);case Testimonials() when testimonials != null:
return testimonials(_that.offset);case Contact() when contact != null:
return contact(_that.offset);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isSvgReady,  bool isGameReady)  loading,required TResult Function()  logo,required TResult Function()  logoOverlayRemoving,required TResult Function()  titleLoading,required TResult Function()  title,required TResult Function( double uiOpacity,  double offset)  boldText,required TResult Function( double offset)  philosophy,required TResult Function( double offset)  workExperience,required TResult Function( double offset)  experience,required TResult Function( double offset)  testimonials,required TResult Function( double offset)  contact,}) {final _that = this;
switch (_that) {
case Loading():
return loading(_that.isSvgReady,_that.isGameReady);case Logo():
return logo();case LogoOverlayRemoving():
return logoOverlayRemoving();case TitleLoading():
return titleLoading();case Title():
return title();case BoldText():
return boldText(_that.uiOpacity,_that.offset);case Philosophy():
return philosophy(_that.offset);case WorkExperience():
return workExperience(_that.offset);case Experience():
return experience(_that.offset);case Testimonials():
return testimonials(_that.offset);case Contact():
return contact(_that.offset);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isSvgReady,  bool isGameReady)?  loading,TResult? Function()?  logo,TResult? Function()?  logoOverlayRemoving,TResult? Function()?  titleLoading,TResult? Function()?  title,TResult? Function( double uiOpacity,  double offset)?  boldText,TResult? Function( double offset)?  philosophy,TResult? Function( double offset)?  workExperience,TResult? Function( double offset)?  experience,TResult? Function( double offset)?  testimonials,TResult? Function( double offset)?  contact,}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.isSvgReady,_that.isGameReady);case Logo() when logo != null:
return logo();case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case BoldText() when boldText != null:
return boldText(_that.uiOpacity,_that.offset);case Philosophy() when philosophy != null:
return philosophy(_that.offset);case WorkExperience() when workExperience != null:
return workExperience(_that.offset);case Experience() when experience != null:
return experience(_that.offset);case Testimonials() when testimonials != null:
return testimonials(_that.offset);case Contact() when contact != null:
return contact(_that.offset);case _:
  return null;

}
}

}

/// @nodoc


class Loading implements SceneState {
  const Loading({this.isSvgReady = false, this.isGameReady = false});
  

@JsonKey() final  bool isSvgReady;
@JsonKey() final  bool isGameReady;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingCopyWith<Loading> get copyWith => _$LoadingCopyWithImpl<Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading&&(identical(other.isSvgReady, isSvgReady) || other.isSvgReady == isSvgReady)&&(identical(other.isGameReady, isGameReady) || other.isGameReady == isGameReady));
}


@override
int get hashCode => Object.hash(runtimeType,isSvgReady,isGameReady);

@override
String toString() {
  return 'SceneState.loading(isSvgReady: $isSvgReady, isGameReady: $isGameReady)';
}


}

/// @nodoc
abstract mixin class $LoadingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) _then) = _$LoadingCopyWithImpl;
@useResult
$Res call({
 bool isSvgReady, bool isGameReady
});




}
/// @nodoc
class _$LoadingCopyWithImpl<$Res>
    implements $LoadingCopyWith<$Res> {
  _$LoadingCopyWithImpl(this._self, this._then);

  final Loading _self;
  final $Res Function(Loading) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isSvgReady = null,Object? isGameReady = null,}) {
  return _then(Loading(
isSvgReady: null == isSvgReady ? _self.isSvgReady : isSvgReady // ignore: cast_nullable_to_non_nullable
as bool,isGameReady: null == isGameReady ? _self.isGameReady : isGameReady // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Logo implements SceneState {
  const Logo();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Logo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.logo()';
}


}




/// @nodoc


class LogoOverlayRemoving implements SceneState {
  const LogoOverlayRemoving();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoOverlayRemoving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.logoOverlayRemoving()';
}


}




/// @nodoc


class TitleLoading implements SceneState {
  const TitleLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.titleLoading()';
}


}




/// @nodoc


class Title implements SceneState {
  const Title();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Title);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.title()';
}


}




/// @nodoc


class BoldText implements SceneState {
  const BoldText({this.uiOpacity = 1.0, this.offset = 0.0});
  

@JsonKey() final  double uiOpacity;
@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoldTextCopyWith<BoldText> get copyWith => _$BoldTextCopyWithImpl<BoldText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoldText&&(identical(other.uiOpacity, uiOpacity) || other.uiOpacity == uiOpacity)&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,uiOpacity,offset);

@override
String toString() {
  return 'SceneState.boldText(uiOpacity: $uiOpacity, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $BoldTextCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $BoldTextCopyWith(BoldText value, $Res Function(BoldText) _then) = _$BoldTextCopyWithImpl;
@useResult
$Res call({
 double uiOpacity, double offset
});




}
/// @nodoc
class _$BoldTextCopyWithImpl<$Res>
    implements $BoldTextCopyWith<$Res> {
  _$BoldTextCopyWithImpl(this._self, this._then);

  final BoldText _self;
  final $Res Function(BoldText) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uiOpacity = null,Object? offset = null,}) {
  return _then(BoldText(
uiOpacity: null == uiOpacity ? _self.uiOpacity : uiOpacity // ignore: cast_nullable_to_non_nullable
as double,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Philosophy implements SceneState {
  const Philosophy({this.offset = 0.0});
  

@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PhilosophyCopyWith<Philosophy> get copyWith => _$PhilosophyCopyWithImpl<Philosophy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Philosophy&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneState.philosophy(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $PhilosophyCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $PhilosophyCopyWith(Philosophy value, $Res Function(Philosophy) _then) = _$PhilosophyCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$PhilosophyCopyWithImpl<$Res>
    implements $PhilosophyCopyWith<$Res> {
  _$PhilosophyCopyWithImpl(this._self, this._then);

  final Philosophy _self;
  final $Res Function(Philosophy) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(Philosophy(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class WorkExperience implements SceneState {
  const WorkExperience({this.offset = 0.0});
  

@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkExperienceCopyWith<WorkExperience> get copyWith => _$WorkExperienceCopyWithImpl<WorkExperience>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkExperience&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneState.workExperience(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $WorkExperienceCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $WorkExperienceCopyWith(WorkExperience value, $Res Function(WorkExperience) _then) = _$WorkExperienceCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$WorkExperienceCopyWithImpl<$Res>
    implements $WorkExperienceCopyWith<$Res> {
  _$WorkExperienceCopyWithImpl(this._self, this._then);

  final WorkExperience _self;
  final $Res Function(WorkExperience) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(WorkExperience(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Experience implements SceneState {
  const Experience({this.offset = 0.0});
  

@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperienceCopyWith<Experience> get copyWith => _$ExperienceCopyWithImpl<Experience>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Experience&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneState.experience(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $ExperienceCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $ExperienceCopyWith(Experience value, $Res Function(Experience) _then) = _$ExperienceCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$ExperienceCopyWithImpl<$Res>
    implements $ExperienceCopyWith<$Res> {
  _$ExperienceCopyWithImpl(this._self, this._then);

  final Experience _self;
  final $Res Function(Experience) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(Experience(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Testimonials implements SceneState {
  const Testimonials({this.offset = 0.0});
  

@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TestimonialsCopyWith<Testimonials> get copyWith => _$TestimonialsCopyWithImpl<Testimonials>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Testimonials&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneState.testimonials(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $TestimonialsCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $TestimonialsCopyWith(Testimonials value, $Res Function(Testimonials) _then) = _$TestimonialsCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$TestimonialsCopyWithImpl<$Res>
    implements $TestimonialsCopyWith<$Res> {
  _$TestimonialsCopyWithImpl(this._self, this._then);

  final Testimonials _self;
  final $Res Function(Testimonials) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(Testimonials(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class Contact implements SceneState {
  const Contact({this.offset = 0.0});
  

@JsonKey() final  double offset;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactCopyWith<Contact> get copyWith => _$ContactCopyWithImpl<Contact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'SceneState.contact(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) = _$ContactCopyWithImpl;
@useResult
$Res call({
 double offset
});




}
/// @nodoc
class _$ContactCopyWithImpl<$Res>
    implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(Contact(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
