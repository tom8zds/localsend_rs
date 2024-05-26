import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/rust/bridge/bridge.dart';
import 'package:localsend_rs/rust/discovery/model.dart';

class CoreProvider extends ChangeNotifier {
  List<MissionItem> missions = [];
  List<Node> nodes = [];

  CoreProvider() {
    missionChannel(dartCallback: updateMission);
    nodeChannel(dartCallback: updateNodes);
  }

  Future<String> updateMission(List<MissionItem> missions) async {
    this.missions = missions;
    notifyListeners();
    return "";
  }

  Future<String> updateNodes(List<Node> nodes) async {
    this.nodes = nodes;
    notifyListeners();
    return "";
  }
}

final coreProvider =
    ChangeNotifierProvider<CoreProvider>((ref) => CoreProvider());
