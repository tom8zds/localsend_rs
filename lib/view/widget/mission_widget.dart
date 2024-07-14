import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/core/rust/bridge.dart';

class TaskProgress extends StatelessWidget {
  final progressStream = listenTaskProgress();
  final int total;

  TaskProgress({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: progressStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("${snapshot.data} / ${total}");
            return LinearProgressIndicator(
              value: (snapshot.data?.toDouble() ?? 0) / total,
            );
          }
          return Container();
        });
  }
}

class MissionWidget extends ConsumerWidget {
  const MissionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      height: 144,
      child: Builder(
        builder: (context) {
          // final data = core.currentMission;
          // if (data != null) {
          //   if (data.state != MissionState.accepting) {
          //     return const Center(
          //       child: Text("empty"),
          //     );
          //   }
          //   return Column(
          //     children: [
          //       Row(
          //         children: [
          //           const SizedBox(
          //             width: 20,
          //           ),
          //           Text("Mission: ${data.state.toString()}"),
          //           IconButton(
          //             onPressed: () async {
          //               // await acceptMission(missionId: data.id, accept: true);
          //             },
          //             icon: const Icon(Icons.check),
          //           ),
          //           IconButton(
          //             onPressed: () async {
          //               // await acceptMission(missionId: data.id, accept: false);
          //             },
          //             icon: const Icon(Icons.close),
          //           ),
          //           const Expanded(child: SizedBox()),
          //           IconButton(
          //               onPressed: () async {
          //                 // await clearMissions();
          //               },
          //               icon: const Icon(Icons.delete))
          //         ],
          //       ),
          //       SizedBox(
          //         height: 100,
          //         child: ListView.builder(
          //           scrollDirection: Axis.horizontal,
          //           itemBuilder: (context, index) {
          //             final item = data.fileInfo.elementAt(index);
          //             return Padding(
          //               padding: const EdgeInsets.all(8.0),
          //               child: Container(
          //                 decoration: BoxDecoration(
          //                   borderRadius: BorderRadius.circular(12),
          //                   color: Theme.of(context).colorScheme.secondary,
          //                 ),
          //                 height: 80,
          //                 width: 80,
          //                 child: Center(
          //                     child: Text(
          //                   item.fileName,
          //                   textAlign: TextAlign.center,
          //                 )),
          //               ),
          //             );
          //           },
          //           itemCount: data.fileInfo.length,
          //         ),
          //       ),
          //     ],
          //   );
          // }
          return const Center(
            child: Text("empty"),
          );
        },
      ),
    );
  }
}
