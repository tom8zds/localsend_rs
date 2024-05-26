import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_provider.dart';
import '../rust/bridge/bridge.dart';
import '../rust/api/model.dart';

class MissionWidget extends ConsumerWidget {
  const MissionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      height: 144,
      child: Builder(
        builder: (context) {
          if (core.missions.isNotEmpty) {
            final data = core.missions.last;
            if (data.state != MissionState.accepting) {
              return const Center(
                child: Text("empty"),
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Text("Mission: ${data.state.toString()}"),
                    IconButton(
                      onPressed: () async {
                        await acceptMission(missionId: data.id, accept: true);
                      },
                      icon: const Icon(Icons.check),
                    ),
                    IconButton(
                      onPressed: () async {
                        await acceptMission(missionId: data.id, accept: false);
                      },
                      icon: const Icon(Icons.close),
                    ),
                    const Expanded(child: SizedBox()),
                    IconButton(
                        onPressed: () async {
                          await clearMissions();
                        },
                        icon: const Icon(Icons.delete))
                  ],
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = data.fileInfo.elementAt(index);
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
                            item.fileName,
                            textAlign: TextAlign.center,
                          )),
                        ),
                      );
                    },
                    itemCount: data.fileInfo.length,
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: Text("empty"),
          );
        },
      ),
    );
  }
}
