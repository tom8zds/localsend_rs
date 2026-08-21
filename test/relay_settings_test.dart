import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_rs/core/providers/relay_provider.dart';
import 'package:localsend_rs/core/providers/session_providers.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/preview/preview_scaffold.dart';
import 'package:localsend_rs/view/widget/session_card.dart';
import 'package:localsend_rs/view/widget/setting_widgets.dart';

void main() {
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
}
