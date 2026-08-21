// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted relay settings, edited on the settings page. The values
/// feed `CoreConfig` when the app assembles it at startup; changing
/// them here only persists (same as the save-folder setting).

@ProviderFor(RelaySettings)
final relaySettingsProvider = RelaySettingsProvider._();

/// Persisted relay settings, edited on the settings page. The values
/// feed `CoreConfig` when the app assembles it at startup; changing
/// them here only persists (same as the save-folder setting).
final class RelaySettingsProvider
    extends $NotifierProvider<RelaySettings, RelayConfig> {
  /// Persisted relay settings, edited on the settings page. The values
  /// feed `CoreConfig` when the app assembles it at startup; changing
  /// them here only persists (same as the save-folder setting).
  RelaySettingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'relaySettingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$relaySettingsHash();

  @$internal
  @override
  RelaySettings create() => RelaySettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RelayConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RelayConfig>(value),
    );
  }
}

String _$relaySettingsHash() => r'f800b8c4d8c2a15210a157def84945ec66f99826';

/// Persisted relay settings, edited on the settings page. The values
/// feed `CoreConfig` when the app assembles it at startup; changing
/// them here only persists (same as the save-folder setting).

abstract class _$RelaySettings extends $Notifier<RelayConfig> {
  RelayConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RelayConfig, RelayConfig>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RelayConfig, RelayConfig>, RelayConfig, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// One-shot STUN probe of the relay. The core probes the relay it was
/// *started* with (the config `getConfig` assembled at startup), so
/// the result reflects the persisted settings only after a restart.

@ProviderFor(RelayPing)
final relayPingProvider = RelayPingProvider._();

/// One-shot STUN probe of the relay. The core probes the relay it was
/// *started* with (the config `getConfig` assembled at startup), so
/// the result reflects the persisted settings only after a restart.
final class RelayPingProvider
    extends $NotifierProvider<RelayPing, RelayPingState> {
  /// One-shot STUN probe of the relay. The core probes the relay it was
  /// *started* with (the config `getConfig` assembled at startup), so
  /// the result reflects the persisted settings only after a restart.
  RelayPingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'relayPingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$relayPingHash();

  @$internal
  @override
  RelayPing create() => RelayPing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RelayPingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RelayPingState>(value),
    );
  }
}

String _$relayPingHash() => r'572f479084560a7b41b3fc4fde5a63d3ca81c4fe';

/// One-shot STUN probe of the relay. The core probes the relay it was
/// *started* with (the config `getConfig` assembled at startup), so
/// the result reflects the persisted settings only after a restart.

abstract class _$RelayPing extends $Notifier<RelayPingState> {
  RelayPingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RelayPingState, RelayPingState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<RelayPingState, RelayPingState>,
        RelayPingState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
