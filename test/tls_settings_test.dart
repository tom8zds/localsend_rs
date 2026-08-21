import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_rs/common/utils.dart';
import 'package:localsend_rs/core/providers/tls_provider.dart';
import 'package:localsend_rs/core/store/config_store.dart';
import 'package:localsend_rs/preview/preview_scaffold.dart';
import 'package:localsend_rs/view/widget/setting_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // Only the first setUp takes effect: ConfigStore caches the mock
    // prefs instance, so tests below must not rely on a fresh store
    // (order the default-value test first).
    SharedPreferences.setMockInitialValues({});
    await ConfigStore.ensureInitialized();
  });

  group('TLS persistence', () {
    test('defaults to enabled', () {
      expect(ConfigStore().tlsEnabled(), isTrue);
    });

    test('round-trips through the store', () async {
      await ConfigStore().setTlsEnabled(false);
      expect(ConfigStore().tlsEnabled(), isFalse);
      await ConfigStore().setTlsEnabled(true);
      expect(ConfigStore().tlsEnabled(), isTrue);
    });
  });

  group('identityDir wiring', () {
    test('enabled maps to the tls subdirectory of the documents dir',
        () {
      expect(
        identityDirFor(tlsEnabled: true, baseDir: '/data/user/docs'),
        '/data/user/docs${Platform.pathSeparator}tls',
      );
    });

    test('disabled maps to null (plain HTTP)', () {
      expect(
        identityDirFor(tlsEnabled: false, baseDir: '/data/user/docs'),
        isNull,
      );
    });
  });

  group('TlsSettings provider', () {
    test('builds from the store and persists changes', () async {
      await ConfigStore().setTlsEnabled(true);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Holds the autoDispose provider alive across the awaits below.
      final sub = container.listen(tlsSettingsProvider, (_, __) {});

      expect(sub.read(), isTrue);

      await container.read(tlsSettingsProvider.notifier).setEnabled(false);

      expect(container.read(tlsSettingsProvider), isFalse);
      expect(ConfigStore().tlsEnabled(), isFalse);
    });
  });

  group('TlsTile', () {
    const title = 'End-to-end Encryption (TLS)';
    const warning = 'Unencrypted transfer; recommended for debugging only';

    testWidgets('enabled: switch on, no warning', (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'tlsOn',
        height: 220,
        overrides: previewOverrides(tlsEnabled: true),
        child: const SettingTileGroup(
          title: 'Security',
          children: [TlsTile()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(warning), findsNothing);
    });

    testWidgets('disabled: switch off with the plain-transport warning',
        (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'tlsOff',
        height: 220,
        overrides: previewOverrides(tlsEnabled: false),
        child: const SettingTileGroup(
          title: 'Security',
          children: [TlsTile()],
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text(warning), findsOneWidget);
    });

    testWidgets('tapping the switch toggles TLS on', (tester) async {
      await tester.pumpWidget(previewShell(
        name: 'tlsToggle',
        height: 220,
        overrides: previewOverrides(tlsEnabled: false),
        child: const SettingTileGroup(
          title: 'Security',
          children: [TlsTile()],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text(warning), findsNothing);
    });
  });
}
