import 'package:flutter/material.dart';

import '../rust/bridge/bridge.dart';
import '../rust/discovery/model.dart';

class NodeWidget extends StatefulWidget {
  const NodeWidget({super.key});

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  Stream<List<Node>> nodeStream = nodeChannel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      height: 100,
      child: StreamBuilder(
        stream: nodeStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data;
            if (data != null) {
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
            }
          }
          return const Center(
            child: Text("empty"),
          );
        },
      ),
    );
  }
}
