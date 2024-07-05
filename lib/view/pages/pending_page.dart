import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/providers/mission_provider.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../widget/device_widget.dart';

class MissionPendingPage extends ConsumerWidget {
  final bool isParalle;

  final ButtonStyle style = ElevatedButton.styleFrom(
    padding: EdgeInsets.fromLTRB(16, 16, 24, 16),
  );

  MissionPendingPage({super.key, this.isParalle = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(pendingMissionProvider);
    if (data.mission != null) {
      final mission = data.mission!;
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
              child: data.state == MissionState.canceled
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
            data.state != MissionState.pending
                ? ElevatedButton.icon(
                    onPressed: () {
                      clearPending();
                    },
                    style: style,
                    icon: Icon(Icons.check_circle),
                    label: Text("Close"),
                  )
                : OverflowBar(
                    spacing: 16.0,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          cancelPending(id: mission.id);
                          if (!isParalle) {
                            clearPending();
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
                        icon: Icon(Icons.cancel),
                        label: Text("Cancel"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        style: style.copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        icon: Icon(Icons.check_circle),
                        label: Text("Accept"),
                      ),
                    ],
                  ),
            SizedBox(
              height: 32,
            )
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: Image.asset("assets/icon/logo_512.png"),
        ),
        AppTitle(),
      ],
    );
  }
}
