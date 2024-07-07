import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/core/rust/actor/mission.dart';

import '../../common/widgets.dart';
import '../../core/providers/mission_provider.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../widget/device_widget.dart';

class IdlePage extends StatelessWidget {
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

class TransferPage extends StatelessWidget {
  final MissionInfo mission;
  final bool isParalle;

  TransferPage({super.key, required this.mission, required this.isParalle});

  final ButtonStyle style = ElevatedButton.styleFrom(
    padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isParalle ? Colors.transparent : null,
      body: Column(
        children: [
          for (final file in mission.files)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                height: 96,
                child: Row(
                  children: [
                    Icon(Icons.file_present),
                    SizedBox(
                      width: 8,
                    ),
                    Column(
                      children: [
                        Text(file.info.fileName),
                        Text(file.state.toString()),
                        LinearProgressIndicator(value: 0.3),
                      ],
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(
            height: 32,
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
          Container(
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
          return IdlePage();
      }
    }
    return IdlePage();
  }
}
