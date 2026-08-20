import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/spacing.dart';
import '../../common/utils.dart';
import '../../core/providers/session_providers.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import 'setting_page.dart';
import 'transfers_page.dart';

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
  int lastIndex = 0;

  FrameType getFrameType(double width) {
    // M3 window size classes: compact <600 (bottom bar), medium 600–839
    // (rail), large 1200+ (drawer).
    if (width < AppBreakpoints.compact) {
      return FrameType.compact;
    } else if (width < AppBreakpoints.large) {
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

  void changeIndex(int value) {
    if (value == index) {
      return;
    }
    setState(() {
      lastIndex = index;
      index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!init) {
      final brightness = Theme.of(context).brightness;
      initOverlay(brightness);
    }
    // Keeps the quick-save auto-accept listener alive.
    ref.watch(autoAcceptProvider);
    // Jump to the transfers tab when someone sends us files (compact
    // layout only; wider layouts surface sessions on the transfers
    // page itself).
    ref.listen(pendingReceiveSessionsProvider, (previous, next) {
      if (next.isNotEmpty &&
          getFrameType(MediaQuery.of(context).size.width) ==
              FrameType.compact) {
        changeIndex(0);
      }
    });

    final pages = [
      const TransfersPage(),
      const SettingPage(),
    ];

    final width = MediaQuery.of(context).size.width;
    final frameType = getFrameType(width);
    final destinations = [
      (
        icon: Icons.swap_vert_outlined,
        selectedIcon: Icons.swap_vert,
        label: context.t.transfers.title,
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: context.t.setting.title,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: getView(frameType, pages, destinations)),
      bottomNavigationBar: frameType == FrameType.compact
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: changeIndex,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ),
              ],
            )
          : null,
    );
  }

  Widget getSideNavigation(
    FrameType frameType,
    List<({IconData icon, IconData selectedIcon, String label})> destinations,
  ) {
    if (frameType == FrameType.wide) {
      return NavigationDrawer(
        onDestinationSelected: changeIndex,
        selectedIndex: index,
        children: [
          const SizedBox(
            height: 112,
            child: Center(
              child: AppTitle(),
            ),
          ),
          for (final d in destinations)
            NavigationDrawerDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
            ),
        ],
      );
    }
    if (frameType == FrameType.normal) {
      return NavigationRail(
        // M3 rail: default surface colors, labels always shown.
        onDestinationSelected: changeIndex,
        labelType: NavigationRailLabelType.all,
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              label: Text(d.label),
            ),
        ],
        selectedIndex: index,
      );
    }
    return Container();
  }

  Widget transition(Widget child) {
    return PageTransitionSwitcher(
      reverse: lastIndex > index,
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
      child: child,
    );
  }

  Widget getView(
    FrameType frameType,
    List<Widget> pages,
    List<({IconData icon, IconData selectedIcon, String label})> destinations,
  ) {
    if (frameType == FrameType.compact) {
      return transition(pages.elementAt(index));
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [
          getSideNavigation(frameType, destinations),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x8),
              child: ClipRRect(
                // M3 large shape token: 16dp.
                borderRadius: BorderRadius.circular(AppSpacing.x16),
                child: transition(pages.elementAt(index)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
