import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:localsend_rs/core/rust/bridge.dart';
import 'package:localsend_rs/core/rust/session/model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class SessionState extends ChangeNotifier {
  static SessionState? _instance;

  SessionVm? session;

  late final StreamSubscription<SessionVm?> subMission;

  static SessionState instance() {
    _instance ??= SessionState._();
    return _instance!;
  }

  SessionState._() {
    subMission = listenSession().listen(
      (event) {
        session = event;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    subMission.cancel();
    super.dispose();
  }
}
