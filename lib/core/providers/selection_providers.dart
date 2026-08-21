import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';

part 'selection_providers.g.dart';

/// Files staged for sending, shared between the home page quick-send,
/// the device list tap-to-send shortcut and the send page.
@riverpod
class SelectedFiles extends _$SelectedFiles {
  @override
  List<String> build() => [];

  void addAll(Iterable<String> paths) {
    final seen = state.toSet();
    state = [...state, ...paths.where(seen.add)];
  }

  void remove(String path) {
    state = state.where((p) => p != path).toList();
  }

  void clear() {
    state = [];
  }
}

/// Result of dispatching one send batch: targets that failed to start,
/// mapped to the error.
typedef SendFailures = Map<NodeDevice, Object>;

/// Send `files` to every target. The core returns a session id per
/// target immediately and serializes sessions per target, so dispatch
/// order does not matter. Targets that fail to start (e.g. unreadable
/// file) are collected instead of throwing so one bad target does not
/// block the rest.
Future<SendFailures> sendFilesToTargets({
  required List<NodeDevice> targets,
  required List<String> files,
}) async {
  final failures = <NodeDevice, Object>{};
  for (final target in targets) {
    try {
      await sendFiles(target: target, files: files);
    } catch (e) {
      failures[target] = e;
    }
  }
  return failures;
}
