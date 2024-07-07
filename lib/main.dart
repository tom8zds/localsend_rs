import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'common/device_info_utils.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/rust/bridge.dart';
import 'core/rust/frb_generated.dart';
import 'core/store/config_store.dart';
import 'i18n/strings.g.dart';
import 'view/pages/frame_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  String storePath;
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
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

  await ConfigStore.ensureInitialized();
  final locale = ConfigStore().locale();
  final String defaultLocale = Platform.localeName;
  final countryCode = LocaleSettings.currentLocale.countryCode;
  if (countryCode == null || countryCode != locale) {
    LocaleSettings.setLocaleRaw(defaultLocale);
  }
  final device = await newDevice();
  await setup(device: device);
  runApp(ProviderScope(child: TranslationProvider(child: const MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    var baseTheme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xfff74c00),
        brightness: brightness);

    return baseTheme.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeStateProvider);
    final localeConfig = ref.watch(localeStateProvider);
    return MaterialApp(
      title: t.appTitle,
      locale: localeConfig.getLocale(),
      // use provider
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: const FramePage(),
    );
  }
}
