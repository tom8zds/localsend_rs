// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.4.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

enum MissionState {
  idle,
  pending,
  transfering,
  finished,
  failed,
  canceled,
  busy,
  ;
}

class NodeDevice {
  final String alias;
  final String version;
  final String deviceModel;
  final String deviceType;
  final String fingerprint;
  final String address;
  final int port;
  final String protocol;
  final bool download;
  final bool announcement;
  final bool announce;

  const NodeDevice({
    required this.alias,
    required this.version,
    required this.deviceModel,
    required this.deviceType,
    required this.fingerprint,
    required this.address,
    required this.port,
    required this.protocol,
    required this.download,
    required this.announcement,
    required this.announce,
  });

  @override
  int get hashCode =>
      alias.hashCode ^
      version.hashCode ^
      deviceModel.hashCode ^
      deviceType.hashCode ^
      fingerprint.hashCode ^
      address.hashCode ^
      port.hashCode ^
      protocol.hashCode ^
      download.hashCode ^
      announcement.hashCode ^
      announce.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeDevice &&
          runtimeType == other.runtimeType &&
          alias == other.alias &&
          version == other.version &&
          deviceModel == other.deviceModel &&
          deviceType == other.deviceType &&
          fingerprint == other.fingerprint &&
          address == other.address &&
          port == other.port &&
          protocol == other.protocol &&
          download == other.download &&
          announcement == other.announcement &&
          announce == other.announce;
}
