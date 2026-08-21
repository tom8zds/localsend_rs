import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/spacing.dart';
import '../../core/providers/relay_provider.dart';
import '../../i18n/strings.g.dart';
import '../pages/relay_scan_page.dart';

/// Whether the device has a camera the QR entry point can use; the
/// scan action stays hidden on desktops.
bool get relayScanSupported => Platform.isAndroid || Platform.isIOS;

/// "Import configuration" entry of the relay settings group: opens
/// the paste/scan dialog; a successful import goes through the same
/// confirm dialog as a deep link.
class RelayImportTile extends ConsumerWidget {
  const RelayImportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(context.t.setting.relay.importTitle),
      subtitle: Text(context.t.setting.relay.importHint),
      trailing: FilledButton(
        onPressed: () => _openImport(context, ref),
        child: Text(context.t.setting.relay.import),
      ),
    );
  }

  Future<void> _openImport(BuildContext context, WidgetRef ref) async {
    final invite = await showRelayImportDialog(context);
    if (invite == null || !context.mounted) {
      return;
    }
    await showRelayInviteConfirm(context: context, ref: ref, invite: invite);
  }
}

/// "Test connection" entry of the relay settings group: STUN-probes
/// the configured relay and shows the RTT (or the failure) inline.
/// Disabled until both relay fields are set.
class RelayTestTile extends ConsumerWidget {
  const RelayTestTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relay = ref.watch(relaySettingsProvider);
    final ping = ref.watch(relayPingProvider);

    final (subtitle, failed) = switch (ping) {
      RelayPingIdle() => (context.t.setting.relay.testHint, false),
      RelayPingLoading() => (context.t.setting.relay.testHint, false),
      RelayPingOk(:final rttMs) =>
        (context.t.setting.relay.testResult(ms: rttMs), false),
      RelayPingError(:final message) =>
        (context.t.setting.relay.testFailed(reason: message), true),
    };

    return ListTile(
      title: Text(context.t.setting.relay.test),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: failed
            // Failure separates from ordinary supporting text, like
            // the TLS plain-transport warning.
            ? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                )
            : null,
      ),
      trailing: FilledButton(
        // Idle + unconfigured disables the probe; loading keeps the
        // button inert while the spinner is up.
        onPressed: !relay.enabled || ping is RelayPingLoading
            ? null
            : () => ref.read(relayPingProvider.notifier).run(),
        child: ping is RelayPingLoading
            ? const SizedBox(
                width: AppSpacing.x16,
                height: AppSpacing.x16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.t.setting.relay.testAction),
      ),
    );
  }
}

/// Paste/scan relay-import dialog. The scan action is mobile only;
/// both paths feed their text through `RelayInvite.parse` and pop
/// with the parsed invite. Public so previews can mount it directly.
class RelayImportDialog extends StatefulWidget {
  const RelayImportDialog({super.key});

  @override
  State<RelayImportDialog> createState() => _RelayImportDialogState();
}

class _RelayImportDialogState extends State<RelayImportDialog> {
  late final TextEditingController _controller = TextEditingController()
    ..addListener(() {
      if (_invalid) {
        setState(() {
          _invalid = false;
        });
      }
    });
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const RelayScanPage()),
    );
    if (text == null || !mounted) {
      return;
    }
    _controller.text = text;
    _submit();
  }

  void _submit() {
    final invite = RelayInvite.parse(_controller.text);
    if (invite == null) {
      setState(() {
        _invalid = true;
      });
      return;
    }
    Navigator.of(context).pop(invite);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.setting.relay.importTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: t.setting.relay.importHint,
              errorText: _invalid ? t.setting.relay.importInvalid : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (relayScanSupported)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x12),
              child: OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(t.setting.relay.scanQr),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.setting.relay.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(t.setting.relay.import),
        ),
      ],
    );
  }
}

/// Opens the paste/scan import dialog; returns the parsed invite, or
/// null when cancelled/unrecognized.
Future<RelayInvite?> showRelayImportDialog(BuildContext context) {
  return showDialog<RelayInvite>(
    context: context,
    builder: (context) => const RelayImportDialog(),
  );
}

/// Confirm dialog for an invite: the address in the clear, the secret
/// masked. Confirms with true; cancel/back dismisses with false.
class RelayInviteConfirmDialog extends StatelessWidget {
  final RelayInvite invite;

  const RelayInviteConfirmDialog({super.key, required this.invite});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.setting.relay.confirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledValue(
            label: t.setting.relay.address,
            value: invite.addr,
          ),
          const SizedBox(height: AppSpacing.x8),
          _LabeledValue(
            label: t.setting.relay.secret,
            value: '••••••',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.setting.relay.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.setting.relay.apply),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          // Supporting text: body-small on on-surface-variant.
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Shows the invite confirm dialog; on confirmation writes the invite
/// into the persisted relay settings and tells the user a restart is
/// needed. Returns whether the settings were written.
Future<bool> showRelayInviteConfirm({
  required BuildContext context,
  required WidgetRef ref,
  required RelayInvite invite,
}) async {
  final applied = await showDialog<bool>(
        context: context,
        builder: (context) => RelayInviteConfirmDialog(invite: invite),
      ) ??
      false;
  if (!applied) {
    return false;
  }

  final notifier = ref.read(relaySettingsProvider.notifier);
  await notifier.setAddr(invite.addr);
  await notifier.setSecret(invite.secret);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.setting.relay.savedRestart)),
    );
  }
  return true;
}

/// Hosts the app body and routes `localsend-relay://` links into the
/// shared invite confirm dialog. Handles both the cold-start link
/// (`getInitialLink`) and links delivered while running
/// (`uriLinkStream`); mount it as the `home:` of the app.
class RelayInviteHost extends ConsumerStatefulWidget {
  final Widget child;

  const RelayInviteHost({super.key, required this.child});

  @override
  ConsumerState<RelayInviteHost> createState() => _RelayInviteHostState();
}

class _RelayInviteHostState extends ConsumerState<RelayInviteHost> {
  StreamSubscription<Uri>? _links;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    final appLinks = AppLinks();
    // Running app: the OS re-delivers the link to the single instance.
    _links = appLinks.uriLinkStream.listen(
      _onLink,
      // Plugin stream errors (no OS handler, dbus hiccup) are not
      // actionable in the UI; ignoring keeps the app usable.
      onError: (Object _) {},
    );
    // Cold start: the link that launched the process, deferred to the
    // first frame so the dialog has a context to attach to. Platforms
    // that replay the initial link on the stream are covered by the
    // [_dialogOpen] guard below.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final link = await appLinks.getInitialLink();
      if (link != null) {
        await _onLink(link);
      }
    });
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  Future<void> _onLink(Uri link) async {
    if (link.scheme != relayDeepLinkScheme || _dialogOpen) {
      return;
    }
    final invite = RelayInvite.parse(link.toString());
    if (invite == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    _dialogOpen = true;
    try {
      await showRelayInviteConfirm(
        context: context,
        ref: ref,
        invite: invite,
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
