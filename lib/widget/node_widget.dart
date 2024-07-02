import 'package:flutter/material.dart';
import 'package:localsend_rs/rust/actor/model.dart';
import 'package:localsend_rs/rust/bridge/bridge.dart';

class NodeWidget extends StatefulWidget {
  NodeWidget({super.key});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  late Stream<List<NodeDevice>> deviceStream;

  @override
  void initState() {
    super.initState();
    deviceStream = listenDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      height: 100,
      child: StreamBuilder<List<NodeDevice>>(
        stream: deviceStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: Text("empty"),
            );
          }
          final data = snap.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = data.elementAt(index);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  height: 80,
                  width: 80,
                  child: Center(
                      child: Text(
                    item.alias,
                    textAlign: TextAlign.center,
                  )),
                ),
              );
            },
            itemCount: data.length,
          );
        },
      ),
    );
  }
}
