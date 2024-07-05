import 'package:localsend_rs/core/rust/actor/mission/pending.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../listeners/pending_mission_listener.dart';
import '../rust/actor/model.dart';

part 'mission_provider.g.dart';

@riverpod
class PendingMission extends _$PendingMission {
  @override
  PendingMissionDto build() {
    final subPendingMission = PendingMissionListener.instance().stream.listen(
      (event) {
        state = event;
      },
    );
    ref.onDispose(() {
      subPendingMission.cancel();
    });
    return const PendingMissionDto(state: MissionState.idle);
  }
}
