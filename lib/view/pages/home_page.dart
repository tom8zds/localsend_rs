import 'package:flutter/material.dart';

import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import '../widget/discover_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool refreshing = false;

  Future<void> refresh() async {
    setState(() {
      refreshing = true;
    });
    await announce();
    await Future.delayed(const Duration(seconds: 4));
    setState(() {
      refreshing = false;
    });
  }

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
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    const Text(
                      "附近的设备",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    IconButton(
                        style: const ButtonStyle(
                          iconSize: WidgetStatePropertyAll(20),
                          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                          minimumSize: WidgetStatePropertyAll(Size(16, 16)),
                          maximumSize: WidgetStatePropertyAll(Size(36, 36)),
                        ),
                        onPressed: () {
                          refresh();
                        },
                        icon: const Icon(
                          Icons.sync,
                        ))
                  ],
                ),
              ),
              if (refreshing)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              const Expanded(child: DiscoverWidget()),
            ],
          ),
        ),
      ),
    );
  }
}
