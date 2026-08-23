import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../common/utils.dart';

import '../store/config_store.dart';

part 'tls_provider.g.dart';

/// Persisted end-to-end TLS toggle, edited on the settings page. The
/// value decides whether `getConfig` hands the core a TLS identity
/// directory at startup (`true`) or runs plain HTTP (`false`);
/// changing it here only persists (same as the relay settings).
@riverpod
class TlsSettings extends _$TlsSettings {
  @override
  bool build() {
    return ConfigStore().tlsEnabled();
  }

  Future<void> setEnabled(bool value) async {
    await ConfigStore().setTlsEnabled(value);
    state = value;
    await restartCoreWithFreshConfig();
  }
}
