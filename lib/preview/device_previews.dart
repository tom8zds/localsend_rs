import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../view/widget/device_widget.dart';
import 'preview_scaffold.dart';

@Preview(name: 'Device card')
Widget deviceCardPreview() => previewShell(
      height: 120,
      child: DeviceWidget(device: mockDevice()),
    );

@Preview(name: 'Device card (selected)')
Widget deviceCardSelectedPreview() => previewShell(
      height: 120,
      child: DeviceWidget(device: mockDevice(), selected: true),
    );

@Preview(name: 'Device card (removable manual target)')
Widget deviceCardRemovablePreview() => previewShell(
      height: 120,
      child: DeviceWidget(
        device: mockDevice(alias: '192.168.1.99:53317'),
        selected: true,
        onRemove: () {},
      ),
    );

@Preview(name: 'Device card (large)')
Widget deviceCardLargePreview() => previewShell(
      height: 300,
      child: DeviceWidgetLarge(device: mockDevice()),
    );
