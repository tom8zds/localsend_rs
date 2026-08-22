import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../common/spacing.dart';
import 'common_widget.dart';

class DeviceWidgetLarge extends StatelessWidget {
  final NodeDevice device;

  const DeviceWidgetLarge({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.smartphone,
            size: 64,
          ),
          const SizedBox(
            height: AppSpacing.x16,
          ),
          Text(
            device.alias,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(
            height: AppSpacing.x16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tag(title: device.address),
              Tag(title: device.deviceModel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Discovered (or manually added) device row. Taps are handled by the
/// caller: quick-send when files are staged, target toggling on the
/// send page. [selected] shows a check indicator; [onRemove] adds a
/// trailing remove button (manual targets).
class DeviceWidget extends StatelessWidget {
  final NodeDevice device;
  final VoidCallback? onTap;
  final bool selected;
  final VoidCallback? onRemove;

  /// Latest connection path for this peer ("local" | "turn" | "stun"),
  /// from its most recent session; null when never transferred to.
  final String? route;

  const DeviceWidget({
    super.key,
    required this.device,
    this.onTap,
    this.selected = false,
    this.onRemove,
    this.route,
  });

  Widget getDeviceBadge(BuildContext context) {
    IconData? icon;
    if (SimpleIcons.values.containsKey(device.deviceModel.toLowerCase())) {
      icon = SimpleIcons.values[device.deviceModel.toLowerCase()];
    } else if (SimpleIcons.values
        .containsKey(device.deviceType.toLowerCase())) {
      icon = SimpleIcons.values[device.deviceType.toLowerCase()];
    }

    return icon == null
        ? const SizedBox()
        : Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.x8),
              padding: const EdgeInsets.all(AppSpacing.x4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.x12),
              ),
              child: Icon(
                icon,
                // Tonal pairing: on-primary-container on
                // primary-container.
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 18,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x8),
      child: Material(
        // M3 card corner: medium (12dp).
        borderRadius: BorderRadius.circular(AppSpacing.x12),
        // M3 selection: secondary-container marks the selected item;
        // the resting row is a high surface container, not an accent.
        color: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.x12),
          onTap: onTap,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                SizedBox(
                  height: 56,
                  width: 56,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          // v2.2 deviceType: mobile | desktop | web |
                          // headless (official enum) — anything else
                          // falls back to the generic devices icon.
                          switch (device.deviceType.toLowerCase()) {
                            'mobile' => Icons.smartphone,
                            'desktop' => Icons.desktop_windows,
                            'web' => Icons.public,
                            'headless' => Icons.terminal,
                            _ => Icons.devices,
                          },
                          size: 40,
                        ),
                      ),
                      getDeviceBadge(context),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.alias,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(
                        height: AppSpacing.x4,
                      ),
                      Row(
                        children: [
                          Tag(title: device.address),
                          Tag(title: device.deviceModel),
                          if (route case final r?) RouteTag(route: r),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.x8),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                const SizedBox(width: AppSpacing.x8,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Path label chip on a device row: local / turn / (future) stun.
class RouteTag extends StatelessWidget {
  final String route;

  const RouteTag({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (route) {
      'turn' => (Icons.alt_route, context.t.transfers.routeTurn),
      'stun' => (Icons.hub, context.t.transfers.routeStun),
      _ => (Icons.lan, context.t.transfers.routeLocal),
    };
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.x8),
        color: scheme.tertiaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onTertiaryContainer),
          const SizedBox(width: AppSpacing.x4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}
