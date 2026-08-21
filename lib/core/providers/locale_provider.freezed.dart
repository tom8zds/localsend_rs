// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'locale_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocaleConfig {
  LocaleMode get mode;
  Locale get customLocale;

  /// Create a copy of LocaleConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LocaleConfigCopyWith<LocaleConfig> get copyWith =>
      _$LocaleConfigCopyWithImpl<LocaleConfig>(
          this as LocaleConfig, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LocaleConfig &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.customLocale, customLocale) ||
                other.customLocale == customLocale));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mode, customLocale);

  @override
  String toString() {
    return 'LocaleConfig(mode: $mode, customLocale: $customLocale)';
  }
}

/// @nodoc
abstract mixin class $LocaleConfigCopyWith<$Res> {
  factory $LocaleConfigCopyWith(
          LocaleConfig value, $Res Function(LocaleConfig) _then) =
      _$LocaleConfigCopyWithImpl;
  @useResult
  $Res call({LocaleMode mode, Locale customLocale});
}

/// @nodoc
class _$LocaleConfigCopyWithImpl<$Res> implements $LocaleConfigCopyWith<$Res> {
  _$LocaleConfigCopyWithImpl(this._self, this._then);

  final LocaleConfig _self;
  final $Res Function(LocaleConfig) _then;

  /// Create a copy of LocaleConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? customLocale = null,
  }) {
    return _then(_self.copyWith(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as LocaleMode,
      customLocale: null == customLocale
          ? _self.customLocale
          : customLocale // ignore: cast_nullable_to_non_nullable
              as Locale,
    ));
  }
}

/// Adds pattern-matching-related methods to [LocaleConfig].
extension LocaleConfigPatterns on LocaleConfig {
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
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_LocaleConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig() when $default != null:
        return $default(_that);
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
  TResult map<TResult extends Object?>(
    TResult Function(_LocaleConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_LocaleConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig() when $default != null:
        return $default(_that);
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
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(LocaleMode mode, Locale customLocale)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig() when $default != null:
        return $default(_that.mode, _that.customLocale);
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
  TResult when<TResult extends Object?>(
    TResult Function(LocaleMode mode, Locale customLocale) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig():
        return $default(_that.mode, _that.customLocale);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(LocaleMode mode, Locale customLocale)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleConfig() when $default != null:
        return $default(_that.mode, _that.customLocale);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LocaleConfig implements LocaleConfig {
  _LocaleConfig({required this.mode, required this.customLocale});

  @override
  final LocaleMode mode;
  @override
  final Locale customLocale;

  /// Create a copy of LocaleConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LocaleConfigCopyWith<_LocaleConfig> get copyWith =>
      __$LocaleConfigCopyWithImpl<_LocaleConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LocaleConfig &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.customLocale, customLocale) ||
                other.customLocale == customLocale));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mode, customLocale);

  @override
  String toString() {
    return 'LocaleConfig(mode: $mode, customLocale: $customLocale)';
  }
}

/// @nodoc
abstract mixin class _$LocaleConfigCopyWith<$Res>
    implements $LocaleConfigCopyWith<$Res> {
  factory _$LocaleConfigCopyWith(
          _LocaleConfig value, $Res Function(_LocaleConfig) _then) =
      __$LocaleConfigCopyWithImpl;
  @override
  @useResult
  $Res call({LocaleMode mode, Locale customLocale});
}

/// @nodoc
class __$LocaleConfigCopyWithImpl<$Res>
    implements _$LocaleConfigCopyWith<$Res> {
  __$LocaleConfigCopyWithImpl(this._self, this._then);

  final _LocaleConfig _self;
  final $Res Function(_LocaleConfig) _then;

  /// Create a copy of LocaleConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? customLocale = null,
  }) {
    return _then(_LocaleConfig(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as LocaleMode,
      customLocale: null == customLocale
          ? _self.customLocale
          : customLocale // ignore: cast_nullable_to_non_nullable
              as Locale,
    ));
  }
}

// dart format on
