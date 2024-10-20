import 'dart:async';

import 'package:flutter/material.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';

class RustCoreState extends ChangeNotifier {
  bool serverState = false;
  List<NodeDevice> devices = [];

  late final StreamSubscription<bool> subServerState;
  late final StreamSubscription<List<NodeDevice>> subDevice;

  static RustCoreState? _instance;

  static RustCoreState instance() {
    _instance ??= RustCoreState._();
    return _instance!;
  }

  RustCoreState._() {
    subServerState = listenServerState().listen(
      (event) {
        serverState = event;
        notifyListeners();
      },
    );
    subDevice = listenDevice().listen(
      (event) {
        devices = event;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    subServerState.cancel();
    subDevice.cancel();
    super.dispose();
  }
}
