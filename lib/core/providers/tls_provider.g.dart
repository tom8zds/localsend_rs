// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tls_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted end-to-end TLS toggle, edited on the settings page. The
/// value decides whether `getConfig` hands the core a TLS identity
/// directory at startup (`true`) or runs plain HTTP (`false`);
/// changing it here only persists (same as the relay settings).

@ProviderFor(TlsSettings)
final tlsSettingsProvider = TlsSettingsProvider._();

/// Persisted end-to-end TLS toggle, edited on the settings page. The
/// value decides whether `getConfig` hands the core a TLS identity
/// directory at startup (`true`) or runs plain HTTP (`false`);
/// changing it here only persists (same as the relay settings).
final class TlsSettingsProvider extends $NotifierProvider<TlsSettings, bool> {
  /// Persisted end-to-end TLS toggle, edited on the settings page. The
  /// value decides whether `getConfig` hands the core a TLS identity
  /// directory at startup (`true`) or runs plain HTTP (`false`);
  /// changing it here only persists (same as the relay settings).
  TlsSettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tlsSettingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tlsSettingsHash();

  @$internal
  @override
  TlsSettings create() => TlsSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$tlsSettingsHash() => r'2588cb74edd3285a47e8fc74b4b7acfab1a370d4';

/// Persisted end-to-end TLS toggle, edited on the settings page. The
/// value decides whether `getConfig` hands the core a TLS identity
/// directory at startup (`true`) or runs plain HTTP (`false`);
/// changing it here only persists (same as the relay settings).

abstract class _$TlsSettings extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
