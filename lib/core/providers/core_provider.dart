import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../rust/actor/model.dart';
import '../rust/bridge.dart';

part 'core_provider.g.dart';

/// Whether the embedded HTTP server is running.
@Riverpod(keepAlive: true)
Stream<bool> serverState(Ref ref) => listenServerState();

/// All discovered devices (LAN + relay merged upstream).
@Riverpod(keepAlive: true)
Stream<List<NodeDevice>> devices(Ref ref) => listenDevice();

/// LAN-discovered devices (multicast only).
@Riverpod(keepAlive: true)
Stream<List<NodeDevice>> lanDevices(Ref ref) =>
    devices(ref).map((list) =>
        list.where((d) => d.discoverySource == 'lan').toList());

/// Relay-discovered devices (rendezvous only).
@Riverpod(keepAlive: true)
Stream<List<NodeDevice>> relayDevices(Ref ref) =>
    devices(ref).map((list) =>
        list.where((d) => d.discoverySource == 'relay').toList());

/// Last server startup error, if any (null once the server binds).
@Riverpod(keepAlive: true)
Stream<String?> serverError(Ref ref) => listenServerError();
