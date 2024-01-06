// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Progress {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(int field0, int field1) progress,
    required TResult Function() done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(int field0, int field1)? progress,
    TResult? Function()? done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(int field0, int field1)? progress,
    TResult Function()? done,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Progress_Idle value) idle,
    required TResult Function(Progress_Progress value) progress,
    required TResult Function(Progress_Done value) done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Progress_Idle value)? idle,
    TResult? Function(Progress_Progress value)? progress,
    TResult? Function(Progress_Done value)? done,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Progress_Idle value)? idle,
    TResult Function(Progress_Progress value)? progress,
    TResult Function(Progress_Done value)? done,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressCopyWith<$Res> {
  factory $ProgressCopyWith(Progress value, $Res Function(Progress) then) =
      _$ProgressCopyWithImpl<$Res, Progress>;
}

/// @nodoc
class _$ProgressCopyWithImpl<$Res, $Val extends Progress>
    implements $ProgressCopyWith<$Res> {
  _$ProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$Progress_IdleImplCopyWith<$Res> {
  factory _$$Progress_IdleImplCopyWith(
          _$Progress_IdleImpl value, $Res Function(_$Progress_IdleImpl) then) =
      __$$Progress_IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Progress_IdleImplCopyWithImpl<$Res>
    extends _$ProgressCopyWithImpl<$Res, _$Progress_IdleImpl>
    implements _$$Progress_IdleImplCopyWith<$Res> {
  __$$Progress_IdleImplCopyWithImpl(
      _$Progress_IdleImpl _value, $Res Function(_$Progress_IdleImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$Progress_IdleImpl implements Progress_Idle {
  const _$Progress_IdleImpl();

  @override
  String toString() {
    return 'Progress.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Progress_IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(int field0, int field1) progress,
    required TResult Function() done,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(int field0, int field1)? progress,
    TResult? Function()? done,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(int field0, int field1)? progress,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Progress_Idle value) idle,
    required TResult Function(Progress_Progress value) progress,
    required TResult Function(Progress_Done value) done,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Progress_Idle value)? idle,
    TResult? Function(Progress_Progress value)? progress,
    TResult? Function(Progress_Done value)? done,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Progress_Idle value)? idle,
    TResult Function(Progress_Progress value)? progress,
    TResult Function(Progress_Done value)? done,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class Progress_Idle implements Progress {
  const factory Progress_Idle() = _$Progress_IdleImpl;
}

/// @nodoc
abstract class _$$Progress_ProgressImplCopyWith<$Res> {
  factory _$$Progress_ProgressImplCopyWith(_$Progress_ProgressImpl value,
          $Res Function(_$Progress_ProgressImpl) then) =
      __$$Progress_ProgressImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int field0, int field1});
}

/// @nodoc
class __$$Progress_ProgressImplCopyWithImpl<$Res>
    extends _$ProgressCopyWithImpl<$Res, _$Progress_ProgressImpl>
    implements _$$Progress_ProgressImplCopyWith<$Res> {
  __$$Progress_ProgressImplCopyWithImpl(_$Progress_ProgressImpl _value,
      $Res Function(_$Progress_ProgressImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
    Object? field1 = null,
  }) {
    return _then(_$Progress_ProgressImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as int,
      null == field1
          ? _value.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$Progress_ProgressImpl implements Progress_Progress {
  const _$Progress_ProgressImpl(this.field0, this.field1);

  @override
  final int field0;
  @override
  final int field1;

  @override
  String toString() {
    return 'Progress.progress(field0: $field0, field1: $field1)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Progress_ProgressImpl &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0, field1);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$Progress_ProgressImplCopyWith<_$Progress_ProgressImpl> get copyWith =>
      __$$Progress_ProgressImplCopyWithImpl<_$Progress_ProgressImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(int field0, int field1) progress,
    required TResult Function() done,
  }) {
    return progress(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(int field0, int field1)? progress,
    TResult? Function()? done,
  }) {
    return progress?.call(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(int field0, int field1)? progress,
    TResult Function()? done,
    required TResult orElse(),
  }) {
    if (progress != null) {
      return progress(field0, field1);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Progress_Idle value) idle,
    required TResult Function(Progress_Progress value) progress,
    required TResult Function(Progress_Done value) done,
  }) {
    return progress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Progress_Idle value)? idle,
    TResult? Function(Progress_Progress value)? progress,
    TResult? Function(Progress_Done value)? done,
  }) {
    return progress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Progress_Idle value)? idle,
    TResult Function(Progress_Progress value)? progress,
    TResult Function(Progress_Done value)? done,
    required TResult orElse(),
  }) {
    if (progress != null) {
      return progress(this);
    }
    return orElse();
  }
}

abstract class Progress_Progress implements Progress {
  const factory Progress_Progress(final int field0, final int field1) =
      _$Progress_ProgressImpl;

  int get field0;
  int get field1;
  @JsonKey(ignore: true)
  _$$Progress_ProgressImplCopyWith<_$Progress_ProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Progress_DoneImplCopyWith<$Res> {
  factory _$$Progress_DoneImplCopyWith(
          _$Progress_DoneImpl value, $Res Function(_$Progress_DoneImpl) then) =
      __$$Progress_DoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Progress_DoneImplCopyWithImpl<$Res>
    extends _$ProgressCopyWithImpl<$Res, _$Progress_DoneImpl>
    implements _$$Progress_DoneImplCopyWith<$Res> {
  __$$Progress_DoneImplCopyWithImpl(
      _$Progress_DoneImpl _value, $Res Function(_$Progress_DoneImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$Progress_DoneImpl implements Progress_Done {
  const _$Progress_DoneImpl();

  @override
  String toString() {
    return 'Progress.done()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Progress_DoneImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(int field0, int field1) progress,
    required TResult Function() done,
  }) {
    return done();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(int field0, int field1)? progress,
    TResult? Function()? done,
  }) {
    return done?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(int field0, int field1)? progress,
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
    required TResult Function(Progress_Idle value) idle,
    required TResult Function(Progress_Progress value) progress,
    required TResult Function(Progress_Done value) done,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Progress_Idle value)? idle,
    TResult? Function(Progress_Progress value)? progress,
    TResult? Function(Progress_Done value)? done,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Progress_Idle value)? idle,
    TResult Function(Progress_Progress value)? progress,
    TResult Function(Progress_Done value)? done,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }
}

abstract class Progress_Done implements Progress {
  const factory Progress_Done() = _$Progress_DoneImpl;
}
