import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/view/widget/device_widget.dart';

import '../../common/spacing.dart';
import '../../core/providers/core_provider.dart';
import '../../core/rust/actor/model.dart';

/// Live list of discovered devices. [onDeviceTap] is forwarded to each
/// [DeviceWidget] (e.g. quick-send when files are staged).
class DiscoverWidget extends ConsumerWidget {
  final ValueChanged<NodeDevice>? onDeviceTap;

  const DiscoverWidget({super.key, this.onDeviceTap});

  static int _buildCount = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    // TEMPORARY flicker diagnosis
    _buildCount++;
    debugPrint('DISCOVER-BUILD #$_buildCount state=${devices.runtimeType} hasValue=${devices.hasValue} n=${devices.value?.length}');
    devices.whenData((list) {
      for (final d in list) {
        debugPrint('  device: ${d.alias} ${d.fingerprint.substring(0, 8)}');
      }
    });
    // Keep the last non-empty snapshot: stream transitions between
    // states every few seconds (announce/register cycles), and
    // flashing an empty placeholder between them reads as flicker.
    final list = devices.value ?? const <NodeDevice>[];
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
