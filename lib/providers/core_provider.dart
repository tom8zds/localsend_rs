import 'package:equatable/equatable.dart';
import 'package:localsend_rs/rust/actor/model.dart';
import 'package:localsend_rs/rust/bridge.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
    final subServerState = listenServerState().listen(
      (event) {
        state = state.copyWith(serverState: event);
      },
    );
    final subDevice = listenDevice().listen(
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
