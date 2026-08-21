import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_rs/core/providers/relay_provider.dart';
import 'package:localsend_rs/core/providers/session_providers.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/core/store/config_store.dart';
import 'package:localsend_rs/preview/preview_scaffold.dart';
import 'package:localsend_rs/view/widget/relay_widgets.dart';
import 'package:localsend_rs/view/widget/session_card.dart';
import 'package:localsend_rs/view/widget/setting_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RelayPing mock that reports a fixed RTT after one event-loop turn,
/// so tests can observe the loading state in between.
class _OkPing extends RelayPing {
  @override
  RelayPingState build() => const RelayPingIdle();

  @override
  Future<void> run() async {
    state = const RelayPingLoading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = const RelayPingOk(12);
  }
}

/// RelayPing mock that fails after one event-loop turn.
class _FailingPing extends RelayPing {
  @override
  RelayPingState build() => const RelayPingIdle();

  @override
  Future<void> run() async {
    state = const RelayPingLoading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = const RelayPingError('no relay configured');
  }
}

void main() {
  // The import-flow tests below confirm invites, which writes through
  // RelaySettings into the ConfigStore.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigStore.ensureInitialized();
  });
  group('RelayConfig', () {
    test('empty fields map to null and disable routing', () {
      const unset = RelayConfig();
      expect(unset.enabled, isFalse);
      expect(unset.relayAddr, isNull);
      expect(unset.relaySecret, isNull);
    });

    test('routing needs both address and secret', () {
      const addrOnly = RelayConfig(addr: 'turn.example.com:3478');
      expect(addrOnly.enabled, isFalse);

      const full = RelayConfig(addr: 'turn.example.com:3478', secret: 's');
      expect(full.enabled, isTrue);
      expect(full.relayAddr, 'turn.example.com:3478');
      expect(full.relaySecret, 's');
    });

    test('copyWith replaces only the given field', () {
      const base = RelayConfig(addr: 'a:1');
      final updated = base.copyWith(secret: 's');
      expect(updated.addr, 'a:1');
      expect(updated.secret, 's');
      expect(updated, isNot(base));
    });
  });

  group('SessionCard relay badge', () {
    testWidgets('shows the via-relay marker for relayed sessions',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'badgeShown',
        overrides: previewOverrides(
          extras: {'relay-1': const SessionExtras()},
        ),
        child: SessionCard(
          summary: mockSession(
            id: 'relay-1',
            direction: SessionDirection.send,
            state: MissionState.transfering,
            viaRelay: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Via relay'), findsOneWidget);
    });

    testWidgets('direct sessions carry no marker', (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'badgeAbsent',
        overrides: previewOverrides(
          extras: {'direct-1': const SessionExtras()},
        ),
        child: SessionCard(
          summary: mockSession(
            id: 'direct-1',
            direction: SessionDirection.send,
            state: MissionState.transfering,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Via relay'), findsNothing);
    });
  });

  group('Relay settings tiles', () {
    testWidgets('unset relay shows "Not set" for both fields', (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'relayUnset',
        height: 320,
        overrides: previewOverrides(),
        child: const SettingTileGroup(
          title: 'Relay Server',
          children: [
            RelayAddressTile(),
            RelaySecretTile(),
            RelayEffectHint(),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsNWidgets(2));
    });

    testWidgets('configured relay shows the address and masks the secret',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'relayConfigured',
        height: 320,
        overrides: previewOverrides(
          relay: const RelayConfig(
            addr: 'turn.example.com:3478',
            secret: 'topsecret',
          ),
        ),
        child: const SettingTileGroup(
          title: 'Relay Server',
          children: [
            RelayAddressTile(),
            RelaySecretTile(),
            RelayEffectHint(),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('turn.example.com:3478'), findsOneWidget);
      expect(find.text('••••••'), findsOneWidget);
      expect(find.text('Not set'), findsNothing);
    });
  });

  group('RelayTestTile', () {
    Widget testGroup(
      RelayConfig relay, {
      RelayPing Function()? pingImpl,
    }) {
      return previewShell(
        name: 'relayTest-${relay.enabled}-${pingImpl != null}',
        height: 180,
        overrides: previewOverrides(relay: relay, pingImpl: pingImpl),
        child: const SettingTileGroup(
          title: 'Relay Server',
          children: [RelayTestTile()],
        ),
      );
    }

    testWidgets('disabled while the relay is not configured',
        (tester) async {
      await tester.pumpWidget(
          testGroup(const RelayConfig(addr: 'turn.example.com:3478')));
      await tester.pumpAndSettle();

      final button =
          tester.widget<FilledButton>(find.byType(FilledButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets('runs loading then shows the RTT', (tester) async {
      await tester.pumpWidget(testGroup(
        const RelayConfig(addr: 'turn.example.com:3478', secret: 's'),
        pingImpl: _OkPing.new,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // Loading: spinner up, button inert.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );

      await tester.pumpAndSettle();
      expect(find.text('12 ms'), findsOneWidget);
    });

    testWidgets('shows the failure in place of the RTT', (tester) async {
      await tester.pumpWidget(testGroup(
        const RelayConfig(addr: 'turn.example.com:3478', secret: 's'),
        pingImpl: _FailingPing.new,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Failed: no relay configured'), findsOneWidget);
    });
  });

  group('RelayImportTile', () {
    testWidgets('rejects unrecognized paste with an inline error',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'relayImportInvalid',
        height: 320,
        overrides: previewOverrides(),
        child: const SettingTileGroup(
          title: 'Relay Server',
          children: [RelayImportTile()],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'not an invite');
      // The dialog's import action is the last FilledButton ("Import").
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(find.text('Unrecognized relay configuration'), findsOneWidget);
    });

    testWidgets('valid paste reaches the confirm dialog and persists',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'relayImportFlow',
        height: 320,
        overrides: previewOverrides(),
        child: const SettingTileGroup(
          title: 'Relay Server',
          children: [RelayImportTile()],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'localsend-relay://configure?addr=turn.example.com:3478&secret=topsecret',
      );
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      // Confirm dialog: address in the clear, secret masked, raw
      // secret absent.
      expect(find.text('Apply Relay Configuration?'), findsOneWidget);
      expect(find.text('turn.example.com:3478'), findsOneWidget);
      expect(find.text('••••••'), findsOneWidget);
      expect(find.text('topsecret'), findsNothing);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // The invite was written into the persisted relay settings.
      expect(ConfigStore().relayAddr(), 'turn.example.com:3478');
      expect(ConfigStore().relaySecret(), 'topsecret');
      expect(find.text('Relay saved; restart the app to apply'),
          findsOneWidget);
    });
  });

  group('RelayInviteConfirmDialog', () {
    testWidgets('shows the address in the clear and the secret masked',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'relayInviteConfirm',
        height: 460,
        overrides: previewOverrides(),
        child: const RelayInviteConfirmDialog(
          invite: RelayInvite(
            addr: 'turn.example.com:3478',
            secret: 'topsecret',
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Apply Relay Configuration?'), findsOneWidget);
      expect(find.text('turn.example.com:3478'), findsOneWidget);
      expect(find.text('••••••'), findsOneWidget);
      expect(find.text('topsecret'), findsNothing);
    });
  });
}
