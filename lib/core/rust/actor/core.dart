// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.4.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class CoreConfig {
  final int port;
  final String interfaceAddr;
  final String multicastAddr;
  final int multicastPort;
  final String storePath;

  const CoreConfig({
    required this.port,
    required this.interfaceAddr,
    required this.multicastAddr,
    required this.multicastPort,
    required this.storePath,
  });

  @override
  int get hashCode =>
      port.hashCode ^
      interfaceAddr.hashCode ^
      multicastAddr.hashCode ^
      multicastPort.hashCode ^
      storePath.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreConfig &&
          runtimeType == other.runtimeType &&
          port == other.port &&
          interfaceAddr == other.interfaceAddr &&
          multicastAddr == other.multicastAddr &&
          multicastPort == other.multicastPort &&
          storePath == other.storePath;
}
