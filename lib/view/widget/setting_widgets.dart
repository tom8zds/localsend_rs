import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/constants.dart';
import '../../common/spacing.dart';
import '../../common/utils.dart';
import '../../core/providers/core_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/relay_provider.dart';
import '../../core/providers/session_providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/tls_provider.dart';
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
        child: Material(
          // Tiles paint their ink (ripples, switch-row taps) on this
          // Material; without it the DecoratedBox above would hide
          // them behind the group background.
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.x12),
          clipBehavior: Clip.antiAlias,
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

/// Editing dialog for one relay field. Returns the trimmed value, or
/// null when cancelled; an empty string clears the field.
Future<String?> showRelayFieldDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initial = '',
  bool obscureText = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RelayFieldDialog(
      title: title,
      hint: hint,
      initial: initial,
      obscureText: obscureText,
    ),
  );
}

class _RelayFieldDialog extends StatefulWidget {
  final String title;
  final String? hint;
  final String initial;
  final bool obscureText;

  const _RelayFieldDialog({
    required this.title,
    this.hint,
    this.initial = '',
    this.obscureText = false,
  });

  @override
  State<_RelayFieldDialog> createState() => _RelayFieldDialogState();
}

class _RelayFieldDialogState extends State<_RelayFieldDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  late bool _obscured = widget.obscureText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: _obscured,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: widget.title,
          hintText: widget.hint,
          border: const OutlineInputBorder(),
          suffixIcon: widget.obscureText
              ? IconButton(
                  // Plain visibility toggle, no semantics beyond the
                  // icon itself.
                  onPressed: () {
                    setState(() {
                      _obscured = !_obscured;
                    });
                  },
                  icon: Icon(_obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                )
              : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.setting.relay.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(t.setting.relay.save),
        ),
      ],
    );
  }
}

/// TURN relay server address (`host:port`). Persisted with the other
/// app settings and fed into the core config on the next app start,
/// like the save-folder setting.
class RelayAddressTile extends ConsumerWidget {
  const RelayAddressTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relay = ref.watch(relaySettingsProvider);
    return ListTile(
      title: Text(context.t.setting.relay.address),
      subtitle: Text(
        relay.addr.isEmpty ? context.t.setting.relay.notSet : relay.addr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: FilledButton(
        onPressed: () async {
          final value = await showRelayFieldDialog(
            context,
            title: context.t.setting.relay.address,
            hint: context.t.setting.relay.addressHint,
            initial: relay.addr,
          );
          if (value != null) {
            await ref.read(relaySettingsProvider.notifier).setAddr(value);
          }
        },
        child: Text(context.t.setting.relay.edit),
      ),
    );
  }
}

/// Shared secret of the TURN relay. Masked in the subtitle; the edit
/// dialog starts obscured with a plain-text toggle.
class RelaySecretTile extends ConsumerWidget {
  const RelaySecretTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relay = ref.watch(relaySettingsProvider);
    return ListTile(
      title: Text(context.t.setting.relay.secret),
      subtitle: Text(
        relay.secret.isEmpty ? context.t.setting.relay.notSet : '••••••',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: FilledButton(
        onPressed: () async {
          final value = await showRelayFieldDialog(
            context,
            title: context.t.setting.relay.secret,
            initial: relay.secret,
            obscureText: true,
          );
          if (value != null) {
            await ref.read(relaySettingsProvider.notifier).setSecret(value);
          }
        },
        child: Text(context.t.setting.relay.edit),
      ),
    );
  }
}

/// Footer note of a settings group: the group's values join the core
/// config at startup, so a change needs an app restart.
class SettingEffectHint extends StatelessWidget {
  final String text;

  const SettingEffectHint({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.x16,
        right: AppSpacing.x16,
        bottom: AppSpacing.x8,
      ),
      child: Text(
        text,
        // Supporting text: body-small on on-surface-variant.
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Relay group footer: relay settings join the core config at
/// startup, so a change needs an app restart.
class RelayEffectHint extends StatelessWidget {
  const RelayEffectHint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingEffectHint(text: context.t.setting.relay.restartHint);
  }
}

/// Security group footer: the TLS toggle joins the core config at
/// startup, so a change needs an app restart.
class TlsEffectHint extends StatelessWidget {
  const TlsEffectHint({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingEffectHint(text: context.t.setting.security.restartHint);
  }
}

/// End-to-end encryption (TLS) toggle. Persisted with the other app
/// settings and fed into the core config on the next app start; the
/// core runs plain HTTP while disabled.
class TlsTile extends ConsumerWidget {
  const TlsTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tlsEnabled = ref.watch(tlsSettingsProvider);
    return SwitchListTile(
      title: Text(context.t.setting.security.tls),
      subtitle: tlsEnabled
          ? null
          : Text(
              context.t.setting.security.plainWarning,
              // Warning: error color separates the plain-HTTP state
              // from ordinary supporting text.
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
      value: tlsEnabled,
      onChanged: (value) {
        ref.read(tlsSettingsProvider.notifier).setEnabled(value);
      },
    );
  }
}
