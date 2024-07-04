import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/constants.dart';
import '../../common/utils.dart';
import '../../core/providers/core_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';

class SettingTileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingTileGroup(
      {super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ThemeTile extends ConsumerWidget {
  const ThemeTile({
    super.key,
  });

  String getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return t.setting.brightness.themeMode.system;
      case ThemeMode.light:
        return t.setting.brightness.themeMode.light;
      case ThemeMode.dark:
        return t.setting.brightness.themeMode.dark;
    }
  }

  Future<void> setTheme(
      WidgetRef ref, BuildContext context, ThemeMode theme) async {
    ref.read(themeStateProvider.notifier).setTheme(theme);
    await sleepAsync(Durations.medium1.inMilliseconds);
    final brightness = Theme.of(context).brightness;
    await updateSystemOverlayStyle(brightness);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeStateProvider);
    return ListTile(
      title: Text(t.setting.brightness.title),
      subtitle:
          Text(t.setting.brightness.subTitle(mode: getThemeName(themeMode))),
      trailing: OverflowBar(
        children: [
          IconButton(
            isSelected: themeMode == ThemeMode.system,
            selectedIcon: Icon(
              Icons.brightness_auto,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              setTheme(ref, context, ThemeMode.system);
            },
            icon: const Icon(Icons.brightness_auto_outlined),
          ),
          IconButton(
            isSelected: themeMode == ThemeMode.light,
            selectedIcon: Icon(
              Icons.brightness_5,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              setTheme(ref, context, ThemeMode.light);
            },
            icon: const Icon(Icons.brightness_5_outlined),
          ),
          IconButton(
            isSelected: themeMode == ThemeMode.dark,
            selectedIcon: Icon(
              Icons.brightness_2,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              setTheme(ref, context, ThemeMode.dark);
            },
            icon: const Icon(Icons.brightness_2_outlined),
          ),
        ],
      ),
    );
  }
}

class LocaleTile extends ConsumerWidget {
  const LocaleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    LocaleConfig config = ref.watch(localeStateProvider);
    Locale locale = config.mode == LocaleMode.system
        ? stringToLocale(Platform.localeName)
        : config.customLocale;
    final currentLocaleName =
        supportLanguages[locale.languageCode]?.name ?? "unknown";

    return ListTile(
      title: Text(t.setting.language.title),
      subtitle: Text(t.setting.language.subTitle(language: currentLocaleName)),
      trailing: FilledButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                final systemLocale = stringToLocale(Platform.localeName);
                final systemLocaleName =
                    supportLanguages[systemLocale.languageCode]?.name ??
                        "unknown";
                return SimpleDialog(
                  title: Text(t.setting.language.title),
                  children: [
                    ListTile(
                      title: Text("系统默认: $systemLocaleName"),
                      selected: config.mode == LocaleMode.system,
                      onTap: () {
                        ref.read(localeStateProvider.notifier).changeMode(
                              LocaleMode.system,
                            );
                        Navigator.of(context).pop();
                      },
                    ),
                    for (var language in supportLanguages.values)
                      ListTile(
                        selected: config.mode == LocaleMode.custom &&
                            locale.languageCode == language.localeName,
                        title: Text(language.name),
                        onTap: () {
                          ref.read(localeStateProvider.notifier).setLocale(
                                Locale(language.localeName),
                              );
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                );
              });
        },
        child: Text(currentLocaleName),
      ),
    );
  }
}

class ServerTile extends ConsumerWidget {
  const ServerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreStateProvider);
    return ListTile(
      title: Text(t.setting.core.server.title),
      trailing: OverflowBar(
        children: [
          IconButton(
            onPressed: core.serverState
                ? null
                : () async {
                    await startServer();
                  },
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: core.serverState
                ? () async {
                    await shutdownServer();
                  }
                : null,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
    );
  }
}
