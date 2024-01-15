// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.5.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../api/model.dart';
import '../discovery/model.dart';
import '../frb_generated.dart';
import '../logger.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Stream<LogEntry> createLogStream({dynamic hint}) =>
    RustLib.instance.api.createLogStream(hint: hint);

Future<void> rustSetUp({required bool isDebug, dynamic hint}) =>
    RustLib.instance.api.rustSetUp(isDebug: isDebug, hint: hint);

Future<void> setup({dynamic hint}) => RustLib.instance.api.setup(hint: hint);

Future<void> start({dynamic hint}) => RustLib.instance.api.start(hint: hint);

Future<void> stop({dynamic hint}) => RustLib.instance.api.stop(hint: hint);

Future<void> discover({dynamic hint}) =>
    RustLib.instance.api.discover(hint: hint);

Future<void> acceptMission(
        {required String missionId, required bool accept, dynamic hint}) =>
    RustLib.instance.api
        .acceptMission(missionId: missionId, accept: accept, hint: hint);

Stream<List<Node>> nodeChannel({dynamic hint}) =>
    RustLib.instance.api.nodeChannel(hint: hint);

Stream<MissionItem> missionChannel({dynamic hint}) =>
    RustLib.instance.api.missionChannel(hint: hint);

class MissionItem {
  final String id;
  final List<FileInfo> fileInfo;

  const MissionItem({
    required this.id,
    required this.fileInfo,
  });

  @override
  int get hashCode => id.hashCode ^ fileInfo.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileInfo == other.fileInfo;
}
