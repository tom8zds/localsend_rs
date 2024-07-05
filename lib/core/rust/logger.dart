// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class LogEntry {
  final PlatformInt64 timeMillis;
  final int level;
  final String tag;
  final String msg;

  const LogEntry({
    required this.timeMillis,
    required this.level,
    required this.tag,
    required this.msg,
  });

  @override
  int get hashCode =>
      timeMillis.hashCode ^ level.hashCode ^ tag.hashCode ^ msg.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogEntry &&
          runtimeType == other.runtimeType &&
          timeMillis == other.timeMillis &&
          level == other.level &&
          tag == other.tag &&
          msg == other.msg;
}
