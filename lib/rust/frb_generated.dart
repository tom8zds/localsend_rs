// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.33.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/model.dart';
import 'bridge/bridge.dart';
import 'dart:async';
import 'dart:convert';
import 'discovery/model.dart';
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
  int get rustContentHash => -15602752;

  static const kDefaultExternalLibraryLoaderConfig =
      ExternalLibraryLoaderConfig(
    stem: 'rust_lib',
    ioDirectory: 'rust/target/release/',
    webPrefix: 'pkg/',
  );
}

abstract class RustLibApi extends BaseApi {
  Future<void> acceptMission(
      {required String missionId, required bool accept, dynamic hint});

  Future<void> clearMissions({dynamic hint});

  Stream<LogEntry> createLogStream({dynamic hint});

  Future<void> discover({dynamic hint});

  Future<void> missionChannel(
      {required FutureOr<String> Function(List<MissionItem>) dartCallback,
      dynamic hint});

  Future<void> nodeChannel(
      {required FutureOr<String> Function(List<Node>) dartCallback,
      dynamic hint});

  Future<void> rustSetUp({required bool isDebug, dynamic hint});

  Future<void> setup({dynamic hint});

  Future<void> start({dynamic hint});

  Future<ServerState> state({dynamic hint});

  Future<void> stop({dynamic hint});
}

class RustLibApiImpl extends RustLibApiImplPlatform implements RustLibApi {
  RustLibApiImpl({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @override
  Future<void> acceptMission(
      {required String missionId, required bool accept, dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_String(missionId, serializer);
        sse_encode_bool(accept, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 8, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kAcceptMissionConstMeta,
      argValues: [missionId, accept],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kAcceptMissionConstMeta => const TaskConstMeta(
        debugName: "accept_mission",
        argNames: ["missionId", "accept"],
      );

  @override
  Future<void> clearMissions({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 9, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kClearMissionsConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kClearMissionsConstMeta => const TaskConstMeta(
        debugName: "clear_missions",
        argNames: [],
      );

  @override
  Stream<LogEntry> createLogStream({dynamic hint}) {
    final s = RustStreamSink<LogEntry>();
    unawaited(handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_StreamSink_log_entry_Sse(s, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 1, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: sse_decode_String,
      ),
      constMeta: kCreateLogStreamConstMeta,
      argValues: [s],
      apiImpl: this,
      hint: hint,
    )));
    return s.stream;
  }

  TaskConstMeta get kCreateLogStreamConstMeta => const TaskConstMeta(
        debugName: "create_log_stream",
        argNames: ["s"],
      );

  @override
  Future<void> discover({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 7, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kDiscoverConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kDiscoverConstMeta => const TaskConstMeta(
        debugName: "discover",
        argNames: [],
      );

  @override
  Future<void> missionChannel(
      {required FutureOr<String> Function(List<MissionItem>) dartCallback,
      dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_DartFn_Inputs_list_mission_item_Output_String(
            dartCallback, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 11, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kMissionChannelConstMeta,
      argValues: [dartCallback],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kMissionChannelConstMeta => const TaskConstMeta(
        debugName: "mission_channel",
        argNames: ["dartCallback"],
      );

  @override
  Future<void> nodeChannel(
      {required FutureOr<String> Function(List<Node>) dartCallback,
      dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_DartFn_Inputs_list_node_Output_String(
            dartCallback, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 10, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kNodeChannelConstMeta,
      argValues: [dartCallback],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kNodeChannelConstMeta => const TaskConstMeta(
        debugName: "node_channel",
        argNames: ["dartCallback"],
      );

  @override
  Future<void> rustSetUp({required bool isDebug, dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_bool(isDebug, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 2, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kRustSetUpConstMeta,
      argValues: [isDebug],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kRustSetUpConstMeta => const TaskConstMeta(
        debugName: "rust_set_up",
        argNames: ["isDebug"],
      );

  @override
  Future<void> setup({dynamic hint}) {
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
  Future<void> start({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 4, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kStartConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kStartConstMeta => const TaskConstMeta(
        debugName: "start",
        argNames: [],
      );

  @override
  Future<ServerState> state({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 6, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_server_state,
        decodeErrorData: null,
      ),
      constMeta: kStateConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kStateConstMeta => const TaskConstMeta(
        debugName: "state",
        argNames: [],
      );

  @override
  Future<void> stop({dynamic hint}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 5, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kStopConstMeta,
      argValues: [],
      apiImpl: this,
      hint: hint,
    ));
  }

  TaskConstMeta get kStopConstMeta => const TaskConstMeta(
        debugName: "stop",
        argNames: [],
      );

  Future<void> Function(int, dynamic)
      encode_DartFn_Inputs_list_mission_item_Output_String(
          FutureOr<String> Function(List<MissionItem>) raw) {
    return (callId, rawArg0) async {
      final arg0 = dco_decode_list_mission_item(rawArg0);

      final rawOutput = await raw(arg0);

      final serializer = SseSerializer(generalizedFrbRustBinding);
      sse_encode_String(rawOutput, serializer);
      final output = serializer.intoRaw();

      generalizedFrbRustBinding.dartFnDeliverOutput(
          callId: callId,
          ptr: output.ptr,
          rustVecLen: output.rustVecLen,
          dataLen: output.dataLen);
    };
  }

  Future<void> Function(int, dynamic)
      encode_DartFn_Inputs_list_node_Output_String(
          FutureOr<String> Function(List<Node>) raw) {
    return (callId, rawArg0) async {
      final arg0 = dco_decode_list_node(rawArg0);

      final rawOutput = await raw(arg0);

      final serializer = SseSerializer(generalizedFrbRustBinding);
      sse_encode_String(rawOutput, serializer);
      final output = serializer.intoRaw();

      generalizedFrbRustBinding.dartFnDeliverOutput(
          callId: callId,
          ptr: output.ptr,
          rustVecLen: output.rustVecLen,
          dataLen: output.dataLen);
    };
  }

  @protected
  FutureOr<String> Function(List<MissionItem>)
      dco_decode_DartFn_Inputs_list_mission_item_Output_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    throw UnimplementedError('');
  }

  @protected
  FutureOr<String> Function(List<Node>)
      dco_decode_DartFn_Inputs_list_node_Output_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    throw UnimplementedError('');
  }

  @protected
  Object dco_decode_DartOpaque(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return decodeDartOpaque(raw, generalizedFrbRustBinding);
  }

  @protected
  RustStreamSink<LogEntry> dco_decode_StreamSink_log_entry_Sse(dynamic raw) {
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
  FileInfo dco_decode_file_info(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 6)
      throw Exception('unexpected arr length: expect 6 but see ${arr.length}');
    return FileInfo(
      id: dco_decode_String(arr[0]),
      fileName: dco_decode_String(arr[1]),
      size: dco_decode_i_64(arr[2]),
      fileType: dco_decode_String(arr[3]),
      sha256: dco_decode_opt_String(arr[4]),
      preview: dco_decode_opt_list_prim_u_8_strict(arr[5]),
    );
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
  List<FileInfo> dco_decode_list_file_info(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_file_info).toList();
  }

  @protected
  List<MissionItem> dco_decode_list_mission_item(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_mission_item).toList();
  }

  @protected
  List<Node> dco_decode_list_node(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_node).toList();
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
  MissionItem dco_decode_mission_item(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 3)
      throw Exception('unexpected arr length: expect 3 but see ${arr.length}');
    return MissionItem(
      id: dco_decode_String(arr[0]),
      state: dco_decode_mission_state(arr[1]),
      fileInfo: dco_decode_list_file_info(arr[2]),
    );
  }

  @protected
  MissionState dco_decode_mission_state(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return MissionState.values[raw as int];
  }

  @protected
  Node dco_decode_node(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 11)
      throw Exception('unexpected arr length: expect 11 but see ${arr.length}');
    return Node(
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
  String? dco_decode_opt_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw == null ? null : dco_decode_String(raw);
  }

  @protected
  Uint8List? dco_decode_opt_list_prim_u_8_strict(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw == null ? null : dco_decode_list_prim_u_8_strict(raw);
  }

  @protected
  ServerState dco_decode_server_state(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return ServerState.values[raw as int];
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
  Object sse_decode_DartOpaque(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_usize(deserializer);
    return decodeDartOpaque(inner, generalizedFrbRustBinding);
  }

  @protected
  RustStreamSink<LogEntry> sse_decode_StreamSink_log_entry_Sse(
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
  FileInfo sse_decode_file_info(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_fileName = sse_decode_String(deserializer);
    var var_size = sse_decode_i_64(deserializer);
    var var_fileType = sse_decode_String(deserializer);
    var var_sha256 = sse_decode_opt_String(deserializer);
    var var_preview = sse_decode_opt_list_prim_u_8_strict(deserializer);
    return FileInfo(
        id: var_id,
        fileName: var_fileName,
        size: var_size,
        fileType: var_fileType,
        sha256: var_sha256,
        preview: var_preview);
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
  List<FileInfo> sse_decode_list_file_info(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <FileInfo>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_file_info(deserializer));
    }
    return ans_;
  }

  @protected
  List<MissionItem> sse_decode_list_mission_item(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <MissionItem>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_mission_item(deserializer));
    }
    return ans_;
  }

  @protected
  List<Node> sse_decode_list_node(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <Node>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_node(deserializer));
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
  MissionItem sse_decode_mission_item(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_id = sse_decode_String(deserializer);
    var var_state = sse_decode_mission_state(deserializer);
    var var_fileInfo = sse_decode_list_file_info(deserializer);
    return MissionItem(id: var_id, state: var_state, fileInfo: var_fileInfo);
  }

  @protected
  MissionState sse_decode_mission_state(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_i_32(deserializer);
    return MissionState.values[inner];
  }

  @protected
  Node sse_decode_node(SseDeserializer deserializer) {
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
    return Node(
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
  String? sse_decode_opt_String(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    if (sse_decode_bool(deserializer)) {
      return (sse_decode_String(deserializer));
    } else {
      return null;
    }
  }

  @protected
  Uint8List? sse_decode_opt_list_prim_u_8_strict(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    if (sse_decode_bool(deserializer)) {
      return (sse_decode_list_prim_u_8_strict(deserializer));
    } else {
      return null;
    }
  }

  @protected
  ServerState sse_decode_server_state(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_i_32(deserializer);
    return ServerState.values[inner];
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
  void sse_encode_DartFn_Inputs_list_mission_item_Output_String(
      FutureOr<String> Function(List<MissionItem>) self,
      SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_DartOpaque(
        encode_DartFn_Inputs_list_mission_item_Output_String(self), serializer);
  }

  @protected
  void sse_encode_DartFn_Inputs_list_node_Output_String(
      FutureOr<String> Function(List<Node>) self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_DartOpaque(
        encode_DartFn_Inputs_list_node_Output_String(self), serializer);
  }

  @protected
  void sse_encode_DartOpaque(Object self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        PlatformPointerUtil.ptrToInt(encodeDartOpaque(
            self, portManager.dartHandlerPort, generalizedFrbRustBinding)),
        serializer);
  }

  @protected
  void sse_encode_StreamSink_log_entry_Sse(
      RustStreamSink<LogEntry> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(
        self.setupAndSerialize(
            codec: SseCodec(
                decodeSuccessData: sse_decode_log_entry,
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
  void sse_encode_file_info(FileInfo self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_String(self.fileName, serializer);
    sse_encode_i_64(self.size, serializer);
    sse_encode_String(self.fileType, serializer);
    sse_encode_opt_String(self.sha256, serializer);
    sse_encode_opt_list_prim_u_8_strict(self.preview, serializer);
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
  void sse_encode_list_file_info(
      List<FileInfo> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_file_info(item, serializer);
    }
  }

  @protected
  void sse_encode_list_mission_item(
      List<MissionItem> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_mission_item(item, serializer);
    }
  }

  @protected
  void sse_encode_list_node(List<Node> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_node(item, serializer);
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
  void sse_encode_mission_item(MissionItem self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.id, serializer);
    sse_encode_mission_state(self.state, serializer);
    sse_encode_list_file_info(self.fileInfo, serializer);
  }

  @protected
  void sse_encode_mission_state(MissionState self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.index, serializer);
  }

  @protected
  void sse_encode_node(Node self, SseSerializer serializer) {
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
  void sse_encode_opt_String(String? self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    sse_encode_bool(self != null, serializer);
    if (self != null) {
      sse_encode_String(self, serializer);
    }
  }

  @protected
  void sse_encode_opt_list_prim_u_8_strict(
      Uint8List? self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    sse_encode_bool(self != null, serializer);
    if (self != null) {
      sse_encode_list_prim_u_8_strict(self, serializer);
    }
  }

  @protected
  void sse_encode_server_state(ServerState self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.index, serializer);
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
