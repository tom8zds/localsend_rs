import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/providers/core_provider.dart';
import 'package:localsend_rs/rust/actor/model.dart';
import 'package:localsend_rs/rust/bridge.dart';

class NodeWidget extends ConsumerWidget {
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
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: Icon(
                          Icons.smartphone,
                          size: 48,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.alias),
                          SizedBox(
                            height: 4,
                          ),
                          Chip(
                            label: Text(item.address),
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
