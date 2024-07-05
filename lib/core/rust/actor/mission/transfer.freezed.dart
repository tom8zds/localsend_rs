// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TransferState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferStateCopyWith<$Res> {
  factory $TransferStateCopyWith(
          TransferState value, $Res Function(TransferState) then) =
      _$TransferStateCopyWithImpl<$Res, TransferState>;
}

/// @nodoc
class _$TransferStateCopyWithImpl<$Res, $Val extends TransferState>
    implements $TransferStateCopyWith<$Res> {
  _$TransferStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$TransferState_PendingImplCopyWith<$Res> {
  factory _$$TransferState_PendingImplCopyWith(
          _$TransferState_PendingImpl value,
          $Res Function(_$TransferState_PendingImpl) then) =
      __$$TransferState_PendingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferState_PendingImplCopyWithImpl<$Res>
    extends _$TransferStateCopyWithImpl<$Res, _$TransferState_PendingImpl>
    implements _$$TransferState_PendingImplCopyWith<$Res> {
  __$$TransferState_PendingImplCopyWithImpl(_$TransferState_PendingImpl _value,
      $Res Function(_$TransferState_PendingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferState_PendingImpl extends TransferState_Pending {
  const _$TransferState_PendingImpl() : super._();

  @override
  String toString() {
    return 'TransferState.pending()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferState_PendingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    return pending();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    return pending?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    if (pending != null) {
      return pending();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) {
    return pending(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) {
    return pending?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) {
    if (pending != null) {
      return pending(this);
    }
    return orElse();
  }
}

abstract class TransferState_Pending extends TransferState {
  const factory TransferState_Pending() = _$TransferState_PendingImpl;
  const TransferState_Pending._() : super._();
}

/// @nodoc
abstract class _$$TransferState_TransferImplCopyWith<$Res> {
  factory _$$TransferState_TransferImplCopyWith(
          _$TransferState_TransferImpl value,
          $Res Function(_$TransferState_TransferImpl) then) =
      __$$TransferState_TransferImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferState_TransferImplCopyWithImpl<$Res>
    extends _$TransferStateCopyWithImpl<$Res, _$TransferState_TransferImpl>
    implements _$$TransferState_TransferImplCopyWith<$Res> {
  __$$TransferState_TransferImplCopyWithImpl(
      _$TransferState_TransferImpl _value,
      $Res Function(_$TransferState_TransferImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferState_TransferImpl extends TransferState_Transfer {
  const _$TransferState_TransferImpl() : super._();

  @override
  String toString() {
    return 'TransferState.transfer()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferState_TransferImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    return transfer();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    return transfer?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    if (transfer != null) {
      return transfer();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) {
    return transfer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) {
    return transfer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) {
    if (transfer != null) {
      return transfer(this);
    }
    return orElse();
  }
}

abstract class TransferState_Transfer extends TransferState {
  const factory TransferState_Transfer() = _$TransferState_TransferImpl;
  const TransferState_Transfer._() : super._();
}

/// @nodoc
abstract class _$$TransferState_FinishImplCopyWith<$Res> {
  factory _$$TransferState_FinishImplCopyWith(_$TransferState_FinishImpl value,
          $Res Function(_$TransferState_FinishImpl) then) =
      __$$TransferState_FinishImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferState_FinishImplCopyWithImpl<$Res>
    extends _$TransferStateCopyWithImpl<$Res, _$TransferState_FinishImpl>
    implements _$$TransferState_FinishImplCopyWith<$Res> {
  __$$TransferState_FinishImplCopyWithImpl(_$TransferState_FinishImpl _value,
      $Res Function(_$TransferState_FinishImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferState_FinishImpl extends TransferState_Finish {
  const _$TransferState_FinishImpl() : super._();

  @override
  String toString() {
    return 'TransferState.finish()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferState_FinishImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    return finish();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    return finish?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    if (finish != null) {
      return finish();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) {
    return finish(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) {
    return finish?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) {
    if (finish != null) {
      return finish(this);
    }
    return orElse();
  }
}

abstract class TransferState_Finish extends TransferState {
  const factory TransferState_Finish() = _$TransferState_FinishImpl;
  const TransferState_Finish._() : super._();
}

/// @nodoc
abstract class _$$TransferState_SkipImplCopyWith<$Res> {
  factory _$$TransferState_SkipImplCopyWith(_$TransferState_SkipImpl value,
          $Res Function(_$TransferState_SkipImpl) then) =
      __$$TransferState_SkipImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferState_SkipImplCopyWithImpl<$Res>
    extends _$TransferStateCopyWithImpl<$Res, _$TransferState_SkipImpl>
    implements _$$TransferState_SkipImplCopyWith<$Res> {
  __$$TransferState_SkipImplCopyWithImpl(_$TransferState_SkipImpl _value,
      $Res Function(_$TransferState_SkipImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferState_SkipImpl extends TransferState_Skip {
  const _$TransferState_SkipImpl() : super._();

  @override
  String toString() {
    return 'TransferState.skip()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TransferState_SkipImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    return skip();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    return skip?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    if (skip != null) {
      return skip();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) {
    return skip(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) {
    return skip?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) {
    if (skip != null) {
      return skip(this);
    }
    return orElse();
  }
}

abstract class TransferState_Skip extends TransferState {
  const factory TransferState_Skip() = _$TransferState_SkipImpl;
  const TransferState_Skip._() : super._();
}

/// @nodoc
abstract class _$$TransferState_FailImplCopyWith<$Res> {
  factory _$$TransferState_FailImplCopyWith(_$TransferState_FailImpl value,
          $Res Function(_$TransferState_FailImpl) then) =
      __$$TransferState_FailImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String msg});
}

/// @nodoc
class __$$TransferState_FailImplCopyWithImpl<$Res>
    extends _$TransferStateCopyWithImpl<$Res, _$TransferState_FailImpl>
    implements _$$TransferState_FailImplCopyWith<$Res> {
  __$$TransferState_FailImplCopyWithImpl(_$TransferState_FailImpl _value,
      $Res Function(_$TransferState_FailImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msg = null,
  }) {
    return _then(_$TransferState_FailImpl(
      msg: null == msg
          ? _value.msg
          : msg // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransferState_FailImpl extends TransferState_Fail {
  const _$TransferState_FailImpl({required this.msg}) : super._();

  @override
  final String msg;

  @override
  String toString() {
    return 'TransferState.fail(msg: $msg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferState_FailImpl &&
            (identical(other.msg, msg) || other.msg == msg));
  }

  @override
  int get hashCode => Object.hash(runtimeType, msg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferState_FailImplCopyWith<_$TransferState_FailImpl> get copyWith =>
      __$$TransferState_FailImplCopyWithImpl<_$TransferState_FailImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    return fail(msg);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    return fail?.call(msg);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    if (fail != null) {
      return fail(msg);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferState_Pending value) pending,
    required TResult Function(TransferState_Transfer value) transfer,
    required TResult Function(TransferState_Finish value) finish,
    required TResult Function(TransferState_Skip value) skip,
    required TResult Function(TransferState_Fail value) fail,
  }) {
    return fail(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferState_Pending value)? pending,
    TResult? Function(TransferState_Transfer value)? transfer,
    TResult? Function(TransferState_Finish value)? finish,
    TResult? Function(TransferState_Skip value)? skip,
    TResult? Function(TransferState_Fail value)? fail,
  }) {
    return fail?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferState_Pending value)? pending,
    TResult Function(TransferState_Transfer value)? transfer,
    TResult Function(TransferState_Finish value)? finish,
    TResult Function(TransferState_Skip value)? skip,
    TResult Function(TransferState_Fail value)? fail,
    required TResult orElse(),
  }) {
    if (fail != null) {
      return fail(this);
    }
    return orElse();
  }
}

abstract class TransferState_Fail extends TransferState {
  const factory TransferState_Fail({required final String msg}) =
      _$TransferState_FailImpl;
  const TransferState_Fail._() : super._();

  String get msg;
  @JsonKey(ignore: true)
  _$$TransferState_FailImplCopyWith<_$TransferState_FailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
