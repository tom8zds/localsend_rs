import 'package:flutter/material.dart';
import 'package:localsend_rs/common/utils.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/pages/home_page.dart';
import 'package:localsend_rs/pages/setting_page.dart';

import '../common/widgets.dart';

enum FrameType {
  compact,
  normal,
  wide,
  expanded,
}

class FramePage extends StatefulWidget {
  const FramePage({super.key});

  @override
  State<FramePage> createState() => _FramePageState();
}

class _FramePageState extends State<FramePage> {
  int index = 0;

  List<Widget> pages = [
    const HomePage(),
    const SettingPage(),
  ];

  FrameType getFrameType(double width) {
    if (width < 640) {
      return FrameType.compact;
    } else if (width < 960) {
      return FrameType.normal;
    } else if (width < 1280) {
      return FrameType.wide;
    } else {
      return FrameType.expanded;
    }
  }

  @override
  void initState() {
    updateSystemOverlayStyle(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final frameType = getFrameType(width);
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

  Widget getView(FrameType frameType) {
    switch (frameType) {
      case FrameType.compact:
        return IndexedStack(
          index: index,
          children: pages,
        );
      case FrameType.normal:
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              NavigationRail(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerLow,
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
              ),
            ],
          ),
        );
      case FrameType.wide:
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              NavigationDrawer(
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
              ),
            ],
          ),
        );
      case FrameType.expanded:
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Row(
            children: [
              NavigationDrawer(
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: IndexedStack(
                            index: index,
                            children: pages,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: Center(
                              child: Text("support page"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
