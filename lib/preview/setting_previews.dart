import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/providers/relay_provider.dart';
import '../i18n/strings.g.dart';
import '../view/widget/relay_widgets.dart';
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
        RelayImportTile(),
        RelayTestTile(),
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
      height: 420,
      // Plain previewOverrides() still routes the relay provider to
      // the empty mock — the real one would hit ConfigStore, which is
      // not initialized in the previewer.
      overrides: previewOverrides(),
      child: const _RelayGroup(),
    );

/// Relay settings, configured: address shown as entered, secret
/// masked; the import entry and test button are enabled.
@Preview(name: 'Relay settings (configured)')
Widget relaySettingsConfiguredPreview() => previewShell(
      name: 'relaySettingsConfigured',
      height: 420,
      overrides: previewOverrides(
        relay: const RelayConfig(
          addr: 'turn.example.com:3478',
          secret: 'topsecret',
        ),
      ),
      child: const _RelayGroup(),
    );

/// Relay test tile, unset relay: the test button is disabled.
@Preview(name: 'Relay test (disabled)')
Widget relayTestDisabledPreview() => previewShell(
      name: 'relayTestDisabled',
      height: 180,
      overrides: previewOverrides(),
      child: const SettingTileGroup(
        title: 'Relay Server',
        children: [RelayTestTile()],
      ),
    );

/// Relay test tile, probe answered: the RTT shows under the button.
@Preview(name: 'Relay test (result)')
Widget relayTestResultPreview() => previewShell(
      name: 'relayTestResult',
      height: 180,
      overrides: previewOverrides(
        relay: const RelayConfig(
          addr: 'turn.example.com:3478',
          secret: 'topsecret',
        ),
        ping: const RelayPingOk(12),
      ),
      child: const SettingTileGroup(
        title: 'Relay Server',
        children: [RelayTestTile()],
      ),
    );

/// Relay test tile, probe failed: the failure shows in error color.
@Preview(name: 'Relay test (error)')
Widget relayTestErrorPreview() => previewShell(
      name: 'relayTestError',
      height: 180,
      overrides: previewOverrides(
        relay: const RelayConfig(
          addr: 'turn.example.com:3478',
          secret: 'topsecret',
        ),
        ping: const RelayPingError('no relay configured'),
      ),
      child: const SettingTileGroup(
        title: 'Relay Server',
        children: [RelayTestTile()],
      ),
    );

/// Relay import dialog. Mounted directly (not as a route) so the
/// paste field and actions stay previewable; the QR entry is
/// mobile-only and stays hidden under the desktop previewer.
@Preview(name: 'Relay import dialog')
Widget relayImportDialogPreview() => previewShell(
      name: 'relayImportDialog',
      height: 460,
      overrides: previewOverrides(),
      child: const Center(child: RelayImportDialog()),
    );

/// Confirm dialog for a scanned/pasted invite: address in the clear,
/// secret masked.
@Preview(name: 'Relay invite confirm dialog')
Widget relayInviteConfirmPreview() => previewShell(
      name: 'relayInviteConfirm',
      height: 460,
      overrides: previewOverrides(),
      child: const Center(
        child: RelayInviteConfirmDialog(
          invite: RelayInvite(
            addr: 'turn.example.com:3478',
            secret: 'topsecret',
          ),
        ),
      ),
    );

/// Security group as mounted on the settings page. Resolves the
/// group title at build time so it follows the preview locale.
class _SecurityGroup extends StatelessWidget {
  const _SecurityGroup();

  @override
  Widget build(BuildContext context) {
    return SettingTileGroup(
      title: context.t.setting.security.title,
      children: const [
        TlsTile(),
        TlsEffectHint(),
      ],
    );
  }
}

/// End-to-end TLS, on (default): switch on, no warning.
@Preview(name: 'TLS enabled')
Widget tlsEnabledPreview() => previewShell(
      name: 'tlsEnabled',
      height: 220,
      overrides: previewOverrides(tlsEnabled: true),
      child: const _SecurityGroup(),
    );

/// End-to-end TLS, off: switch off plus the plain-transport warning.
@Preview(name: 'TLS disabled')
Widget tlsDisabledPreview() => previewShell(
      name: 'tlsDisabled',
      height: 220,
      overrides: previewOverrides(tlsEnabled: false),
      child: const _SecurityGroup(),
    );
