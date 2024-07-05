// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

class FileInfo {
  final String id;
  final String fileName;
  final PlatformInt64 size;
  final String fileType;
  final String? sha256;
  final Uint8List? preview;

  const FileInfo({
    required this.id,
    required this.fileName,
    required this.size,
    required this.fileType,
    this.sha256,
    this.preview,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      fileName.hashCode ^
      size.hashCode ^
      fileType.hashCode ^
      sha256.hashCode ^
      preview.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          size == other.size &&
          fileType == other.fileType &&
          sha256 == other.sha256 &&
          preview == other.preview;
}
