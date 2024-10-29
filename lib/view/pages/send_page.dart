import 'package:flutter/material.dart';
import 'package:localsend_rs/common/utils.dart';

import '../../core/rust/actor/model.dart';
import '../widget/device_widget.dart';

class SendPage extends StatelessWidget {
  final NodeDevice target;

  const SendPage({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              SizedBox(
                height: 16,
              ),
              DeviceWidget(
                device: DeviceHolder.device,
              ),
              SizedBox(
                height: 8,
              ),
              Icon(Icons.arrow_downward),
              SizedBox(
                height: 8,
              ),
              Hero(
                tag: target.fingerprint,
                child: DeviceWidget(
                  device: target,
                ),
              ),
              Expanded(child: SizedBox()),
              Text(
                "Waiting for confirmation...",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              SizedBox(
                height: 16,
              ),
              FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.cancel),
                  label: const Text("Cancel")),
              SizedBox(
                height: 32,
              )
            ],
          ),
        ),
      ),
    );
  }
}
