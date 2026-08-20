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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    return Container(
      decoration: BoxDecoration(
        // Low surface container one step above the page background.
        borderRadius: BorderRadius.circular(AppSpacing.x12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: switch (devices) {
        AsyncData(:final value) when value.isNotEmpty => ListView.builder(
            itemBuilder: (context, index) {
              final item = value.elementAt(index);
              return DeviceWidget(
                device: item,
                onTap:
                    onDeviceTap == null ? null : () => onDeviceTap!(item),
              );
            },
            itemCount: value.length,
          ),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const Center(
            child: Text("empty"),
          ),
      },
    );
  }
}
