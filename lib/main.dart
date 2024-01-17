import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/config_store.dart';
import 'package:localsend_rs/pages/frame_page.dart';
import 'package:path_provider/path_provider.dart';

import 'i18n/strings.g.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'rust/bridge/bridge.dart';
import 'rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  await RustLib.init();
  String storePath;
  if (Platform.isAndroid) {
    storePath = "/storage/emulated/0/Download";
  } else {
    storePath = (await getDownloadsDirectory())!.absolute.path;
  }
  // initServer(
  //   device: DeviceConfig(
  //     alias: "test",
  //     fingerprint: "fingerprint",
  //     deviceModel: "rust",
  //     deviceType: "mobile",
  //     storePath: storePath,
  //   ),
  // );
  await rustSetUp(isDebug: kDebugMode);
  await setup();
  await ConfigStore.ensureInitialized();
  // createLogStream().listen((event) {
  //   print(
  //       'rust log [${event.level}] - ${event.tag} ${event.msg}(rust_time=${event.timeMillis})');
  // });
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeStateProvider);
    final locale = ref.watch(localeStateProvider);
    return MaterialApp(
      title: t.appTitle,
      locale: locale, // use provider
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: FramePage(),
    );
  }
}
