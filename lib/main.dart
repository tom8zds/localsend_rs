import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/common/device_info_utils.dart';
import 'package:localsend_rs/config_store.dart';
import 'package:localsend_rs/pages/frame_page.dart';
import 'package:localsend_rs/rust/actor/model.dart';
import 'package:localsend_rs/rust/bridge.dart';
import 'package:path_provider/path_provider.dart';

import 'i18n/strings.g.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  String storePath;
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
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
  await ConfigStore.ensureInitialized();
  final locale = ConfigStore().locale();
  print(locale);
  print(LocaleSettings.currentLocale.countryCode);
  final countryCode = LocaleSettings.currentLocale.countryCode;
  if (countryCode == null || countryCode != locale) {
    print("test");
    LocaleSettings.setLocaleRaw(locale);
  }
  final device = await newDevice();
  await setup(device: device);
  runApp(ProviderScope(child: TranslationProvider(child: const MyApp())));
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xfff74c00),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xfff74c00),
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      home: const FramePage(),
    );
  }
}
