import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';

part 'core_provider.g.dart';

/// Whether the embedded HTTP server is running.
@Riverpod(keepAlive: true)
Stream<bool> serverState(Ref ref) => listenServerState();

/// Devices discovered on the local network.
@Riverpod(keepAlive: true)
Stream<List<NodeDevice>> devices(Ref ref) => listenDevice();

/// Last server startup error, if any (null once the server binds).
@Riverpod(keepAlive: true)
Stream<String?> serverError(Ref ref) => listenServerError();
