import 'package:localsend_rs/core/listeners/core_listener.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';

part 'core_provider.g.dart';

class RustCoreState {
  final bool serverState;
  final List<NodeDevice> devices;

  RustCoreState({required this.serverState, required this.devices});

  RustCoreState copyWith({bool? serverState, List<NodeDevice>? devices}) =>
      RustCoreState(
        serverState: serverState ?? this.serverState,
        devices: devices ?? this.devices,
      );
}

@riverpod
class CoreState extends _$CoreState {
  @override
  RustCoreState build() {
    final subServerState = CoreListener.instance().stateStream.listen(
      (event) {
        state = state.copyWith(serverState: event);
      },
    );
    final subDevice = CoreListener.instance().deviceStream.listen(
      (event) {
        state = state.copyWith(devices: event);
      },
    );
    ref.onDispose(() {
      subServerState.cancel();
      subDevice.cancel();
    });
    return RustCoreState(serverState: false, devices: []);
  }
}
