import 'package:flutter/material.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/widget/network_widget.dart';

import '../widget/mission_widget.dart';
import '../widget/node_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              SizedBox(
                height: 8,
              ),
              // MissionWidget(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Text(
                      "附近的设备",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    IconButton(
                        style: ButtonStyle(
                          iconSize: WidgetStatePropertyAll(20),
                          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                          minimumSize: WidgetStatePropertyAll(Size(16, 16)),
                          maximumSize: WidgetStatePropertyAll(Size(36, 36)),
                        ),
                        onPressed: () {},
                        icon: Icon(
                          Icons.sync,
                        ))
                  ],
                ),
              ),
              Expanded(child: NodeWidget()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          // await discover();
        },
      ),
    );
  }
}
