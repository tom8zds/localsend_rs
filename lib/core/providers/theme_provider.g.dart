// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ThemeState)
final themeStateProvider = ThemeStateProvider._();

final class ThemeStateProvider
    extends $NotifierProvider<ThemeState, ThemeMode> {
  ThemeStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeStateHash();

  @$internal
  @override
  ThemeState create() => ThemeState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeStateHash() => r'6f0d061bc0306df79968b8a6a40a50220428ec9d';

abstract class _$ThemeState extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ThemeMode, ThemeMode>, ThemeMode, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
