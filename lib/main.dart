import 'dart:async';
import 'dart:io';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'common/device_info_utils.dart';
import 'common/utils.dart';
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
  initLogger();

  await ConfigStore.ensureInitialized();

  final device = await getDevice();
  final config = await getConfig(device.port);
  await setup(device: device, config: config);

  if (Platform.isWindows) {
    // Must add this line.
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1080, 960),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  initLocale();

  runApp(ProviderScope(child: TranslationProvider(child: const MyApp())));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness, Locale locale) {
    var baseTheme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xfff74c00),
        brightness: brightness);

    if (locale.languageCode == "zh") {
      return baseTheme.useSystemChineseFont(brightness);
    }
    return baseTheme;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeStateProvider);
    final localeConfig = ref.watch(localeStateProvider);
    final locale = localeConfig.getLocale();
    return MaterialApp(
      title: t.appTitle.parta + t.appTitle.partb,
      locale: locale,
      // use provider
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: _buildTheme(
        Brightness.light,
        locale,
      ),
      darkTheme: _buildTheme(
        Brightness.dark,
        locale,
      ),
      themeMode: themeMode,
      home: const FramePage(),
    );
  }
}
