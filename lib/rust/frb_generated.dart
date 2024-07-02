// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.33.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'actor/core.dart';
import 'actor/model.dart';
import 'bridge.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.io.dart' if (dart.library.html) 'frb_generated.web.dart';
import 'logger.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Main entrypoint of the Rust API
class RustLib extends BaseEntrypoint<RustLibApi, RustLibApiImpl, RustLibWire> {
  @internal
  static final instance = RustLib._();

  RustLib._();

  /// Initialize flutter_rust_bridge
  static Future<void> init({
    RustLibApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
  }) async {
    await instance.initImpl(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary,
    );
  }

  /// Dispose flutter_rust_bridge
  ///
  /// The call to this function is optional, since flutter_rust_bridge (and everything else)
  /// is automatically disposed when the app stops.
  static void dispose() => instance.disposeImpl();

  @override
  ApiImplConstructor<RustLibApiImpl, RustLibWire> get apiImplConstructor =>
      RustLibApiImpl.new;

  @override
  WireConstructor<RustLibWire> get wireConstructor =>
      RustLibWire.fromExternalLibrary;

  @override
  Future<void> executeRustInitializers() async {}

  @override
  ExternalLibraryLoaderConfig get defaultExternalLibraryLoaderConfig =>
      kDefaultExternalLibraryLoaderConfig;

  @override
  String get codegenVersion => '2.0.0-dev.33';

  @override
  int get rustContentHash => -1477711227;

  static const kDefaultExternalLibraryLoaderConfig =
      ExternalLibraryLoaderConfig(
    stem: 'rust_lib',
    ioDirectory: 'rust/target/release/',
    webPrefix: 'pkg/',
  );
}

abstract class RustLibApi extends BaseApi {
  Future<void> changeConfig({required CoreConfig config, dynamic hint});

  Future<LogEntry> getLog({dynamic hint});

  Stream<List<NodeDevice>> listenDevice({dynamic hint});

  Future<void> setup({dynamic hint});

  Future<void> shutdownServer({dynamic hint});

  Future<void> startServer({dynamic hint});

  RustArcIncrementStrongCountFnType
      get rust_arc_increment_strong_count_CoreConfig;

  RustArcDecrementStrongCountFnType
      get rust_arc_decrement_strong_count_CoreConfig;

  CrossPlatformFinalizerArg get rust_arc_decrement_strong_count_CoreConfigPtr;
}

class RustLibApiImpl extends RustLibApiImplPlatform implements RustLibApi {
  RustLibApiImpl({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @override
  Future<void> changeConfig({required CoreConfig config, dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
            config, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 4, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kChangeConfigConstMeta,
      argValues: [config],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kChangeConfigConstMeta => const TaskConstMeta(
        debugName: "change_config",
        argNames: ["config"],
      );

  @override
  Future<LogEntry> getLog({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 5, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_log_entry,
        decodeErrorData: null,
      ),
      constMeta: kGetLogConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kGetLogConstMeta => const TaskConstMeta(
        debugName: "get_log",
        argNames: [],
      );

  @override
  Stream<List<NodeDevice>> listenDevice({dynamic hint}) {
    final s = RustStreamSink<List<NodeDevice>>();
    unawaited(handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_StreamSink_list_node_device_Sse(s, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 6, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kListenDeviceConstMeta,
      argValues: [s],
      apiImpl: this,
      hint: hint,
    )));
    return s.stream;
  }

  TaskConstMeta get kListenDeviceConstMeta => const TaskConstMeta(
        debugName: "listen_device",
        argNames: ["s"],
      );

  @override
  Future<void> setup({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 1, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kSetupConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kSetupConstMeta => const TaskConstMeta(
        debugName: "setup",
        argNames: [],
      );

  @override
  Future<void> shutdownServer({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 3, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kShutdownServerConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kShutdownServerConstMeta => const TaskConstMeta(
        debugName: "shutdown_server",
        argNames: [],
      );

  @override
  Future<void> startServer({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 2, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kStartServerConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kStartServerConstMeta => const TaskConstMeta(
        debugName: "start_server",
        argNames: [],
      );

  RustArcIncrementStrongCountFnType
      get rust_arc_increment_strong_count_CoreConfig => wire
          .rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig;

  RustArcDecrementStrongCountFnType
      get rust_arc_decrement_strong_count_CoreConfig => wire
          .rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig;

  @protected
  CoreConfig
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return CoreConfig.dcoDecode(raw as List<dynamic>);
  }

  @protected
  CoreConfig
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return CoreConfig.dcoDecode(raw as List<dynamic>);
  }

  @protected
  RustStreamSink<List<NodeDevice>> dco_decode_StreamSink_list_node_device_Sse(
      dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    throw UnimplementedError();
  }

  @protected
  String dco_decode_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as String;
  }

  @protected
  bool dco_decode_bool(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as bool;
  }

  @protected
  int dco_decode_i_32(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  int dco_decode_i_64(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return dcoDecodeI64OrU64(raw);
  }

  @protected
  List<NodeDevice> dco_decode_list_node_device(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_node_device).toList();
  }

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as Uint8List;
  }

  @protected
  LogEntry dco_decode_log_entry(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 4)
      throw Exception('unexpected arr length: expect 4 but see ${arr.length}');
    return LogEntry(
      timeMillis: dco_decode_i_64(arr[0]),
      level: dco_decode_i_32(arr[1]),
      tag: dco_decode_String(arr[2]),
      msg: dco_decode_String(arr[3]),
    );
  }

  @protected
  NodeDevice dco_decode_node_device(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 11)
      throw Exception('unexpected arr length: expect 11 but see ${arr.length}');
    return NodeDevice(
      alias: dco_decode_String(arr[0]),
      version: dco_decode_String(arr[1]),
      deviceModel: dco_decode_String(arr[2]),
      deviceType: dco_decode_String(arr[3]),
      fingerprint: dco_decode_String(arr[4]),
      address: dco_decode_String(arr[5]),
      port: dco_decode_u_16(arr[6]),
      protocol: dco_decode_String(arr[7]),
      download: dco_decode_bool(arr[8]),
      announcement: dco_decode_bool(arr[9]),
      announce: dco_decode_bool(arr[10]),
    );
  }

  @protected
  int dco_decode_u_16(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  int dco_decode_u_8(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  void dco_decode_unit(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return;
  }

  @protected
  int dco_decode_usize(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return dcoDecodeI64OrU64(raw);
  }

  @protected
  CoreConfig
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return CoreConfig.sseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  CoreConfig
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return CoreConfig.sseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  RustStreamSink<List<NodeDevice>> sse_decode_StreamSink_list_node_device_Sse(
      SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    throw UnimplementedError('Unreachable ()');
  }

  @protected
  String sse_decode_String(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_list_prim_u_8_strict(deserializer);
    return utf8.decoder.convert(inner);
  }

  @protected
  bool sse_decode_bool(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8() != 0;
  }

  @protected
  int sse_decode_i_32(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getInt32();
  }

  @protected
  int sse_decode_i_64(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getInt64();
  }

  @protected
  List<NodeDevice> sse_decode_list_node_device(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <NodeDevice>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_node_device(deserializer));
    }
    return ans_;
  }

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var len_ = sse_decode_i_32(deserializer);
    return deserializer.buffer.getUint8List(len_);
  }

  @protected
  LogEntry sse_decode_log_entry(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_timeMillis = sse_decode_i_64(deserializer);
    var var_level = sse_decode_i_32(deserializer);
    var var_tag = sse_decode_String(deserializer);
    var var_msg = sse_decode_String(deserializer);
    return LogEntry(
        timeMillis: var_timeMillis,
        level: var_level,
        tag: var_tag,
        msg: var_msg);
  }

  @protected
  NodeDevice sse_decode_node_device(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_alias = sse_decode_String(deserializer);
    var var_version = sse_decode_String(deserializer);
    var var_deviceModel = sse_decode_String(deserializer);
    var var_deviceType = sse_decode_String(deserializer);
    var var_fingerprint = sse_decode_String(deserializer);
    var var_address = sse_decode_String(deserializer);
    var var_port = sse_decode_u_16(deserializer);
    var var_protocol = sse_decode_String(deserializer);
    var var_download = sse_decode_bool(deserializer);
    var var_announcement = sse_decode_bool(deserializer);
    var var_announce = sse_decode_bool(deserializer);
    return NodeDevice(
        alias: var_alias,
        version: var_version,
        deviceModel: var_deviceModel,
        deviceType: var_deviceType,
        fingerprint: var_fingerprint,
        address: var_address,
        port: var_port,
        protocol: var_protocol,
        download: var_download,
        announcement: var_announcement,
        announce: var_announce);
  }

  @protected
  int sse_decode_u_16(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint16();
  }

  @protected
  int sse_decode_u_8(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8();
  }

  @protected
  void sse_decode_unit(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  int sse_decode_usize(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint64();
  }

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          CoreConfig self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(self.sseEncode(move: true), serializer);
  }

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerCoreConfig(
          CoreConfig self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(self.sseEncode(move: null), serializer);
  }

  @protected
  void sse_encode_StreamSink_list_node_device_Sse(
      RustStreamSink<List<NodeDevice>> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(
        self.setupAndSerialize(
            codec: SseCodec(
                decodeSuccessData: sse_decode_list_node_device,
                decodeErrorData: null)),
        serializer);
  }

  @protected
  void sse_encode_String(String self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_list_prim_u_8_strict(utf8.encoder.convert(self), serializer);
  }

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self ? 1 : 0);
  }

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putInt32(self);
  }

  @protected
  void sse_encode_i_64(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putInt64(self);
  }

  @protected
  void sse_encode_list_node_device(
      List<NodeDevice> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_node_device(item, serializer);
    }
  }

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    serializer.buffer.putUint8List(self);
  }

  @protected
  void sse_encode_log_entry(LogEntry self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_64(self.timeMillis, serializer);
    sse_encode_i_32(self.level, serializer);
    sse_encode_String(self.tag, serializer);
    sse_encode_String(self.msg, serializer);
  }

  @protected
  void sse_encode_node_device(NodeDevice self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.alias, serializer);
    sse_encode_String(self.version, serializer);
    sse_encode_String(self.deviceModel, serializer);
    sse_encode_String(self.deviceType, serializer);
    sse_encode_String(self.fingerprint, serializer);
    sse_encode_String(self.address, serializer);
    sse_encode_u_16(self.port, serializer);
    sse_encode_String(self.protocol, serializer);
    sse_encode_bool(self.download, serializer);
    sse_encode_bool(self.announcement, serializer);
    sse_encode_bool(self.announce, serializer);
  }

  @protected
  void sse_encode_u_16(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint16(self);
  }

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self);
  }

  @protected
  void sse_encode_unit(void self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  void sse_encode_usize(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint64(self);
  }
}
