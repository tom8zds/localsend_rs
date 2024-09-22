import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/common/utils.dart';
import 'package:localsend_rs/core/rust/actor/mission.dart';

import '../../core/providers/mission_provider.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import '../widget/device_widget.dart';
import '../widget/mission_widget.dart';

class IdlePage extends StatelessWidget {
  const IdlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: Image.asset("assets/icon/logo_512.png"),
        ),
        const AppTitle(),
      ],
    );
  }
}

class TransferPage extends StatefulWidget {
  final MissionInfo mission;
  final bool isParalle;

  const TransferPage(
      {super.key, required this.mission, required this.isParalle});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final ButtonStyle style = ElevatedButton.styleFrom(
    padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
  );

  bool showAdvaned = false;

  List<Widget> advanceMessage(MissionInfo mission) {
    int totalNum = mission.files.length;
    int totalSize = 0;
    int finishedNum = 0;
    int finishedSize = 0;
    for (var file in mission.files) {
      totalSize += file.info.size;
      if (file.state == const FileState.finish()) {
        finishedNum += 1;
        finishedSize += file.info.size;
      }
    }
    return [
      Text("${t.common.file}: $finishedNum / $totalNum"),
      Text(
          "${t.common.size}: ${filesize(finishedSize)} / ${filesize(totalSize)}")
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isParalle ? Colors.transparent : null,
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  itemCount: widget.mission.files.length,
                  itemBuilder: (context, index) {
                    final file = widget.mission.files.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: SizedBox(
                        height: 72,
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 8,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              height: 48,
                              width: 48,
                              child: Icon(
                                Icons.file_present,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 36,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      "${file.info.fileName} (${filesize(file.info.size)})"),
                                  Text(
                                    file.state.getName(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                  if (file.state == const FileState.transfer())
                                    TaskProgress(
                                      total: file.info.size,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
          AnimatedContainer(
            curve: Curves.ease,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Durations.medium1,
            height: showAdvaned ? 144 : 96,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mission.state.getName(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      if (widget.mission.state == MissionState.finished)
                        LinearProgressIndicator(
                          value: 1,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(12),
                        )
                      else
                        LinearProgressIndicator(
                          value: 0.3,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      const SizedBox(
                        height: 8,
                      ),
                      SizedBox(
                        height: 48,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: advanceMessage(widget.mission),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              showAdvaned = !showAdvaned;
                            });
                          },
                          label: Text(context.t.mission.advance),
                          icon: const Icon(Icons.info),
                        ),
                        if (widget.mission.state == MissionState.finished)
                          FilledButton.icon(
                            onPressed: () {
                              clearMission();
                            },
                            label: Text(context.t.mission.complete),
                            icon: const Icon(Icons.info),
                          )
                        else
                          TextButton.icon(
                            onPressed: () {
                              clearMission();
                            },
                            label: Text(context.t.mission.cancel),
                            icon: const Icon(Icons.cancel),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          )
        ],
      ),
    );
  }
}

class PendingPage extends StatelessWidget {
  final MissionInfo mission;
  final bool isParalle;

  PendingPage({super.key, required this.mission, required this.isParalle});

  final ButtonStyle style = ElevatedButton.styleFrom(
    padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isParalle ? Colors.transparent : null,
      body: Column(
        children: [
          Expanded(
              child: Center(
            child: DeviceWidgetLarge(device: mission.sender),
          )),
          SizedBox(
            height: kToolbarHeight,
            child: mission.state == MissionState.canceled
                ? Center(
                    child: Text(
                      "请求已取消。",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  )
                : null,
          ),
          mission.state != MissionState.pending
              ? ElevatedButton.icon(
                  onPressed: () {
                    clearMission();
                  },
                  style: style,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Close"),
                )
              : OverflowBar(
                  spacing: 16.0,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        cancelPending(id: mission.id);
                        if (!isParalle) {
                          clearMission();
                        }
                      },
                      style: style.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.tertiaryContainer,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        acceptPending(id: mission.id);
                      },
                      style: style.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.secondaryContainer,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Accept"),
                    ),
                  ],
                ),
          const SizedBox(
            height: 32,
          )
        ],
      ),
    );
  }
}

class MissionPendingPage extends ConsumerWidget {
  final bool isParalle;

  const MissionPendingPage({super.key, this.isParalle = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(coreMissionProvider);
    if (data != null) {
      switch (data.state) {
        case MissionState.pending:
        case MissionState.canceled:
          return PendingPage(mission: data, isParalle: isParalle);
        case MissionState.transfering:
        case MissionState.failed:
        case MissionState.finished:
          return TransferPage(mission: data, isParalle: isParalle);
        default:
          return const IdlePage();
      }
    }
    return const IdlePage();
  }
}
