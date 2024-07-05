import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/core/rust/bridge.dart';

class CoreListener {
  static CoreListener? _instance;
  CoreListener._();

  static CoreListener instance() {
    _instance ??= CoreListener._();
    return _instance!;
  }

  Stream<bool> stateStream = listenServerState();
  Stream<List<NodeDevice>> deviceStream = listenDevice();
}
