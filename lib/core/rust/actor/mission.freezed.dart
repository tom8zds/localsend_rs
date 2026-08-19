// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mission.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FileState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FileState()';
  }
}

/// @nodoc
class $FileStateCopyWith<$Res> {
  $FileStateCopyWith(FileState _, $Res Function(FileState) __);
}

/// Adds pattern-matching-related methods to [FileState].
extension FileStatePatterns on FileState {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FileState_Pending value)? pending,
    TResult Function(FileState_Transfer value)? transfer,
    TResult Function(FileState_Finish value)? finish,
    TResult Function(FileState_Skip value)? skip,
    TResult Function(FileState_Fail value)? fail,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending() when pending != null:
        return pending(_that);
      case FileState_Transfer() when transfer != null:
        return transfer(_that);
      case FileState_Finish() when finish != null:
        return finish(_that);
      case FileState_Skip() when skip != null:
        return skip(_that);
      case FileState_Fail() when fail != null:
        return fail(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FileState_Pending value) pending,
    required TResult Function(FileState_Transfer value) transfer,
    required TResult Function(FileState_Finish value) finish,
    required TResult Function(FileState_Skip value) skip,
    required TResult Function(FileState_Fail value) fail,
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending():
        return pending(_that);
      case FileState_Transfer():
        return transfer(_that);
      case FileState_Finish():
        return finish(_that);
      case FileState_Skip():
        return skip(_that);
      case FileState_Fail():
        return fail(_that);
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FileState_Pending value)? pending,
    TResult? Function(FileState_Transfer value)? transfer,
    TResult? Function(FileState_Finish value)? finish,
    TResult? Function(FileState_Skip value)? skip,
    TResult? Function(FileState_Fail value)? fail,
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending() when pending != null:
        return pending(_that);
      case FileState_Transfer() when transfer != null:
        return transfer(_that);
      case FileState_Finish() when finish != null:
        return finish(_that);
      case FileState_Skip() when skip != null:
        return skip(_that);
      case FileState_Fail() when fail != null:
        return fail(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? pending,
    TResult Function()? transfer,
    TResult Function()? finish,
    TResult Function()? skip,
    TResult Function(String msg)? fail,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending() when pending != null:
        return pending();
      case FileState_Transfer() when transfer != null:
        return transfer();
      case FileState_Finish() when finish != null:
        return finish();
      case FileState_Skip() when skip != null:
        return skip();
      case FileState_Fail() when fail != null:
        return fail(_that.msg);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() pending,
    required TResult Function() transfer,
    required TResult Function() finish,
    required TResult Function() skip,
    required TResult Function(String msg) fail,
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending():
        return pending();
      case FileState_Transfer():
        return transfer();
      case FileState_Finish():
        return finish();
      case FileState_Skip():
        return skip();
      case FileState_Fail():
        return fail(_that.msg);
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? pending,
    TResult? Function()? transfer,
    TResult? Function()? finish,
    TResult? Function()? skip,
    TResult? Function(String msg)? fail,
  }) {
    final _that = this;
    switch (_that) {
      case FileState_Pending() when pending != null:
        return pending();
      case FileState_Transfer() when transfer != null:
        return transfer();
      case FileState_Finish() when finish != null:
        return finish();
      case FileState_Skip() when skip != null:
        return skip();
      case FileState_Fail() when fail != null:
        return fail(_that.msg);
      case _:
        return null;
    }
  }
}

/// @nodoc

class FileState_Pending extends FileState {
  const FileState_Pending() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FileState_Pending);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FileState.pending()';
  }
}

/// @nodoc

class FileState_Transfer extends FileState {
  const FileState_Transfer() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FileState_Transfer);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FileState.transfer()';
  }
}

/// @nodoc

class FileState_Finish extends FileState {
  const FileState_Finish() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FileState_Finish);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FileState.finish()';
  }
}

/// @nodoc

class FileState_Skip extends FileState {
  const FileState_Skip() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FileState_Skip);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FileState.skip()';
  }
}

/// @nodoc

class FileState_Fail extends FileState {
  const FileState_Fail({required this.msg}) : super._();

  final String msg;

  /// Create a copy of FileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FileState_FailCopyWith<FileState_Fail> get copyWith =>
      _$FileState_FailCopyWithImpl<FileState_Fail>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FileState_Fail &&
            (identical(other.msg, msg) || other.msg == msg));
  }

  @override
  int get hashCode => Object.hash(runtimeType, msg);

  @override
  String toString() {
    return 'FileState.fail(msg: $msg)';
  }
}

/// @nodoc
abstract mixin class $FileState_FailCopyWith<$Res>
    implements $FileStateCopyWith<$Res> {
  factory $FileState_FailCopyWith(
          FileState_Fail value, $Res Function(FileState_Fail) _then) =
      _$FileState_FailCopyWithImpl;
  @useResult
  $Res call({String msg});
}

/// @nodoc
class _$FileState_FailCopyWithImpl<$Res>
    implements $FileState_FailCopyWith<$Res> {
  _$FileState_FailCopyWithImpl(this._self, this._then);

  final FileState_Fail _self;
  final $Res Function(FileState_Fail) _then;

  /// Create a copy of FileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? msg = null,
  }) {
    return _then(FileState_Fail(
      msg: null == msg
          ? _self.msg
          : msg // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
