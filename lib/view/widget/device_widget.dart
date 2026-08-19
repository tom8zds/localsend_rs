import 'package:flutter/material.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';
import 'package:simple_icons/simple_icons.dart';

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
            height: 16,
          ),
          Text(
            device.alias,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(
            height: 16,
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

  const DeviceWidget({
    super.key,
    required this.device,
    this.onTap,
    this.selected = false,
    this.onRemove,
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
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.smartphone,
                          size: 48,
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
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          Tag(title: device.address),
                          Tag(title: device.deviceModel),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
