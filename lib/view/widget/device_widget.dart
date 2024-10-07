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
          const SizedBox(
            height: 24,
          ),
          Text(
            "想要发送给你一个文件。",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class DeviceWidget extends StatelessWidget {
  final NodeDevice device;
  final Function(NodeDevice)? onTap;

  const DeviceWidget({super.key, required this.device, this.onTap});

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
            child: InkWell(
              onTap: () {
                onTap?.call(device);
              },
              child: Ink(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
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
            Column(
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
          ],
        ),
      ),
    );
  }
}
