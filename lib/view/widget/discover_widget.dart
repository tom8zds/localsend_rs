import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/view/widget/device_widget.dart';

import '../../common/spacing.dart';
import '../../core/providers/core_provider.dart';
import '../../core/providers/session_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/actor/model.dart';

/// Live list of discovered devices. [onDeviceTap] is forwarded to each
/// [DeviceWidget] (e.g. quick-send when files are staged).
class DiscoverWidget extends ConsumerWidget {
  final ValueChanged<NodeDevice>? onDeviceTap;

  const DiscoverWidget({super.key, this.onDeviceTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    // Keep the last non-empty snapshot: stream transitions between
    // states every few seconds (announce/register cycles), and
    // flashing an empty placeholder between them reads as flicker.
    final list = devices.value ?? const <NodeDevice>[];
    // Latest connection path per peer (from its most recent session).
    final latestRoute = <String, String>{
      for (final s in ref.watch(sessionIndexProvider).value ?? const <SessionSummary>[])
        if (s.viaRelay || s.route.isNotEmpty) s.peer.fingerprint: s.route,
    };
    return Container(
      decoration: BoxDecoration(
        // Low surface container one step above the page background.
        borderRadius: BorderRadius.circular(AppSpacing.x12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: list.isNotEmpty
          ? ListView.builder(
              // Keyed items let Flutter reuse element trees when the
              // stream replays the (identical) list.
              itemBuilder: (context, index) {
                final item = list.elementAt(index);
                return DeviceWidget(
                  key: ValueKey(item.fingerprint),
                  device: item,
                  route: latestRoute[item.fingerprint],
                  onTap:
                      onDeviceTap == null ? null : () => onDeviceTap!(item),
                );
              },
              itemCount: list.length,
            )
          : switch (devices) {
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => const Center(child: Text("empty")),
            },
    );
  }
}
