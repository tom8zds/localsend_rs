// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'simple.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$DiscoverState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DeviceInfo> field0) discovering,
    required TResult Function() done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DeviceInfo> field0)? discovering,
    TResult? Function()? done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DeviceInfo> field0)? discovering,
    TResult Function()? done,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscoverState_Discovering value) discovering,
    required TResult Function(DiscoverState_Done value) done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscoverState_Discovering value)? discovering,
    TResult? Function(DiscoverState_Done value)? done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscoverState_Discovering value)? discovering,
    TResult Function(DiscoverState_Done value)? done,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscoverStateCopyWith<$Res> {
  factory $DiscoverStateCopyWith(
          DiscoverState value, $Res Function(DiscoverState) then) =
      _$DiscoverStateCopyWithImpl<$Res, DiscoverState>;
}

/// @nodoc
class _$DiscoverStateCopyWithImpl<$Res, $Val extends DiscoverState>
    implements $DiscoverStateCopyWith<$Res> {
  _$DiscoverStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$DiscoverState_DiscoveringImplCopyWith<$Res> {
  factory _$$DiscoverState_DiscoveringImplCopyWith(
          _$DiscoverState_DiscoveringImpl value,
          $Res Function(_$DiscoverState_DiscoveringImpl) then) =
      __$$DiscoverState_DiscoveringImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<DeviceInfo> field0});
}

/// @nodoc
class __$$DiscoverState_DiscoveringImplCopyWithImpl<$Res>
    extends _$DiscoverStateCopyWithImpl<$Res, _$DiscoverState_DiscoveringImpl>
    implements _$$DiscoverState_DiscoveringImplCopyWith<$Res> {
  __$$DiscoverState_DiscoveringImplCopyWithImpl(
      _$DiscoverState_DiscoveringImpl _value,
      $Res Function(_$DiscoverState_DiscoveringImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$DiscoverState_DiscoveringImpl(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<DeviceInfo>,
    ));
  }
}

/// @nodoc

class _$DiscoverState_DiscoveringImpl implements DiscoverState_Discovering {
  const _$DiscoverState_DiscoveringImpl(final List<DeviceInfo> field0)
      : _field0 = field0;

  final List<DeviceInfo> _field0;
  @override
  List<DeviceInfo> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  @override
  String toString() {
    return 'DiscoverState.discovering(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscoverState_DiscoveringImpl &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscoverState_DiscoveringImplCopyWith<_$DiscoverState_DiscoveringImpl>
      get copyWith => __$$DiscoverState_DiscoveringImplCopyWithImpl<
          _$DiscoverState_DiscoveringImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DeviceInfo> field0) discovering,
    required TResult Function() done,
  }) {
    return discovering(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DeviceInfo> field0)? discovering,
    TResult? Function()? done,
  }) {
    return discovering?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DeviceInfo> field0)? discovering,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (discovering != null) {
      return discovering(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscoverState_Discovering value) discovering,
    required TResult Function(DiscoverState_Done value) done,
  }) {
    return discovering(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscoverState_Discovering value)? discovering,
    TResult? Function(DiscoverState_Done value)? done,
  }) {
    return discovering?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscoverState_Discovering value)? discovering,
    TResult Function(DiscoverState_Done value)? done,
    required TResult orElse(),
  }) {
    if (discovering != null) {
      return discovering(this);
    }
    return orElse();
  }
}

abstract class DiscoverState_Discovering implements DiscoverState {
  const factory DiscoverState_Discovering(final List<DeviceInfo> field0) =
      _$DiscoverState_DiscoveringImpl;

  List<DeviceInfo> get field0;
  @JsonKey(ignore: true)
  _$$DiscoverState_DiscoveringImplCopyWith<_$DiscoverState_DiscoveringImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DiscoverState_DoneImplCopyWith<$Res> {
  factory _$$DiscoverState_DoneImplCopyWith(_$DiscoverState_DoneImpl value,
          $Res Function(_$DiscoverState_DoneImpl) then) =
      __$$DiscoverState_DoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DiscoverState_DoneImplCopyWithImpl<$Res>
    extends _$DiscoverStateCopyWithImpl<$Res, _$DiscoverState_DoneImpl>
    implements _$$DiscoverState_DoneImplCopyWith<$Res> {
  __$$DiscoverState_DoneImplCopyWithImpl(_$DiscoverState_DoneImpl _value,
      $Res Function(_$DiscoverState_DoneImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$DiscoverState_DoneImpl implements DiscoverState_Done {
  const _$DiscoverState_DoneImpl();

  @override
  String toString() {
    return 'DiscoverState.done()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DiscoverState_DoneImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<DeviceInfo> field0) discovering,
    required TResult Function() done,
  }) {
    return done();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<DeviceInfo> field0)? discovering,
    TResult? Function()? done,
  }) {
    return done?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<DeviceInfo> field0)? discovering,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscoverState_Discovering value) discovering,
    required TResult Function(DiscoverState_Done value) done,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscoverState_Discovering value)? discovering,
    TResult? Function(DiscoverState_Done value)? done,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscoverState_Discovering value)? discovering,
    TResult Function(DiscoverState_Done value)? done,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }
}

abstract class DiscoverState_Done implements DiscoverState {
  const factory DiscoverState_Done() = _$DiscoverState_DoneImpl;
}
