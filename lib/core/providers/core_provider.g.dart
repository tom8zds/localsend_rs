// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the embedded HTTP server is running.

@ProviderFor(serverState)
final serverStateProvider = ServerStateProvider._();

/// Whether the embedded HTTP server is running.

final class ServerStateProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the embedded HTTP server is running.
  ServerStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'serverStateProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$serverStateHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return serverState(ref);
  }
}

String _$serverStateHash() => r'2ebe48e87c9e895ddecace17c46155dccd637b6e';

/// Devices discovered on the local network.

@ProviderFor(devices)
final devicesProvider = DevicesProvider._();

/// Devices discovered on the local network.

final class DevicesProvider extends $FunctionalProvider<
        AsyncValue<List<NodeDevice>>,
        List<NodeDevice>,
        Stream<List<NodeDevice>>>
    with $FutureModifier<List<NodeDevice>>, $StreamProvider<List<NodeDevice>> {
  /// Devices discovered on the local network.
  DevicesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'devicesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$devicesHash();

  @$internal
  @override
  $StreamProviderElement<List<NodeDevice>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<NodeDevice>> create(Ref ref) {
    return devices(ref);
  }
}

String _$devicesHash() => r'c349ebfebd8a4f50dc30b5550d41bc3d47f89ef4';

/// Last server startup error, if any (null once the server binds).

@ProviderFor(serverError)
final serverErrorProvider = ServerErrorProvider._();

/// Last server startup error, if any (null once the server binds).

final class ServerErrorProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Last server startup error, if any (null once the server binds).
  ServerErrorProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'serverErrorProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$serverErrorHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return serverError(ref);
  }
}

String _$serverErrorHash() => r'e58c217995688bea42265d7a5737bd9e0c6c51b2';
