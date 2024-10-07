import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:localsend_rs/view/widget/device_widget.dart';

import '../../core/providers/core_provider.dart';

class DiscoverWidget extends ConsumerWidget {
  const DiscoverWidget({super.key, this.onDeviceTapped});

  final Function(NodeDevice)? onDeviceTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreStateProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Builder(
        builder: (context) {
          final data = core.devices;
          if (data.isEmpty) {
            return const Center(
              child: Text("empty"),
            );
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              final item = data.elementAt(index);
              return DeviceWidget(device: item, onTap: onDeviceTapped);
            },
            itemCount: data.length,
          );
        },
      ),
    );
  }
}
