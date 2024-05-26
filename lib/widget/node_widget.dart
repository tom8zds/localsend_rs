import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_provider.dart';
import '../rust/bridge/bridge.dart';
import '../rust/discovery/model.dart';

class NodeWidget extends ConsumerWidget {
  const NodeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      height: 100,
      child: Builder(
        builder: (context) {
          if (core.nodes.isEmpty) {
            return const Center(
              child: Text("empty"),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = core.nodes.elementAt(index);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  height: 80,
                  width: 80,
                  child: Center(
                      child: Text(
                    item.alias,
                    textAlign: TextAlign.center,
                  )),
                ),
              );
            },
            itemCount: core.nodes.length,
          );
        },
      ),
    );
  }
}
