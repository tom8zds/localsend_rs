import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_rs/core/providers/relay_provider.dart';

void main() {
  group('RelayInvite.parse deep links', () {
    test('parses addr and secret from the configure link', () {
      expect(
        RelayInvite.parse(
            'localsend-relay://configure?addr=turn.example.com:3478&secret=s3cret'),
        const RelayInvite(addr: 'turn.example.com:3478', secret: 's3cret'),
      );
    });

    test('decodes percent-encoded values', () {
      expect(
        RelayInvite.parse(
            'localsend-relay://configure?addr=turn.example.com%3A3478&secret=a%20b'),
        const RelayInvite(addr: 'turn.example.com:3478', secret: 'a b'),
      );
    });

    test('matches the scheme case-insensitively', () {
      expect(
        RelayInvite.parse(
            'LOCALSEND-RELAY://configure?addr=host:1&secret=s'),
        const RelayInvite(addr: 'host:1', secret: 's'),
      );
    });

    test('tolerates surrounding whitespace', () {
      expect(
        RelayInvite.parse(
            '  localsend-relay://configure?addr=host:1&secret=s\n'),
        const RelayInvite(addr: 'host:1', secret: 's'),
      );
    });

    test('rejects a link missing the secret', () {
      expect(
        RelayInvite.parse('localsend-relay://configure?addr=host:1'),
        isNull,
      );
    });

    test('rejects a link missing the addr', () {
      expect(
        RelayInvite.parse('localsend-relay://configure?secret=s'),
        isNull,
      );
    });

    test('rejects a foreign scheme', () {
      expect(
        RelayInvite.parse('https://example.com/configure?addr=h:1&secret=s'),
        isNull,
      );
    });
  });

  group('RelayInvite.parse bare lines', () {
    test('parses addr|secret', () {
      expect(
        RelayInvite.parse('turn.example.com:3478|s3cret'),
        const RelayInvite(addr: 'turn.example.com:3478', secret: 's3cret'),
      );
    });

    test('tolerates spaces around both fields', () {
      expect(
        RelayInvite.parse('  host:1 | secret with spaces  '),
        const RelayInvite(addr: 'host:1', secret: 'secret with spaces'),
      );
    });

    test('keeps separator characters inside the secret', () {
      expect(
        RelayInvite.parse('host:1|a|b'),
        const RelayInvite(addr: 'host:1', secret: 'a|b'),
      );
    });

    test('tolerates multi-line QR payloads', () {
      expect(
        RelayInvite.parse('host:1|secret\n'),
        const RelayInvite(addr: 'host:1', secret: 'secret'),
      );
    });

    test('rejects a line missing either field', () {
      expect(RelayInvite.parse('host:1|'), isNull);
      expect(RelayInvite.parse('|secret'), isNull);
      expect(RelayInvite.parse('|'), isNull);
    });

    test('rejects empty and separator-free input', () {
      expect(RelayInvite.parse(''), isNull);
      expect(RelayInvite.parse('   '), isNull);
      expect(RelayInvite.parse('host:1'), isNull);
    });
  });

  group('summarizeError', () {
    test('strips the exception class prefix', () {
      expect(
        summarizeError('AnyhowException: no relay configured'),
        'no relay configured',
      );
    });

    test('keeps a plain message intact', () {
      expect(summarizeError('192.168.1.1:3478 refused'), '192.168.1.1:3478 refused');
    });

    test('keeps the first line only', () {
      expect(
        summarizeError('AnyhowException: boom\nbacktrace'),
        'boom',
      );
    });
  });
}
