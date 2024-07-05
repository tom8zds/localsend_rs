import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_provider.dart';

class NodeWidget extends ConsumerWidget {
  const NodeWidget({super.key});

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
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  height: 80,
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 80,
                        width: 80,
                        child: Icon(
                          Icons.smartphone,
                          size: 48,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.alias,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                            ),
                            child: Text(
                              item.address,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: data.length,
          );
        },
      ),
    );
  }
}
