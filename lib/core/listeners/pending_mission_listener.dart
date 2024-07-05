import 'package:localsend_rs/core/rust/bridge.dart';

import '../rust/actor/mission/pending.dart';

class PendingMissionListener {
  static PendingMissionListener? _instance;
  PendingMissionListener._();

  static PendingMissionListener instance() {
    _instance ??= PendingMissionListener._();
    return _instance!;
  }

  Stream<PendingMissionDto> stream = listenPendingMission();
}
