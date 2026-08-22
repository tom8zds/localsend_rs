import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../view/widget/device_widget.dart';
import 'preview_scaffold.dart';

@Preview(name: 'Device card')
Widget deviceCardPreview() => previewShell(
      name: 'deviceCard',
      height: 120,
      child: DeviceWidget(device: mockDevice()),
    );

@Preview(name: 'Device card (selected)')
Widget deviceCardSelectedPreview() => previewShell(
      name: 'deviceCardSelected',
      height: 120,
      child: DeviceWidget(device: mockDevice(), selected: true),
    );

@Preview(name: 'Device card (removable manual target)')
Widget deviceCardRemovablePreview() => previewShell(
      name: 'deviceCardRemovable',
      height: 120,
      child: DeviceWidget(
        device: mockDevice(alias: '192.168.1.99:53317'),
        selected: true,
        onRemove: () {},
      ),
    );

@Preview(name: 'Device card (large)')
Widget deviceCardLargePreview() => previewShell(
      name: 'deviceCardLarge',
      height: 300,
      child: DeviceWidgetLarge(device: mockDevice()),
    );

@Preview(name: 'Device card (desktop peer)')
Widget deviceCardDesktopPreview() => previewShell(
      name: 'deviceCardDesktop',
      height: 120,
      child: DeviceWidget(
        device: mockDevice(alias: 'Workstation', type: 'desktop'),
        route: 'local',
      ),
    );

@Preview(name: 'Device card (headless peer, via relay)')
Widget deviceCardHeadlessPreview() => previewShell(
      name: 'deviceCardHeadless',
      height: 120,
      child: DeviceWidget(
        device: mockDevice(alias: 'homeserver', type: 'headless'),
        route: 'turn',
      ),
    );
