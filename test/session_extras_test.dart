import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_rs/core/providers/session_providers.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/view/pages/transfers_page.dart';

import 'package:localsend_rs/preview/preview_scaffold.dart';

void main() {
  group('reduceSessionExtras', () {
    test('accumulates byte progress per file', () {
      var extras = const SessionExtras();
      extras = reduceSessionExtras(
        extras,
        const SessionEvent.progress(fileId: 'a', bytes: 100),
      );
      extras = reduceSessionExtras(
        extras,
        const SessionEvent.progress(fileId: 'b', bytes: 50),
      );
      extras = reduceSessionExtras(
        extras,
        const SessionEvent.progress(fileId: 'a', bytes: 200),
      );

      expect(extras.bytesFor('a'), 200);
      expect(extras.bytesFor('b'), 50);
      expect(extras.bytesFor('missing'), 0);
      expect(extras.failureReason, isNull);
    });

    test('records the failure reason and keeps progress', () {
      var extras = const SessionExtras(
        progress: {'a': 42},
      );
      extras = reduceSessionExtras(
        extras,
        const SessionEvent.failed(reason: 'declined by receiver'),
      );

      expect(extras.failureReason, 'declined by receiver');
      expect(extras.bytesFor('a'), 42);
    });

    test('ignores state and file-state events', () {
      const initial = SessionExtras(
        progress: {'a': 1},
        failureReason: 'boom',
      );
      final afterState = reduceSessionExtras(
        initial,
        const SessionEvent.stateChanged(MissionState.transfering),
      );
      final afterFileState = reduceSessionExtras(
        initial,
        const SessionEvent.fileStateChanged(
          fileId: 'a',
          state: FileState.finish(),
        ),
      );

      expect(identical(afterState, initial), isTrue);
      expect(identical(afterFileState, initial), isTrue);
    });
  });

  group('TransfersPage.sortSessions', () {
    test('orders pending receive, then active, then terminal', () {
      final pending = mockSession(
        id: '1-pending',
        direction: SessionDirection.receive,
        state: MissionState.pending,
      );
      final transferring = mockSession(
        id: '2-transfer',
        direction: SessionDirection.send,
        state: MissionState.transfering,
      );
      final pendingSend = mockSession(
        id: '3-pending-send',
        direction: SessionDirection.send,
        state: MissionState.pending,
      );
      final finished = mockSession(
        id: '4-finished',
        direction: SessionDirection.receive,
        state: MissionState.finished,
      );

      final sorted = TransfersPage.sortSessions(
        [finished, pendingSend, transferring, pending],
      );

      expect(
        sorted.map((s) => s.id),
        ['1-pending', '2-transfer', '3-pending-send', '4-finished'],
      );
    });
  });
}
