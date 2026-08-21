import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';
import '../store/config_store.dart';

part 'session_providers.g.dart';

/// Low-frequency full snapshot of all transfer sessions (both
/// directions). Widgets must watch this instead of touching the Rust
/// stream directly.
@Riverpod(keepAlive: true)
Stream<List<SessionSummary>> sessionIndex(Ref ref) => listenSessionIndex();

/// Per-session event stream (state changes, per-file states, byte
/// progress, failures).
@riverpod
Stream<SessionEvent> sessionEvent(Ref ref, String sessionId) =>
    listenSession(sessionId: sessionId);

/// Receive sessions waiting for the user's decision.
@riverpod
List<SessionSummary> pendingReceiveSessions(Ref ref) {
  final sessions =
      ref.watch(sessionIndexProvider).value ?? const <SessionSummary>[];
  return sessions
      .where((s) =>
          s.direction == SessionDirection.receive &&
          s.state == MissionState.pending)
      .toList();
}

/// Live per-session data that the session index snapshots do not carry:
/// transferred byte counters per file and the failure reason.
class SessionExtras {
  final Map<String, int> progress;
  final String? failureReason;

  const SessionExtras({this.progress = const {}, this.failureReason});

  int bytesFor(String fileId) => progress[fileId] ?? 0;
}

/// Fold one session event into the accumulated extras.
SessionExtras reduceSessionExtras(SessionExtras current, SessionEvent event) {
  return switch (event) {
    SessionEvent_Progress(:final fileId, :final bytes) => SessionExtras(
        progress: {...current.progress, fileId: bytes.toInt()},
        failureReason: current.failureReason,
      ),
    SessionEvent_Failed(:final reason) => SessionExtras(
        progress: current.progress,
        failureReason: reason,
      ),
    _ => current,
  };
}

/// Accumulates [`SessionExtras`] from the per-session event stream.
@riverpod
class SessionExtrasNotifier extends _$SessionExtrasNotifier {
  @override
  SessionExtras build(String sessionId) {
    ref.listen(sessionEventProvider(sessionId), (_, next) {
      final event = next.value;
      if (event != null) {
        state = reduceSessionExtras(state, event);
      }
    });
    return const SessionExtras();
  }
}

/// Persisted quick-save toggle: accept incoming sessions without
/// confirmation.
@Riverpod(keepAlive: true)
class QuickSave extends _$QuickSave {
  @override
  bool build() => ConfigStore().quickSave();

  Future<void> set(bool value) async {
    await ConfigStore().setQuickSave(value);
    state = value;
  }
}

/// Accepts pending receive sessions automatically while quick save is
/// enabled. Watched once by the app frame; the state is the set of
/// session ids already acted on.
@Riverpod(keepAlive: true)
class AutoAccept extends _$AutoAccept {
  @override
  Set<String> build() {
    ref.listen(sessionIndexProvider, (_, next) {
      if (!ref.read(quickSaveProvider)) {
        return;
      }
      for (final session
          in next.value ?? const <SessionSummary>[]) {
        if (session.direction == SessionDirection.receive &&
            session.state == MissionState.pending &&
            !state.contains(session.id)) {
          state = {...state, session.id};
          acceptSession(sessionId: session.id);
        }
      }
    });
    return {};
  }
}
