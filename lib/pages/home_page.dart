import 'package:flutter/material.dart';
import 'package:localsend_rs/i18n/strings.g.dart';
import 'package:localsend_rs/rust/bridge/bridge.dart';

import '../widget/mission_widget.dart';
import '../widget/node_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.home.title),
      ),
      body: ListView(
        children: const [MissionWidget(), NodeWidget()],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          await discover();
        },
      ),
    );
  }
}
