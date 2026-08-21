import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../store/config_store.dart';

part 'relay_provider.g.dart';

/// User-configured TURN relay endpoint. The core routes traffic
/// through the relay only when both [addr] and [secret] are set
/// (empty values are passed to the core as `null`).
class RelayConfig {
  final String addr;
  final String secret;

  const RelayConfig({this.addr = '', this.secret = ''});

  /// The relay participates in routing only with a complete
  /// address + secret pair.
  bool get enabled => addr.isNotEmpty && secret.isNotEmpty;

  String? get relayAddr => addr.isEmpty ? null : addr;

  String? get relaySecret => secret.isEmpty ? null : secret;

  RelayConfig copyWith({String? addr, String? secret}) => RelayConfig(
        addr: addr ?? this.addr,
        secret: secret ?? this.secret,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelayConfig &&
          runtimeType == other.runtimeType &&
          addr == other.addr &&
          secret == other.secret;

  @override
  int get hashCode => addr.hashCode ^ secret.hashCode;
}

/// Persisted relay settings, edited on the settings page. The values
/// feed `CoreConfig` when the app assembles it at startup; changing
/// them here only persists (same as the save-folder setting).
@riverpod
class RelaySettings extends _$RelaySettings {
  @override
  RelayConfig build() {
    return RelayConfig(
      addr: ConfigStore().relayAddr(),
      secret: ConfigStore().relaySecret(),
    );
  }

  Future<void> setAddr(String value) async {
    await ConfigStore().setRelayAddr(value);
    state = state.copyWith(addr: value);
  }

  Future<void> setSecret(String value) async {
    await ConfigStore().setRelaySecret(value);
    state = state.copyWith(secret: value);
  }
}
