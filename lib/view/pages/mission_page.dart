import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/common/utils.dart';

import 'package:localsend_rs/core/rust/session/model.dart';

import '../../core/providers/session_provider.dart';
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
  final SessionVm session;
  final bool isParalle;

  const TransferPage(
      {super.key, required this.session, required this.isParalle});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final ButtonStyle style = ElevatedButton.styleFrom(
    padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
  );

  bool showAdvaned = false;

  List<Widget> advanceMessage(SessionVm session) {
    int totalNum = session.tasks.length;
    BigInt totalSize = BigInt.from(0);
    int finishedNum = 0;
    BigInt finishedSize = BigInt.from(0);
    for (var task in session.tasks) {
      totalSize += task.size;
      if (task.status == const Status_Finish()) {
        finishedNum += 1;
        finishedSize += task.size;
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
                  itemCount: widget.session.tasks.length,
                  itemBuilder: (context, index) {
                    final task = widget.session.tasks.elementAt(index);
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
                                  Text("${task.name} (${filesize(task.size)})"),
                                  Text(
                                    task.status.getName(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                  if (task.status == const Status_Finish())
                                    TaskProgress(
                                      id: task.id,
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
                        widget.session.status.getName(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      if (widget.session.status == const Status_Finish())
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
                          children: advanceMessage(widget.session),
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
                          label: Text(context.t.session.advance),
                          icon: const Icon(Icons.info),
                        ),
                        if (widget.session.status == const Status_Finish())
                          FilledButton.icon(
                            onPressed: () {
                              clearMission();
                            },
                            label: Text(context.t.session.complete),
                            icon: const Icon(Icons.info),
                          )
                        else
                          TextButton.icon(
                            onPressed: () {
                              clearMission();
                            },
                            label: Text(context.t.session.cancel),
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
  final SessionVm session;
  final bool isParalle;

  PendingPage({super.key, required this.session, required this.isParalle});

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
            child: DeviceWidgetLarge(device: session.node),
          )),
          SizedBox(
            height: kToolbarHeight,
            child: session.status == const Status_Cancel()
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
          session.status != const Status_Pending()
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
                        cancelPending();
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
                        acceptPending();
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

class MissionPendingPage extends StatelessWidget {
  final bool isParalle;

  const MissionPendingPage({super.key, this.isParalle = false});

  @override
  Widget build(BuildContext context) {
    final session = SessionState.instance();
    return ListenableBuilder(
        listenable: session,
        builder: (context, child) {
          final data = session.session;
          if (data != null) {
            switch (data.status) {
              case Status_Pending():
              case Status_Cancel():
                return PendingPage(session: data, isParalle: isParalle);
              case Status_Transfer():
              case Status_Fail():
              case Status_Finish():
                return TransferPage(session: data, isParalle: isParalle);
              default:
                return const IdlePage();
            }
          }
          return const IdlePage();
        });
  }
}
