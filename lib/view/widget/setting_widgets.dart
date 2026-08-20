import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/constants.dart';
import '../../common/spacing.dart';
import '../../common/utils.dart';
import '../../core/providers/core_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/session_providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/rust/bridge.dart';
import '../../core/store/config_store.dart';
import '../../i18n/strings.g.dart';

class SettingTileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingTileGroup(
      {super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x8),
      child: Container(
        decoration: BoxDecoration(
          // Neutral filled group: low surface container (not the
          // secondary/selection container), M3 card corner (12dp).
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.x12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x16,
                vertical: AppSpacing.x8,
              ),
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
      title: Text(context.t.setting.brightness.title),
      subtitle: Text(
          context.t.setting.brightness.subTitle(mode: getThemeName(themeMode))),
      trailing: OverflowBar(
        children: [
          // Selected state is conveyed by IconButton's built-in M3
          // isSelected treatment (primary), not a hand-picked accent.
          IconButton(
            isSelected: themeMode == ThemeMode.system,
            selectedIcon: const Icon(Icons.brightness_auto),
            onPressed: () {
              setTheme(ref, context, ThemeMode.system);
            },
            icon: const Icon(Icons.brightness_auto_outlined),
          ),
          IconButton(
            isSelected: themeMode == ThemeMode.light,
            selectedIcon: const Icon(Icons.brightness_5),
            onPressed: () {
              setTheme(ref, context, ThemeMode.light);
            },
            icon: const Icon(Icons.brightness_5_outlined),
          ),
          IconButton(
            isSelected: themeMode == ThemeMode.dark,
            selectedIcon: const Icon(Icons.brightness_2),
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
      title: Text(context.t.setting.language.title),
      subtitle: Text(
          context.t.setting.language.subTitle(language: currentLocaleName)),
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
                  title: Text(context.t.setting.language.title),
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
    final serverState = ref.watch(serverStateProvider).value ?? false;
    return ListTile(
      title: Text(context.t.setting.core.server.title),
      trailing: OverflowBar(
        children: [
          IconButton(
            onPressed: serverState
                ? null
                : () async {
                    await startServer();
                  },
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            onPressed: serverState
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

class QuickSaveWidget extends ConsumerWidget {
  const QuickSaveWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickSave = ref.watch(quickSaveProvider);
    return ListTile(
      title: Text(context.t.setting.receive.quickSave),
      subtitle: Text(context.t.setting.receive.quickSaveHint),
      trailing: Switch(
        onChanged: (value) {
          ref.read(quickSaveProvider.notifier).set(value);
        },
        value: quickSave,
      ),
    );
  }
}

class StorePathWIdget extends StatefulWidget {
  const StorePathWIdget({
    super.key,
  });

  @override
  State<StorePathWIdget> createState() => _StorePathWIdgetState();
}

class _StorePathWIdgetState extends State<StorePathWIdget> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(context.t.setting.receive.saveFolder),
      subtitle: Text(ConfigStore().storePath()),
      trailing: FilledButton(
        onPressed: () async {
          String? selectedDirectory =
              await FilePicker.getDirectoryPath();

          if (selectedDirectory != null) {
            ConfigStore().setStorePath(selectedDirectory);
          }
          setState(() {});
        },
        child: Text(context.t.setting.receive.selectSaveFolder),
      ),
    );
  }
}
