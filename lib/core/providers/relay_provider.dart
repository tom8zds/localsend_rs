import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/bridge.dart';
import '../store/config_store.dart';

part 'relay_provider.g.dart';

/// URL scheme of the relay-invite deep link
/// (`localsend-relay://configure?addr=host:port&secret=xxx`).
const relayDeepLinkScheme = 'localsend-relay';

/// An invitation to use a TURN relay, shared either as a deep link
/// (`localsend-relay://configure?addr=host:port&secret=xxx`) or as a
/// bare `addr|secret` text line (QR payloads). Parsing is pure so the
/// deep-link entry and the paste/scan import share one code path.
class RelayInvite {
  final String addr;
  final String secret;

  const RelayInvite({required this.addr, required this.secret});

  /// Parses [input]: either a `localsend-relay://` link with `addr`
  /// and `secret` query parameters, or a bare `addr|secret` line.
  /// Surrounding whitespace is tolerated; returns null when the input
  /// matches neither form or either field is missing/empty.
  static RelayInvite? parse(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return null;
    }

    // Deep link form; Uri normalizes the scheme to lower case.
    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme && uri.scheme == relayDeepLinkScheme) {
      final addr = uri.queryParameters['addr']?.trim() ?? '';
      final secret = uri.queryParameters['secret']?.trim() ?? '';
      if (addr.isEmpty || secret.isEmpty) {
        return null;
      }
      return RelayInvite(addr: addr, secret: secret);
    }

    // Bare `addr|secret` line; the secret keeps any further separator.
    final separator = text.indexOf('|');
    if (separator <= 0) {
      return null;
    }
    final addr = text.substring(0, separator).trim();
    final secret = text.substring(separator + 1).trim();
    if (addr.isEmpty || secret.isEmpty) {
      return null;
    }
    return RelayInvite(addr: addr, secret: secret);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelayInvite &&
          runtimeType == other.runtimeType &&
          addr == other.addr &&
          secret == other.secret;

  @override
  int get hashCode => addr.hashCode ^ secret.hashCode;
}

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

/// Outcome of a relay STUN probe, shown inline under the test button.
sealed class RelayPingState {
  const RelayPingState();
}

/// No probe has been run since the settings page was entered.
class RelayPingIdle extends RelayPingState {
  const RelayPingIdle();
}

/// A probe is in flight; the test button shows its loading state.
class RelayPingLoading extends RelayPingState {
  const RelayPingLoading();
}

/// The relay answered; [rttMs] is the round-trip time in milliseconds.
class RelayPingOk extends RelayPingState {
  final int rttMs;

  const RelayPingOk(this.rttMs);
}

/// The probe failed ([message] is a human-friendly one-liner).
class RelayPingError extends RelayPingState {
  final String message;

  const RelayPingError(this.message);
}

/// One-shot STUN probe of the relay. The core probes the relay it was
/// *started* with (the config `getConfig` assembled at startup), so
/// the result reflects the persisted settings only after a restart.
@riverpod
class RelayPing extends _$RelayPing {
  @override
  RelayPingState build() => const RelayPingIdle();

  Future<void> run() async {
    state = const RelayPingLoading();
    try {
      final rtt = await relayPing();
      state = RelayPingOk(rtt.toInt());
    } catch (e) {
      state = RelayPingError(summarizeError(e));
    }
  }
}

/// One-line, class-free error text: strips a leading `ClassName: `
/// prefix (FRB raises `AnyhowException: ...`) and keeps the first
/// line only.
String summarizeError(Object error) {
  var message = error.toString();
  final match =
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*: (.*)$', dotAll: true).firstMatch(message);
  if (match != null) {
    message = match.group(1)!;
  }
  return message.split('\n').first.trim();
}
