import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_rs/core/rust/session/model.dart';
import 'package:localsend_rs/core/store/config_store.dart';
import 'package:logger/logger.dart';
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

Future<CoreConfig> getConfig(int port) async {
  if (!ConfigStore().storePathSet()) {
    final path = await getDownloadPath();
    ConfigStore().setStorePath(path);
  }
  final storePath = ConfigStore().storePath();

  return CoreConfig(
    port: port,
    interfaceAddr: "0.0.0.0",
    multicastAddr: "224.0.0.167",
    multicastPort: 53317,
    storePath: storePath,
  );
}

Future<String> getDownloadPath() async {
  String storePath;
  if (Platform.isAndroid) {
    storePath = "/storage/emulated/0/Download";
    if (kDebugMode) {
      createLogStream().listen((event) {
        debugPrint(
            '${event.level} ${event.tag} ${event.msg} ${event.timeMillis}');
      });
    }
  } else {
    storePath = (await getDownloadsDirectory())!.absolute.path;
  }
  return storePath;
}

const levelList = [
  Level.off,
  Level.error,
  Level.warning,
  Level.info,
  Level.debug,
  Level.trace
];

void initLogger() {
  // var logger = Logger();

  // if (Platform.isAndroid) {
  //   if (kDebugMode) {
  //     createLogStream().listen((event) {
  //       logger.log(
  //         levelList[event.level],
  //         event.msg,
  //         time: DateTime.fromMillisecondsSinceEpoch(event.timeMillis),
  //       );
  //     });
  //   }
  // }
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

extension StatusName on Status {
  String getName() {
    switch (this) {
      case Status_Pending():
        return t.session.pending;
      case Status_Transfer():
        return t.session.tranfer;
      case Status_Finish():
        return t.session.finished;
      case Status_Fail():
        return t.session.failed;
      case Status_Cancel():
        return t.session.cancel;
      case Status_Rejected():
      // TODO: Handle this case.
    }
    return "unknown";
  }
}
