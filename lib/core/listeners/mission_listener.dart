import 'package:localsend_rs/core/rust/bridge.dart';

import '../rust/actor/mission.dart';

class MissionListener {
  static MissionListener? _instance;
  MissionListener._();

  static MissionListener instance() {
    _instance ??= MissionListener._();
    return _instance!;
  }

  Stream<MissionInfo?> stream = listenMission();
}
