import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/providers/relay_provider.dart';
import '../i18n/strings.g.dart';
import '../view/widget/setting_widgets.dart';
import 'preview_scaffold.dart';

/// Relay settings group as mounted on the settings page. Resolves the
/// group title at build time so it follows the preview locale.
class _RelayGroup extends StatelessWidget {
  const _RelayGroup();

  @override
  Widget build(BuildContext context) {
    return SettingTileGroup(
      title: context.t.setting.relay.title,
      children: const [
        RelayAddressTile(),
        RelaySecretTile(),
        RelayEffectHint(),
      ],
    );
  }
}

/// Relay settings, unset: both fields show "Not set" and the
/// restart-hint footer.
@Preview(name: 'Relay settings (unset)')
Widget relaySettingsUnsetPreview() => previewShell(
      name: 'relaySettingsUnset',
      height: 300,
      // Plain previewOverrides() still routes the relay provider to
      // the empty mock — the real one would hit ConfigStore, which is
      // not initialized in the previewer.
      overrides: previewOverrides(),
      child: const _RelayGroup(),
    );

/// Relay settings, configured: address shown as entered, secret
/// masked.
@Preview(name: 'Relay settings (configured)')
Widget relaySettingsConfiguredPreview() => previewShell(
      name: 'relaySettingsConfigured',
      height: 300,
      overrides: previewOverrides(
        relay: const RelayConfig(
          addr: 'turn.example.com:3478',
          secret: 'topsecret',
        ),
      ),
      child: const _RelayGroup(),
    );
