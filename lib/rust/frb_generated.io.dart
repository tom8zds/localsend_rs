// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.33.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/model.dart';
import 'bridge/bridge.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'discovery/model.dart';
import 'frb_generated.dart';
import 'logger.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @protected
  FutureOr<String> Function(List<MissionItem>)
      dco_decode_DartFn_Inputs_list_mission_item_Output_String(dynamic raw);

  @protected
  FutureOr<String> Function(List<Node>)
      dco_decode_DartFn_Inputs_list_node_Output_String(dynamic raw);

  @protected
  Object dco_decode_DartOpaque(dynamic raw);

  @protected
  RustStreamSink<LogEntry> dco_decode_StreamSink_log_entry_Sse(dynamic raw);

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  FileInfo dco_decode_file_info(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  int dco_decode_i_64(dynamic raw);

  @protected
  List<FileInfo> dco_decode_list_file_info(dynamic raw);

  @protected
  List<MissionItem> dco_decode_list_mission_item(dynamic raw);

  @protected
  List<Node> dco_decode_list_node(dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw);

  @protected
  LogEntry dco_decode_log_entry(dynamic raw);

  @protected
  MissionItem dco_decode_mission_item(dynamic raw);

  @protected
  MissionState dco_decode_mission_state(dynamic raw);

  @protected
  Node dco_decode_node(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  Uint8List? dco_decode_opt_list_prim_u_8_strict(dynamic raw);

  @protected
  ServerState dco_decode_server_state(dynamic raw);

  @protected
  int dco_decode_u_16(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  int dco_decode_usize(dynamic raw);

  @protected
  Object sse_decode_DartOpaque(SseDeserializer deserializer);

  @protected
  RustStreamSink<LogEntry> sse_decode_StreamSink_log_entry_Sse(
      SseDeserializer deserializer);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  FileInfo sse_decode_file_info(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  int sse_decode_i_64(SseDeserializer deserializer);

  @protected
  List<FileInfo> sse_decode_list_file_info(SseDeserializer deserializer);

  @protected
  List<MissionItem> sse_decode_list_mission_item(SseDeserializer deserializer);

  @protected
  List<Node> sse_decode_list_node(SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  LogEntry sse_decode_log_entry(SseDeserializer deserializer);

  @protected
  MissionItem sse_decode_mission_item(SseDeserializer deserializer);

  @protected
  MissionState sse_decode_mission_state(SseDeserializer deserializer);

  @protected
  Node sse_decode_node(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  Uint8List? sse_decode_opt_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  ServerState sse_decode_server_state(SseDeserializer deserializer);

  @protected
  int sse_decode_u_16(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  int sse_decode_usize(SseDeserializer deserializer);

  @protected
  void sse_encode_DartFn_Inputs_list_mission_item_Output_String(
      FutureOr<String> Function(List<MissionItem>) self,
      SseSerializer serializer);

  @protected
  void sse_encode_DartFn_Inputs_list_node_Output_String(
      FutureOr<String> Function(List<Node>) self, SseSerializer serializer);

  @protected
  void sse_encode_DartOpaque(Object self, SseSerializer serializer);

  @protected
  void sse_encode_StreamSink_log_entry_Sse(
      RustStreamSink<LogEntry> self, SseSerializer serializer);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_file_info(FileInfo self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_64(int self, SseSerializer serializer);

  @protected
  void sse_encode_list_file_info(List<FileInfo> self, SseSerializer serializer);

  @protected
  void sse_encode_list_mission_item(
      List<MissionItem> self, SseSerializer serializer);

  @protected
  void sse_encode_list_node(List<Node> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_log_entry(LogEntry self, SseSerializer serializer);

  @protected
  void sse_encode_mission_item(MissionItem self, SseSerializer serializer);

  @protected
  void sse_encode_mission_state(MissionState self, SseSerializer serializer);

  @protected
  void sse_encode_node(Node self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_list_prim_u_8_strict(
      Uint8List? self, SseSerializer serializer);

  @protected
  void sse_encode_server_state(ServerState self, SseSerializer serializer);

  @protected
  void sse_encode_u_16(int self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);

  @protected
  void sse_encode_usize(int self, SseSerializer serializer);
}

// Section: wire_class

class RustLibWire implements BaseWire {
  factory RustLibWire.fromExternalLibrary(ExternalLibrary lib) =>
      RustLibWire(lib.ffiDynamicLibrary);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  RustLibWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;
}
