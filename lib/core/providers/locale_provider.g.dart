// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocaleState)
final localeStateProvider = LocaleStateProvider._();

final class LocaleStateProvider
    extends $NotifierProvider<LocaleState, LocaleConfig> {
  LocaleStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'localeStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$localeStateHash();

  @$internal
  @override
  LocaleState create() => LocaleState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocaleConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocaleConfig>(value),
    );
  }
}

String _$localeStateHash() => r'e639ad5930410f9b4d38fd1d65777d2836014665';

abstract class _$LocaleState extends $Notifier<LocaleConfig> {
  LocaleConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocaleConfig, LocaleConfig>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<LocaleConfig, LocaleConfig>,
        LocaleConfig,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
