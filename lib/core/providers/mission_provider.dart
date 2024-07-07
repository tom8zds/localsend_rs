import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../listeners/mission_listener.dart';
import '../rust/actor/mission.dart';

part 'mission_provider.g.dart';

@riverpod
class CoreMission extends _$CoreMission {
  @override
  MissionInfo? build() {
    final subMission = MissionListener.instance().stream.listen(
      (event) {
        state = event;
      },
    );
    ref.onDispose(() {
      subMission.cancel();
    });
    return null;
  }
}
