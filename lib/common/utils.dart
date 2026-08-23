import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/core/store/config_store.dart';
import 'package:logger/logger.dart';
import 'device_info_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import '../core/rust/actor/core.dart';
import '../core/rust/bridge.dart';
import '../i18n/strings.g.dart';
import 'constants.dart';

Future<void> sleepAsync(int millis) {
  return Future.delayed(Duration(milliseconds: millis), () {});
}

Future<void> updateSystemOverlayStyle(Brightness brightness) async {
  await updateSystemOverlayStyleWithBrightness(brightness);
}

Future<void> updateSystemOverlayStyleWithBrightness(
    Brightness brightness) async {
  if (Platform.isAndroid) {
    // See https://github.com/flutter/flutter/issues/90098
    final darkMode = brightness == Brightness.dark;

    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge); // ignore: unawaited_futures

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: brightness, // iOS
      statusBarColor: Colors.transparent, // Not relevant to this issue
    ));
  }
}

Locale stringToLocale(String value) {
  if (value.isEmpty) {
    value = Platform.localeName;
  }
  final localeArgs = value.split("_");
  if (localeArgs.length == 1) {
    return Locale.fromSubtags(languageCode: localeArgs[0]);
  }
  if (localeArgs.length == 2) {
    return Locale.fromSubtags(
      languageCode: localeArgs[0],
      scriptCode: localeArgs[1],
    );
  }
  if (localeArgs.length >= 3) {
    return Locale.fromSubtags(
      languageCode: localeArgs[0],
      scriptCode: localeArgs[1],
      countryCode: localeArgs[2],
    );
  }
  return const Locale("en");
}

/// Maps the persisted TLS toggle onto the core's `identityDir`:
/// enabled hands the core a device identity (which lives in the
/// `tls` subdirectory of [baseDir], the app documents directory),
/// disabled runs plain HTTP. The core creates the directory on
/// demand; `allowPlainTls` stays unset (its `false` default).
String? identityDirFor({required bool tlsEnabled, required String baseDir}) {
  if (!tlsEnabled) {
    return null;
  }
  return '$baseDir${Platform.pathSeparator}tls';
}

Future<CoreConfig> getConfig(int port) async {
  if (!ConfigStore().storePathSet()) {
    final path = await getDownloadPath();
    ConfigStore().setStorePath(path);
  }
  final storePath = ConfigStore().storePath();
  final relayAddr = ConfigStore().relayAddr();
  final relaySecret = ConfigStore().relaySecret();

  return CoreConfig(
    port: port,
    interfaceAddr: "0.0.0.0",
    multicastAddr: "224.0.0.167",
    multicastPort: 53317,
    storePath: storePath,
    // Relay routing is enabled only when both fields are set; empty
    // values mean "no relay" and are passed as null.
    relayAddr: relayAddr.isEmpty ? null : relayAddr,
    relaySecret: relaySecret.isEmpty ? null : relaySecret,
    // End-to-end TLS: Some(identityDir) enables it, null runs plain
    // HTTP.
    identityDir: identityDirFor(
      tlsEnabled: ConfigStore().tlsEnabled(),
      baseDir: (await getApplicationDocumentsDirectory()).path,
    ),
  );
}

Future<String> getDownloadPath() async {
  String storePath;
  if (Platform.isAndroid) {
    storePath = "/storage/emulated/0/Download";
  } else {
    storePath = (await getDownloadsDirectory())!.absolute.path;
  }
  return storePath;
}

/// Shared app logger (package:logger). Pretty-printed, colored by
/// level; Rust-core records arrive through [routeRustLogs].
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: false,
  ),
);

/// The FFI logger encodes levels as the FRB template does:
/// 5000=trace, 10000=debug, 20000=info, 30000=warn, 40000=error.
Level _rustLevel(int raw) {
  switch (raw) {
    case >= 40000:
      return Level.error;
    case >= 30000:
      return Level.warning;
    case >= 20000:
      return Level.info;
    case >= 10000:
      return Level.debug;
    default:
      return Level.trace;
  }
}

/// Bridge the Rust core's log stream into [appLogger] — the core's
/// own logging (file-side) already filters third-party chatter, so
/// everything arriving here is worth showing in debug builds.
void routeRustLogs() {
  if (!kDebugMode) return;
  createLogStream().listen((event) {
    appLogger.log(
      _rustLevel(event.level),
      '[${event.tag}] ${event.msg}',
      time: DateTime.fromMillisecondsSinceEpoch(event.timeMillis.toInt()),
    );
  });
}

void initLocale() {
  final localeMode = ConfigStore().localeMode();

  if (localeMode == LocaleMode.system) {
    LocaleSettings.useDeviceLocale();
  } else {
    final locale = ConfigStore().locale();
    LocaleSettings.setLocaleRaw(stringToLocale(locale).languageCode);
  }

  if (Platform.isWindows) {
    windowManager.setTitle(t.appTitle.parta + t.appTitle.partb);
  }
}

extension MissionStateName on MissionState {
  String getName() {
    return switch (this) {
      MissionState.idle => t.mission.pending,
      MissionState.pending => t.mission.pending,
      MissionState.transfering => t.mission.tranfer,
      MissionState.finished => t.mission.finished,
      MissionState.failed => t.mission.failed,
      MissionState.canceled => t.mission.cancel,
      MissionState.busy => t.mission.busy,
    };
  }
}

extension FileStateName on FileState {
  String getName() {
    return switch (this) {
      FileState_Pending() => t.mission.pending,
      FileState_Transfer() => t.mission.tranfer,
      FileState_Finish() => t.mission.complete,
      FileState_Skip() => t.mission.skip,
      FileState_Fail() => t.mission.failed,
    };
  }
}


/// Backwards-compatible alias.
void initLogger() => routeRustLogs();

/// Rebuild the core config from the current ConfigStore values and
/// restart the core with it. Called by settings changes that need a
/// fresh core (relay server, TLS toggle, port).
Future<void> restartCoreWithFreshConfig() async {
  final device = await getDevice();
  final config = await getConfig(device.port);
  await setup(device: device, config: config);
}
