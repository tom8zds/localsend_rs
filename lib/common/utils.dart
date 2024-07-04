import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

Locale stringToLocale(String value){
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
