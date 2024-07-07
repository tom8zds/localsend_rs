import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_rs/view/pages/mission_page.dart';

import '../../common/utils.dart';
import '../../common/widgets.dart';
import '../../core/providers/mission_provider.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import 'home_page.dart';
import 'setting_page.dart';

enum FrameType {
  compact,
  normal,
  wide,
}

class FramePage extends ConsumerStatefulWidget {
  const FramePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FramePageState();
}

class _FramePageState extends ConsumerState<FramePage> {
  int index = 0;

  List<Widget> pages = [
    const HomePage(),
    const SettingPage(),
  ];

  FrameType getFrameType(double width) {
    if (width < 960) {
      return FrameType.compact;
    } else if (width < 1440) {
      return FrameType.normal;
    } else {
      return FrameType.wide;
    }
  }

  bool init = false;

  void initOverlay(Brightness brightness) {
    setState(() {
      init = true;
    });
    updateSystemOverlayStyle(brightness);
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      final brightness = Theme.of(context).brightness;
      initOverlay(brightness);
    }
    final data = ref.watch(coreMissionProvider);

    final width = MediaQuery.of(context).size.width;
    final frameType = getFrameType(width);
    if (frameType == FrameType.compact) {
      if (data != null && data.state == MissionState.pending) {
        return const MissionPendingPage(
          isParalle: false,
        );
      }
    }
    return Scaffold(
      body: SafeArea(child: getView(frameType)),
      bottomNavigationBar: frameType == FrameType.compact
          ? BottomNavigationBar(
              currentIndex: index,
              onTap: (index) {
                setState(() {
                  this.index = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: context.t.home.title,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings),
                  label: context.t.setting.title,
                ),
              ],
            )
          : null,
    );
  }

  Widget getSideNavigation(FrameType frameType) {
    if (frameType == FrameType.wide) {
      return NavigationDrawer(
        onDestinationSelected: (index) {
          setState(() {
            this.index = index;
          });
        },
        selectedIndex: index,
        children: [
          const SizedBox(
            height: 112,
            child: Center(
              child: AppTitle(),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: Text(context.t.home.title),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: Text(context.t.setting.title),
          ),
        ],
      );
    }
    if (frameType == FrameType.normal) {
      return NavigationRail(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        labelType: NavigationRailLabelType.selected,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.home),
            label: Text(context.t.home.title),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.settings),
            label: Text(context.t.setting.title),
          ),
        ],
        selectedIndex: index,
      );
    }
    return Container();
  }

  Widget getParalleView(FrameType frameType) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          getSideNavigation(frameType),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IndexedStack(
                        index: index,
                        children: pages,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const MissionPendingPage(
                        isParalle: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getView(FrameType frameType) {
    if (frameType == FrameType.compact) {
      return IndexedStack(
        index: index,
        children: pages,
      );
    }
    return getParalleView(frameType);
  }
}
