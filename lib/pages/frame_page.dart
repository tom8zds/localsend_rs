import 'package:flutter/material.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/pages/home_page.dart';
import 'package:localsend_rs/pages/setting_page.dart';

import '../common/widgets.dart';

enum FrameType {
  compact,
  normal,
  wide,
}

class FramePage extends StatefulWidget {
  const FramePage({super.key});

  @override
  State<FramePage> createState() => _FramePageState();
}

class _FramePageState extends State<FramePage> {
  int index = 0;

  List<Widget> pages = [
    HomePage(),
    const SettingPage(),
  ];

  FrameType getFrameType(double width) {
    if (width < 720) {
      return FrameType.compact;
    } else if (width < 960) {
      return FrameType.normal;
    } else {
      return FrameType.wide;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final frameType = getFrameType(width);
    return Scaffold(
      body: getView(frameType),
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
        return Row(
          children: [
            NavigationRail(
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
              child: Center(
                child: SizedBox(
                  width: 600,
                  child: IndexedStack(
                    index: index,
                    children: pages,
                  ),
                ),
              ),
            ),
          ],
        );
      case FrameType.wide:
        return Row(
          children: [
            NavigationDrawer(
              onDestinationSelected: (index) {
                setState(() {
                  this.index = index;
                });
              },
              selectedIndex: index,
              children: [
                SizedBox(
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
              child: Center(
                child: SizedBox(
                  width: 600,
                  child: IndexedStack(
                    index: index,
                    children: pages,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
