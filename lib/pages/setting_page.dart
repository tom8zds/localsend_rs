import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/rust/bridge.dart';
import 'package:localsend_rs/widget/network_widget.dart';

import '../common/constants.dart';
import '../common/widgets.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            centerTitle: true,
            title: Text(context.t.setting.title),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  SettingTileGroup(
                    title: t.setting.common,
                    children: const [
                      ThemeTile(),
                      // color tile
                      // language tile
                      LocaleTile(),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SettingTileGroup(
                    title: t.setting.core.title,
                    children: [
                      // core status
                      ListTile(
                        title: Text(t.setting.core.server.title),
                        trailing: OverflowBar(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await startServer();
                              },
                              icon: const Icon(Icons.play_arrow),
                            ),
                            IconButton(
                              onPressed: () async {
                                await shutdownServer();
                              },
                              icon: const Icon(Icons.stop),
                            ),
                          ],
                        ),
                      ),
                      // core log
                      NetworkWidget(
                        onPressed: (addr) {
                          changeAddress(addr: addr);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const SettingTileGroup(
                    title: "behavior",
                    children: [
                      // receive without accept
                      // save dir
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 200,
                    child: Image.asset("assets/icon/logo_512.png"),
                  ),
                  const Column(
                    children: [
                      AppTitle(),
                      SizedBox(
                        height: 8,
                      ),
                      Text("Version: 1.0.0"),
                      Text("by tom8zds @ github")
                    ],
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SettingTileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingTileGroup(
      {super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
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
              ref.read(themeStateProvider.notifier).setTheme(ThemeMode.system);
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
              ref.read(themeStateProvider.notifier).setTheme(ThemeMode.light);
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
              ref.read(themeStateProvider.notifier).setTheme(ThemeMode.dark);
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
    Locale locale = ref.watch(localeStateProvider);
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
                final systemLocale = Platform.localeName.split("_")[0];
                final systemLocaleName =
                    supportLanguages[systemLocale]?.name ?? "unknown";
                return SimpleDialog(
                  title: Text(t.setting.language.title),
                  children: [
                    ListTile(
                      title: Text("系统默认: $systemLocaleName"),
                      onTap: () {
                        ref.read(localeStateProvider.notifier).setLocale(
                              Locale(systemLocale),
                            );
                        Navigator.of(context).pop();
                      },
                    ),
                    for (var language in supportLanguages.values)
                      ListTile(
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
