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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Status {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatusCopyWith<$Res> {
  factory $StatusCopyWith(Status value, $Res Function(Status) then) =
      _$StatusCopyWithImpl<$Res, Status>;
}

/// @nodoc
class _$StatusCopyWithImpl<$Res, $Val extends Status>
    implements $StatusCopyWith<$Res> {
  _$StatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$Status_PendingImplCopyWith<$Res> {
  factory _$$Status_PendingImplCopyWith(_$Status_PendingImpl value,
          $Res Function(_$Status_PendingImpl) then) =
      __$$Status_PendingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Status_PendingImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_PendingImpl>
    implements _$$Status_PendingImplCopyWith<$Res> {
  __$$Status_PendingImplCopyWithImpl(
      _$Status_PendingImpl _value, $Res Function(_$Status_PendingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Status_PendingImpl extends Status_Pending {
  const _$Status_PendingImpl() : super._();

  @override
  String toString() {
    return 'Status.pending()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Status_PendingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return pending();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return pending?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
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
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return pending(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return pending?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (pending != null) {
      return pending(this);
    }
    return orElse();
  }
}

abstract class Status_Pending extends Status {
  const factory Status_Pending() = _$Status_PendingImpl;
  const Status_Pending._() : super._();
}

/// @nodoc
abstract class _$$Status_TransferImplCopyWith<$Res> {
  factory _$$Status_TransferImplCopyWith(_$Status_TransferImpl value,
          $Res Function(_$Status_TransferImpl) then) =
      __$$Status_TransferImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BigInt startTime});
}

/// @nodoc
class __$$Status_TransferImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_TransferImpl>
    implements _$$Status_TransferImplCopyWith<$Res> {
  __$$Status_TransferImplCopyWithImpl(
      _$Status_TransferImpl _value, $Res Function(_$Status_TransferImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
  }) {
    return _then(_$Status_TransferImpl(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as BigInt,
    ));
  }
}

/// @nodoc

class _$Status_TransferImpl extends Status_Transfer {
  const _$Status_TransferImpl({required this.startTime}) : super._();

  @override
  final BigInt startTime;

  @override
  String toString() {
    return 'Status.transfer(startTime: $startTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Status_TransferImpl &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime));
  }

  @override
  int get hashCode => Object.hash(runtimeType, startTime);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Status_TransferImplCopyWith<_$Status_TransferImpl> get copyWith =>
      __$$Status_TransferImplCopyWithImpl<_$Status_TransferImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return transfer(startTime);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return transfer?.call(startTime);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
    required TResult orElse(),
  }) {
    if (transfer != null) {
      return transfer(startTime);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return transfer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return transfer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (transfer != null) {
      return transfer(this);
    }
    return orElse();
  }
}

abstract class Status_Transfer extends Status {
  const factory Status_Transfer({required final BigInt startTime}) =
      _$Status_TransferImpl;
  const Status_Transfer._() : super._();

  BigInt get startTime;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Status_TransferImplCopyWith<_$Status_TransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Status_FinishImplCopyWith<$Res> {
  factory _$$Status_FinishImplCopyWith(
          _$Status_FinishImpl value, $Res Function(_$Status_FinishImpl) then) =
      __$$Status_FinishImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Status_FinishImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_FinishImpl>
    implements _$$Status_FinishImplCopyWith<$Res> {
  __$$Status_FinishImplCopyWithImpl(
      _$Status_FinishImpl _value, $Res Function(_$Status_FinishImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Status_FinishImpl extends Status_Finish {
  const _$Status_FinishImpl() : super._();

  @override
  String toString() {
    return 'Status.finish()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Status_FinishImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return finish();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return finish?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
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
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return finish(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return finish?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (finish != null) {
      return finish(this);
    }
    return orElse();
  }
}

abstract class Status_Finish extends Status {
  const factory Status_Finish() = _$Status_FinishImpl;
  const Status_Finish._() : super._();
}

/// @nodoc
abstract class _$$Status_FailImplCopyWith<$Res> {
  factory _$$Status_FailImplCopyWith(
          _$Status_FailImpl value, $Res Function(_$Status_FailImpl) then) =
      __$$Status_FailImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String msg});
}

/// @nodoc
class __$$Status_FailImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_FailImpl>
    implements _$$Status_FailImplCopyWith<$Res> {
  __$$Status_FailImplCopyWithImpl(
      _$Status_FailImpl _value, $Res Function(_$Status_FailImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msg = null,
  }) {
    return _then(_$Status_FailImpl(
      msg: null == msg
          ? _value.msg
          : msg // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$Status_FailImpl extends Status_Fail {
  const _$Status_FailImpl({required this.msg}) : super._();

  @override
  final String msg;

  @override
  String toString() {
    return 'Status.fail(msg: $msg)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$Status_FailImpl &&
            (identical(other.msg, msg) || other.msg == msg));
  }

  @override
  int get hashCode => Object.hash(runtimeType, msg);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$Status_FailImplCopyWith<_$Status_FailImpl> get copyWith =>
      __$$Status_FailImplCopyWithImpl<_$Status_FailImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return fail(msg);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return fail?.call(msg);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
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
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return fail(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return fail?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (fail != null) {
      return fail(this);
    }
    return orElse();
  }
}

abstract class Status_Fail extends Status {
  const factory Status_Fail({required final String msg}) = _$Status_FailImpl;
  const Status_Fail._() : super._();

  String get msg;

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$Status_FailImplCopyWith<_$Status_FailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$Status_CancelImplCopyWith<$Res> {
  factory _$$Status_CancelImplCopyWith(
          _$Status_CancelImpl value, $Res Function(_$Status_CancelImpl) then) =
      __$$Status_CancelImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Status_CancelImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_CancelImpl>
    implements _$$Status_CancelImplCopyWith<$Res> {
  __$$Status_CancelImplCopyWithImpl(
      _$Status_CancelImpl _value, $Res Function(_$Status_CancelImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Status_CancelImpl extends Status_Cancel {
  const _$Status_CancelImpl() : super._();

  @override
  String toString() {
    return 'Status.cancel()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Status_CancelImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return cancel();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return cancel?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
    required TResult orElse(),
  }) {
    if (cancel != null) {
      return cancel();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return cancel(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return cancel?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (cancel != null) {
      return cancel(this);
    }
    return orElse();
  }
}

abstract class Status_Cancel extends Status {
  const factory Status_Cancel() = _$Status_CancelImpl;
  const Status_Cancel._() : super._();
}

/// @nodoc
abstract class _$$Status_RejectedImplCopyWith<$Res> {
  factory _$$Status_RejectedImplCopyWith(_$Status_RejectedImpl value,
          $Res Function(_$Status_RejectedImpl) then) =
      __$$Status_RejectedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$Status_RejectedImplCopyWithImpl<$Res>
    extends _$StatusCopyWithImpl<$Res, _$Status_RejectedImpl>
    implements _$$Status_RejectedImplCopyWith<$Res> {
  __$$Status_RejectedImplCopyWithImpl(
      _$Status_RejectedImpl _value, $Res Function(_$Status_RejectedImpl) _then)
      : super(_value, _then);

  /// Create a copy of Status
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$Status_RejectedImpl extends Status_Rejected {
  const _$Status_RejectedImpl() : super._();

  @override
  String toString() {
    return 'Status.rejected()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$Status_RejectedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function(BigInt startTime) transfer,
    required TResult Function() finish,
    required TResult Function(String msg) fail,
    required TResult Function() cancel,
    required TResult Function() rejected,
  }) {
    return rejected();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function(BigInt startTime)? transfer,
    TResult? Function()? finish,
    TResult? Function(String msg)? fail,
    TResult? Function()? cancel,
    TResult? Function()? rejected,
  }) {
    return rejected?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function(BigInt startTime)? transfer,
    TResult Function()? finish,
    TResult Function(String msg)? fail,
    TResult Function()? cancel,
    TResult Function()? rejected,
    required TResult orElse(),
  }) {
    if (rejected != null) {
      return rejected();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Status_Pending value) pending,
    required TResult Function(Status_Transfer value) transfer,
    required TResult Function(Status_Finish value) finish,
    required TResult Function(Status_Fail value) fail,
    required TResult Function(Status_Cancel value) cancel,
    required TResult Function(Status_Rejected value) rejected,
  }) {
    return rejected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Status_Pending value)? pending,
    TResult? Function(Status_Transfer value)? transfer,
    TResult? Function(Status_Finish value)? finish,
    TResult? Function(Status_Fail value)? fail,
    TResult? Function(Status_Cancel value)? cancel,
    TResult? Function(Status_Rejected value)? rejected,
  }) {
    return rejected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Status_Pending value)? pending,
    TResult Function(Status_Transfer value)? transfer,
    TResult Function(Status_Finish value)? finish,
    TResult Function(Status_Fail value)? fail,
    TResult Function(Status_Cancel value)? cancel,
    TResult Function(Status_Rejected value)? rejected,
    required TResult orElse(),
  }) {
    if (rejected != null) {
      return rejected(this);
    }
    return orElse();
  }
}

abstract class Status_Rejected extends Status {
  const factory Status_Rejected() = _$Status_RejectedImpl;
  const Status_Rejected._() : super._();
}
