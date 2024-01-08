// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.5.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables

import 'api/simple.dart';
import 'core/model.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  DeviceConfig dco_decode_box_autoadd_device_config(dynamic raw);

  @protected
  ServerConfig dco_decode_box_autoadd_server_config(dynamic raw);

  @protected
  DeviceConfig dco_decode_device_config(dynamic raw);

  @protected
  DeviceInfo dco_decode_device_info(dynamic raw);

  @protected
  DiscoverState dco_decode_discover_state(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  int dco_decode_i_64(dynamic raw);

  @protected
  List<DeviceInfo> dco_decode_list_device_info(dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8(dynamic raw);

  @protected
  LogEntry dco_decode_log_entry(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  Progress dco_decode_progress(dynamic raw);

  @protected
  ServerConfig dco_decode_server_config(dynamic raw);

  @protected
  ServerStatus dco_decode_server_status(dynamic raw);

  @protected
  int dco_decode_u_16(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  int dco_decode_usize(dynamic raw);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  DeviceConfig sse_decode_box_autoadd_device_config(
      SseDeserializer deserializer);

  @protected
  ServerConfig sse_decode_box_autoadd_server_config(
      SseDeserializer deserializer);

  @protected
  DeviceConfig sse_decode_device_config(SseDeserializer deserializer);

  @protected
  DeviceInfo sse_decode_device_info(SseDeserializer deserializer);

  @protected
  DiscoverState sse_decode_discover_state(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  int sse_decode_i_64(SseDeserializer deserializer);

  @protected
  List<DeviceInfo> sse_decode_list_device_info(SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8(SseDeserializer deserializer);

  @protected
  LogEntry sse_decode_log_entry(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  Progress sse_decode_progress(SseDeserializer deserializer);

  @protected
  ServerConfig sse_decode_server_config(SseDeserializer deserializer);

  @protected
  ServerStatus sse_decode_server_status(SseDeserializer deserializer);

  @protected
  int sse_decode_u_16(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  int sse_decode_usize(SseDeserializer deserializer);

  @protected
  String cst_encode_String(String raw) {
    return raw;
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_device_config(DeviceConfig raw) {
    return cst_encode_device_config(raw);
  }

  @protected
  List<dynamic> cst_encode_box_autoadd_server_config(ServerConfig raw) {
    return cst_encode_server_config(raw);
  }

  @protected
  List<dynamic> cst_encode_device_config(DeviceConfig raw) {
    return [
      cst_encode_String(raw.alias),
      cst_encode_String(raw.fingerprint),
      cst_encode_String(raw.deviceModel),
      cst_encode_String(raw.deviceType),
      cst_encode_String(raw.storePath)
    ];
  }

  @protected
  List<dynamic> cst_encode_device_info(DeviceInfo raw) {
    return [
      cst_encode_String(raw.alias),
      cst_encode_String(raw.version),
      cst_encode_String(raw.deviceModel),
      cst_encode_String(raw.deviceType),
      cst_encode_String(raw.fingerprint),
      cst_encode_opt_String(raw.address),
      cst_encode_u_16(raw.port),
      cst_encode_String(raw.protocol),
      cst_encode_bool(raw.download),
      cst_encode_bool(raw.announcement),
      cst_encode_bool(raw.announce)
    ];
  }

  @protected
  List<dynamic> cst_encode_discover_state(DiscoverState raw) {
    if (raw is DiscoverState_Discovering) {
      return [0, cst_encode_list_device_info(raw.field0)];
    }
    if (raw is DiscoverState_Done) {
      return [1];
    }

    throw Exception('unreachable');
  }

  @protected
  Object cst_encode_i_64(int raw) {
    return castNativeBigInt(raw);
  }

  @protected
  List<dynamic> cst_encode_list_device_info(List<DeviceInfo> raw) {
    return raw.map(cst_encode_device_info).toList();
  }

  @protected
  Uint8List cst_encode_list_prim_u_8(Uint8List raw) {
    return raw;
  }

  @protected
  List<dynamic> cst_encode_log_entry(LogEntry raw) {
    return [
      cst_encode_i_64(raw.timeMillis),
      cst_encode_i_32(raw.level),
      cst_encode_String(raw.tag),
      cst_encode_String(raw.msg)
    ];
  }

  @protected
  String? cst_encode_opt_String(String? raw) {
    return raw == null ? null : cst_encode_String(raw);
  }

  @protected
  List<dynamic> cst_encode_progress(Progress raw) {
    if (raw is Progress_Prepare) {
      return [0];
    }
    if (raw is Progress_Idle) {
      return [1];
    }
    if (raw is Progress_Progress) {
      return [2, cst_encode_usize(raw.field0), cst_encode_usize(raw.field1)];
    }
    if (raw is Progress_Done) {
      return [3];
    }

    throw Exception('unreachable');
  }

  @protected
  List<dynamic> cst_encode_server_config(ServerConfig raw) {
    return [
      cst_encode_String(raw.multicastAddr),
      cst_encode_u_16(raw.port),
      cst_encode_String(raw.protocol),
      cst_encode_bool(raw.download),
      cst_encode_bool(raw.announcement),
      cst_encode_bool(raw.announce)
    ];
  }

  @protected
  bool cst_encode_bool(bool raw);

  @protected
  int cst_encode_i_32(int raw);

  @protected
  int cst_encode_server_status(ServerStatus raw);

  @protected
  int cst_encode_u_16(int raw);

  @protected
  int cst_encode_u_8(int raw);

  @protected
  void cst_encode_unit(void raw);

  @protected
  int cst_encode_usize(int raw);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_device_config(
      DeviceConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_server_config(
      ServerConfig self, SseSerializer serializer);

  @protected
  void sse_encode_device_config(DeviceConfig self, SseSerializer serializer);

  @protected
  void sse_encode_device_info(DeviceInfo self, SseSerializer serializer);

  @protected
  void sse_encode_discover_state(DiscoverState self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_64(int self, SseSerializer serializer);

  @protected
  void sse_encode_list_device_info(
      List<DeviceInfo> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8(Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_log_entry(LogEntry self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void sse_encode_progress(Progress self, SseSerializer serializer);

  @protected
  void sse_encode_server_config(ServerConfig self, SseSerializer serializer);

  @protected
  void sse_encode_server_status(ServerStatus self, SseSerializer serializer);

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

class RustLibWire extends BaseWire {
  RustLibWire.fromExternalLibrary(ExternalLibrary lib);

  void dart_fn_deliver_output(int call_id, PlatformGeneralizedUint8ListPtr ptr_,
          int rust_vec_len_, int data_len_) =>
      wasmModule.dart_fn_deliver_output(
          call_id, ptr_, rust_vec_len_, data_len_);

  void wire_accept(NativePortType port_, bool is_accept) =>
      wasmModule.wire_accept(port_, is_accept);

  void wire_create_log_stream(NativePortType port_) =>
      wasmModule.wire_create_log_stream(port_);

  void wire_discover(NativePortType port_) => wasmModule.wire_discover(port_);

  void wire_init_server(NativePortType port_, List<dynamic> device) =>
      wasmModule.wire_init_server(port_, device);

  void wire_listen_discover(NativePortType port_) =>
      wasmModule.wire_listen_discover(port_);

  void wire_listen_progress(NativePortType port_) =>
      wasmModule.wire_listen_progress(port_);

  void wire_rust_set_up(NativePortType port_, bool isDebug) =>
      wasmModule.wire_rust_set_up(port_, isDebug);

  void wire_server_status(NativePortType port_) =>
      wasmModule.wire_server_status(port_);

  void wire_start_server(NativePortType port_, List<dynamic> config) =>
      wasmModule.wire_start_server(port_, config);

  void wire_stop_server(NativePortType port_) =>
      wasmModule.wire_stop_server(port_);
}

@JS('wasm_bindgen')
external RustLibWasmModule get wasmModule;

@JS()
@anonymous
class RustLibWasmModule implements WasmModule {
  @override
  external Object /* Promise */ call([String? moduleName]);

  @override
  external RustLibWasmModule bind(dynamic thisArg, String moduleName);

  external void dart_fn_deliver_output(int call_id,
      PlatformGeneralizedUint8ListPtr ptr_, int rust_vec_len_, int data_len_);

  external void wire_accept(NativePortType port_, bool is_accept);

  external void wire_create_log_stream(NativePortType port_);

  external void wire_discover(NativePortType port_);

  external void wire_init_server(NativePortType port_, List<dynamic> device);

  external void wire_listen_discover(NativePortType port_);

  external void wire_listen_progress(NativePortType port_);

  external void wire_rust_set_up(NativePortType port_, bool isDebug);

  external void wire_server_status(NativePortType port_);

  external void wire_start_server(NativePortType port_, List<dynamic> config);

  external void wire_stop_server(NativePortType port_);
}
