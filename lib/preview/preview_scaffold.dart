import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../core/providers/core_provider.dart';
import '../core/providers/selection_providers.dart';
import '../core/providers/session_providers.dart';
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
      size: size,
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

class PreviewAutoAccept extends AutoAccept {
  @override
  Set<String> build() => {};
}

/// Overrides routing every Rust-backed provider to mock data.
List<Override> previewOverrides({
  List<SessionSummary> sessions = const [],
  Map<String, SessionExtras> extras = const {},
  List<String> selectedFiles = const [],
}) {
  return [
    sessionIndexProvider.overrideWith((ref) => Stream.value(sessions)),
    devicesProvider.overrideWith(
      (ref) => Stream.value([mockDevice(), mockDevice(alias: 'ThinkPad', address: '192.168.1.30', model: 'ThinkPad', type: 'desktop')]),
    ),
    serverStateProvider.overrideWith((ref) => Stream.value(true)),
    selectedFilesProvider.overrideWith(() => PreviewSelectedFiles(selectedFiles)),
    quickSaveProvider.overrideWith(PreviewQuickSave.new),
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
Widget previewShell({
  required Widget child,
  List<Override> overrides = const [],
  double width = 420,
  double height = 700,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  return TranslationProvider(
    child: ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xfff74c00),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    ),
  );
}
