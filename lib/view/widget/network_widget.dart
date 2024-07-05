import 'dart:io';

import 'package:flutter/material.dart';

class NetworkWidget extends StatefulWidget {
  final void Function(String addr) onPressed;

  const NetworkWidget({super.key, required this.onPressed});

  @override
  State<NetworkWidget> createState() => _NetworkWidgetState();
}

class _NetworkWidgetState extends State<NetworkWidget> {
  List<String> addressList = [];

  Future<void> getInterface() async {
    List<String> addressList = [];
    List<NetworkInterface> interfaces = await NetworkInterface.list();
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.isLinkLocal ||
            addr.isLoopback ||
            addr.isMulticast ||
            addr.type != InternetAddressType.IPv4) {
          continue;
        }
        addressList.add(addr.address);
      }
    }
    addressList.sort();
    setState(() {
      this.addressList = addressList;
    });
  }

  @override
  void initState() {
    getInterface();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          TextButton.icon(
            onPressed: getInterface,
            label: const Text("refresh"),
            icon: const Icon(Icons.refresh),
          ),
          for (final addr in addressList)
            TextButton(
                child: Text(addr),
                onPressed: () {
                  widget.onPressed(addr);
                })
        ],
      ),
    );
  }
}
