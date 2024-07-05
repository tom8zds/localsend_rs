import 'package:flutter/material.dart';
import 'package:localsend_rs/core/rust/actor/model.dart';

import 'common_widget.dart';

class DeviceWidgetLarge extends StatelessWidget {
  final NodeDevice device;

  const DeviceWidgetLarge({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smartphone,
            size: 64,
          ),
          SizedBox(
            height: 16,
          ),
          Text(
            device.alias,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tag(title: device.address),
              Tag(title: device.deviceModel),
            ],
          ),
          SizedBox(
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

  const DeviceWidget({super.key, required this.device});

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
            const SizedBox(
              height: 80,
              width: 80,
              child: Icon(
                Icons.smartphone,
                size: 48,
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
