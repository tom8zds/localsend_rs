// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

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

/// @nodoc
mixin _$SessionEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SessionEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SessionEvent()';
  }
}

/// @nodoc
class $SessionEventCopyWith<$Res> {
  $SessionEventCopyWith(SessionEvent _, $Res Function(SessionEvent) __);
}

/// Adds pattern-matching-related methods to [SessionEvent].
extension SessionEventPatterns on SessionEvent {
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
    TResult Function(SessionEvent_StateChanged value)? stateChanged,
    TResult Function(SessionEvent_FileStateChanged value)? fileStateChanged,
    TResult Function(SessionEvent_Progress value)? progress,
    TResult Function(SessionEvent_Failed value)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged() when stateChanged != null:
        return stateChanged(_that);
      case SessionEvent_FileStateChanged() when fileStateChanged != null:
        return fileStateChanged(_that);
      case SessionEvent_Progress() when progress != null:
        return progress(_that);
      case SessionEvent_Failed() when failed != null:
        return failed(_that);
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
    required TResult Function(SessionEvent_StateChanged value) stateChanged,
    required TResult Function(SessionEvent_FileStateChanged value)
        fileStateChanged,
    required TResult Function(SessionEvent_Progress value) progress,
    required TResult Function(SessionEvent_Failed value) failed,
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged():
        return stateChanged(_that);
      case SessionEvent_FileStateChanged():
        return fileStateChanged(_that);
      case SessionEvent_Progress():
        return progress(_that);
      case SessionEvent_Failed():
        return failed(_that);
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
    TResult? Function(SessionEvent_StateChanged value)? stateChanged,
    TResult? Function(SessionEvent_FileStateChanged value)? fileStateChanged,
    TResult? Function(SessionEvent_Progress value)? progress,
    TResult? Function(SessionEvent_Failed value)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged() when stateChanged != null:
        return stateChanged(_that);
      case SessionEvent_FileStateChanged() when fileStateChanged != null:
        return fileStateChanged(_that);
      case SessionEvent_Progress() when progress != null:
        return progress(_that);
      case SessionEvent_Failed() when failed != null:
        return failed(_that);
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
    TResult Function(MissionState field0)? stateChanged,
    TResult Function(String fileId, FileState state)? fileStateChanged,
    TResult Function(String fileId, PlatformInt64 bytes)? progress,
    TResult Function(String reason)? failed,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged() when stateChanged != null:
        return stateChanged(_that.field0);
      case SessionEvent_FileStateChanged() when fileStateChanged != null:
        return fileStateChanged(_that.fileId, _that.state);
      case SessionEvent_Progress() when progress != null:
        return progress(_that.fileId, _that.bytes);
      case SessionEvent_Failed() when failed != null:
        return failed(_that.reason);
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
    required TResult Function(MissionState field0) stateChanged,
    required TResult Function(String fileId, FileState state) fileStateChanged,
    required TResult Function(String fileId, PlatformInt64 bytes) progress,
    required TResult Function(String reason) failed,
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged():
        return stateChanged(_that.field0);
      case SessionEvent_FileStateChanged():
        return fileStateChanged(_that.fileId, _that.state);
      case SessionEvent_Progress():
        return progress(_that.fileId, _that.bytes);
      case SessionEvent_Failed():
        return failed(_that.reason);
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
    TResult? Function(MissionState field0)? stateChanged,
    TResult? Function(String fileId, FileState state)? fileStateChanged,
    TResult? Function(String fileId, PlatformInt64 bytes)? progress,
    TResult? Function(String reason)? failed,
  }) {
    final _that = this;
    switch (_that) {
      case SessionEvent_StateChanged() when stateChanged != null:
        return stateChanged(_that.field0);
      case SessionEvent_FileStateChanged() when fileStateChanged != null:
        return fileStateChanged(_that.fileId, _that.state);
      case SessionEvent_Progress() when progress != null:
        return progress(_that.fileId, _that.bytes);
      case SessionEvent_Failed() when failed != null:
        return failed(_that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc

class SessionEvent_StateChanged extends SessionEvent {
  const SessionEvent_StateChanged(this.field0) : super._();

  final MissionState field0;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SessionEvent_StateChangedCopyWith<SessionEvent_StateChanged> get copyWith =>
      _$SessionEvent_StateChangedCopyWithImpl<SessionEvent_StateChanged>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SessionEvent_StateChanged &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @override
  String toString() {
    return 'SessionEvent.stateChanged(field0: $field0)';
  }
}

/// @nodoc
abstract mixin class $SessionEvent_StateChangedCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_StateChangedCopyWith(SessionEvent_StateChanged value,
          $Res Function(SessionEvent_StateChanged) _then) =
      _$SessionEvent_StateChangedCopyWithImpl;
  @useResult
  $Res call({MissionState field0});
}

/// @nodoc
class _$SessionEvent_StateChangedCopyWithImpl<$Res>
    implements $SessionEvent_StateChangedCopyWith<$Res> {
  _$SessionEvent_StateChangedCopyWithImpl(this._self, this._then);

  final SessionEvent_StateChanged _self;
  final $Res Function(SessionEvent_StateChanged) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? field0 = null,
  }) {
    return _then(SessionEvent_StateChanged(
      null == field0
          ? _self.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as MissionState,
    ));
  }
}

/// @nodoc

class SessionEvent_FileStateChanged extends SessionEvent {
  const SessionEvent_FileStateChanged(
      {required this.fileId, required this.state})
      : super._();

  final String fileId;
  final FileState state;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SessionEvent_FileStateChangedCopyWith<SessionEvent_FileStateChanged>
      get copyWith => _$SessionEvent_FileStateChangedCopyWithImpl<
          SessionEvent_FileStateChanged>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SessionEvent_FileStateChanged &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.state, state) || other.state == state));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileId, state);

  @override
  String toString() {
    return 'SessionEvent.fileStateChanged(fileId: $fileId, state: $state)';
  }
}

/// @nodoc
abstract mixin class $SessionEvent_FileStateChangedCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_FileStateChangedCopyWith(
          SessionEvent_FileStateChanged value,
          $Res Function(SessionEvent_FileStateChanged) _then) =
      _$SessionEvent_FileStateChangedCopyWithImpl;
  @useResult
  $Res call({String fileId, FileState state});

  $FileStateCopyWith<$Res> get state;
}

/// @nodoc
class _$SessionEvent_FileStateChangedCopyWithImpl<$Res>
    implements $SessionEvent_FileStateChangedCopyWith<$Res> {
  _$SessionEvent_FileStateChangedCopyWithImpl(this._self, this._then);

  final SessionEvent_FileStateChanged _self;
  final $Res Function(SessionEvent_FileStateChanged) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileId = null,
    Object? state = null,
  }) {
    return _then(SessionEvent_FileStateChanged(
      fileId: null == fileId
          ? _self.fileId
          : fileId // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as FileState,
    ));
  }

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FileStateCopyWith<$Res> get state {
    return $FileStateCopyWith<$Res>(_self.state, (value) {
      return _then(_self.copyWith(state: value));
    });
  }
}

/// @nodoc

class SessionEvent_Progress extends SessionEvent {
  const SessionEvent_Progress({required this.fileId, required this.bytes})
      : super._();

  final String fileId;
  final PlatformInt64 bytes;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SessionEvent_ProgressCopyWith<SessionEvent_Progress> get copyWith =>
      _$SessionEvent_ProgressCopyWithImpl<SessionEvent_Progress>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SessionEvent_Progress &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.bytes, bytes) || other.bytes == bytes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileId, bytes);

  @override
  String toString() {
    return 'SessionEvent.progress(fileId: $fileId, bytes: $bytes)';
  }
}

/// @nodoc
abstract mixin class $SessionEvent_ProgressCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_ProgressCopyWith(SessionEvent_Progress value,
          $Res Function(SessionEvent_Progress) _then) =
      _$SessionEvent_ProgressCopyWithImpl;
  @useResult
  $Res call({String fileId, PlatformInt64 bytes});
}

/// @nodoc
class _$SessionEvent_ProgressCopyWithImpl<$Res>
    implements $SessionEvent_ProgressCopyWith<$Res> {
  _$SessionEvent_ProgressCopyWithImpl(this._self, this._then);

  final SessionEvent_Progress _self;
  final $Res Function(SessionEvent_Progress) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileId = null,
    Object? bytes = null,
  }) {
    return _then(SessionEvent_Progress(
      fileId: null == fileId
          ? _self.fileId
          : fileId // ignore: cast_nullable_to_non_nullable
              as String,
      bytes: null == bytes
          ? _self.bytes
          : bytes // ignore: cast_nullable_to_non_nullable
              as PlatformInt64,
    ));
  }
}

/// @nodoc

class SessionEvent_Failed extends SessionEvent {
  const SessionEvent_Failed({required this.reason}) : super._();

  final String reason;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SessionEvent_FailedCopyWith<SessionEvent_Failed> get copyWith =>
      _$SessionEvent_FailedCopyWithImpl<SessionEvent_Failed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SessionEvent_Failed &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() {
    return 'SessionEvent.failed(reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $SessionEvent_FailedCopyWith<$Res>
    implements $SessionEventCopyWith<$Res> {
  factory $SessionEvent_FailedCopyWith(
          SessionEvent_Failed value, $Res Function(SessionEvent_Failed) _then) =
      _$SessionEvent_FailedCopyWithImpl;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class _$SessionEvent_FailedCopyWithImpl<$Res>
    implements $SessionEvent_FailedCopyWith<$Res> {
  _$SessionEvent_FailedCopyWithImpl(this._self, this._then);

  final SessionEvent_Failed _self;
  final $Res Function(SessionEvent_Failed) _then;

  /// Create a copy of SessionEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
  }) {
    return _then(SessionEvent_Failed(
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
