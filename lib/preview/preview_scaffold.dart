import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../common/platform_int64.dart';

import '../core/providers/core_provider.dart';
import '../core/providers/relay_provider.dart';
import '../core/providers/selection_providers.dart';
import '../core/providers/session_providers.dart';
import '../core/providers/tls_provider.dart';
import '../core/rust/actor/model.dart';
import '../core/rust/api/model.dart';
import '../i18n/strings.g.dart';

/// Mock devices/sessions shared by the widget previews. Everything
/// here is plain Dart data — the previews never call into Rust.
NodeDevice mockDevice({
  String alias = 'Pixel 8',
  String address = '192.168.1.20',
  String model = 'Pixel 8',
  String type = 'mobile',
}) {
  return NodeDevice(
    alias: alias,
    version: '2.2',
    deviceModel: model,
    deviceType: type,
    fingerprint: 'fp-$alias',
    address: address,
    port: 53317,
    protocol: 'http',
    download: true,
    announcement: true,
    announce: true,
    discoverySource: 'lan',
  );
}

MissionFileInfo mockFile(
  String name,
  int size, {
  FileState state = const FileState.pending(),
}) {
  return MissionFileInfo(
    info: FileInfo(
      id: 'id-$name',
      fileName: name,
      size: platformInt64(size),
      fileType: 'bin',
    ),
    state: state,
  );
}

SessionSummary mockSession({
  required String id,
  required SessionDirection direction,
  required MissionState state,
  NodeDevice? peer,
  bool viaRelay = false,
  String? route,
  List<MissionFileInfo>? files,
}) {
  final fileList = files ??
      [
        mockFile('photo.jpg', 1024 * 1024),
        mockFile('notes.txt', 2048),
      ];
  return SessionSummary(
    id: id,
    direction: direction,
    peer: peer ?? mockDevice(),
    fileCount: fileList.length,
    state: state,
    viaRelay: viaRelay,
    route: route ?? (viaRelay ? 'turn' : 'local'),
    speedBps: BigInt.zero,
    files: fileList,
  );
}

class PreviewSelectedFiles extends SelectedFiles {
  PreviewSelectedFiles(this.files);

  final List<String> files;

  @override
  List<String> build() => files;
}

class PreviewQuickSave extends QuickSave {
  @override
  bool build() => false;
}

class PreviewRelaySettings extends RelaySettings {
  PreviewRelaySettings(this.config);

  final RelayConfig config;

  @override
  RelayConfig build() => config;
}

class PreviewRelayPing extends RelayPing {
  PreviewRelayPing(this.initial);

  final RelayPingState initial;

  @override
  RelayPingState build() => initial;

  // The previewer has no Rust bridge; tapping the test button in a
  // preview stays on the mocked state instead of probing.
  @override
  Future<void> run() async {}
}

class PreviewTlsSettings extends TlsSettings {
  PreviewTlsSettings(this.enabled);

  final bool enabled;

  @override
  bool build() => enabled;

  // The previewer has no initialized ConfigStore; keep toggle taps
  // local instead of persisting.
  @override
  Future<void> setEnabled(bool value) async {
    state = value;
  }
}

class PreviewAutoAccept extends AutoAccept {
  @override
  Set<String> build() => {};
}

/// Overrides routing every Rust-backed provider to mock data.
///
/// [pingImpl] swaps in a behavior-mocking ping notifier (used by the
/// widget tests) instead of the stateless [PreviewRelayPing].
List<Override> previewOverrides({
  List<SessionSummary> sessions = const [],
  Map<String, SessionExtras> extras = const {},
  List<String> selectedFiles = const [],
  RelayConfig relay = const RelayConfig(),
  bool tlsEnabled = true,
  RelayPingState ping = const RelayPingIdle(),
  RelayPing Function()? pingImpl,
}) {
  return [
    sessionIndexProvider.overrideWith((ref) => Stream.value(sessions)),
    devicesProvider.overrideWith(
      (ref) => Stream.value([
        mockDevice(),
        mockDevice(
            alias: 'ThinkPad',
            address: '192.168.1.30',
            model: 'ThinkPad',
            type: 'desktop')
      ]),
    ),
    serverStateProvider.overrideWith((ref) => Stream.value(true)),
    selectedFilesProvider
        .overrideWith(() => PreviewSelectedFiles(selectedFiles)),
    quickSaveProvider.overrideWith(PreviewQuickSave.new),
    relaySettingsProvider.overrideWith(() => PreviewRelaySettings(relay)),
    relayPingProvider.overrideWith(pingImpl ?? () => PreviewRelayPing(ping)),
    tlsSettingsProvider.overrideWith(() => PreviewTlsSettings(tlsEnabled)),
    autoAcceptProvider.overrideWith(PreviewAutoAccept.new),
    for (final entry in extras.entries)
      sessionExtrasProvider(entry.key).overrideWith(
        () => PreviewSessionExtras(entry.value),
      ),
  ];
}

class PreviewSessionExtras extends SessionExtrasNotifier {
  PreviewSessionExtras(this._extras);

  final SessionExtras _extras;

  @override
  SessionExtras build(String sessionId) => _extras;
}

/// Common preview scaffold: fixed English translations, app theme and
/// mocked providers, centred in a neutral surface.
///
/// [name] keys the subtree so the previewer never updates this
/// [ProviderScope] in place when switching between previews (riverpod
/// forbids changing the number of overrides on an existing scope).
Widget previewShell({
  required String name,
  required Widget child,
  List<Override> overrides = const [],
  double width = 420,
  double height = 700,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  return KeyedSubtree(
    key: ValueKey('preview-$name'),
    // InheritedLocaleData instead of TranslationProvider: slang's
    // TranslationProvider registers one GlobalKey per locale enum
    // process-wide, which collides when the previewer mounts several
    // previews at once.
    child: InheritedLocaleData<AppLocale, Translations>(
      translations: AppLocale.en.buildSync(),
      // Keyed by preview name + override count: riverpod forbids
      // adding/removing overrides on an existing scope, so if the
      // previewer reuses this slot for another preview the scope is
      // remounted instead of updated in place.
      child: ProviderScope(
        key: ValueKey('preview-scope-$name-${overrides.length}'),
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Both themes + ThemeMode.system so the previewer's
          // night-mode toggle (platform brightness) takes effect.
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xfff74c00),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xfff74c00),
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.system,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ),
      ),
    ),
  );
}
