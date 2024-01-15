import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_rs/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';

import 'src/rust/bridge/bridge.dart';
import 'src/rust/discovery/model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  String storePath;
  if (Platform.isAndroid) {
    storePath = "/storage/emulated/0/Download";
  } else {
    storePath = (await getDownloadsDirectory())!.absolute.path;
  }
  // initServer(
  //   device: DeviceConfig(
  //     alias: "test",
  //     fingerprint: "fingerprint",
  //     deviceModel: "rust",
  //     deviceType: "mobile",
  //     storePath: storePath,
  //   ),
  // );
  await rustSetUp(isDebug: kDebugMode);
  await setup();
  // createLogStream().listen((event) {
  //   print(
  //       'rust log [${event.level}] - ${event.tag} ${event.msg}(rust_time=${event.timeMillis})');
  // });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                start(
                    // config: const ServerConfig(
                    //   multicastAddr: "224.0.0.167",
                    //   port: 53317,
                    //   protocol: "http",
                    //   download: false,
                    //   announcement: true,
                    //   announce: true,
                    // ),
                    );
              },
              child: const Text("start server"),
            ),
            FutureBuilder(
              future: getDownloadsDirectory(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text("external storage: ${snapshot.data}");
                } else {
                  return const Text("external storage: unknown");
                }
              },
            ),
            ElevatedButton(
              onPressed: () async {
                await stop();
              },
              child: const Text("stop server"),
            ),
            ElevatedButton(
              onPressed: () async {
                await discover();
              },
              child: const Text("discover"),
            ),
            MissionList(),
            Expanded(child: NodeList()),
          ],
        ),
      ),
    );
  }
}

class NodeCard extends StatelessWidget {
  const NodeCard({required this.node, super.key});

  final Node node;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 100,
      child: Card(
        child: Row(
          children: [
            Icon(Icons.phone_android),
            Column(
              children: [
                Text(node.alias),
                Text(node.address),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MissionWidget extends StatelessWidget {
  const MissionWidget({required this.mission, super.key});

  final MissionItem mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 100,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text("missions"),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () {
                        acceptMission(missionId: mission.id, accept: true);
                      },
                      child: Text("接收"),
                    ),
                    SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {
                        acceptMission(missionId: mission.id, accept: false);
                      },
                      child: Text("拒绝"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MissionList extends StatefulWidget {
  const MissionList({super.key});

  @override
  State<MissionList> createState() => _MissionListState();
}

class _MissionListState extends State<MissionList> {
  late Stream<MissionItem> _missionStream;

  @override
  void initState() {
    super.initState();
    _missionStream = missionChannel();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _missionStream,
        builder: (context, snapShot) {
          if (snapShot.hasData) {
            final mission = snapShot.data as MissionItem;
            return MissionWidget(mission: mission);
          }
          return Container();
        });
  }
}

class NodeList extends StatefulWidget {
  const NodeList({super.key});

  @override
  State<NodeList> createState() => _NodeListState();
}

class _NodeListState extends State<NodeList> {
  late Stream<List<Node>> _nodeStream;

  @override
  void initState() {
    super.initState();
    _nodeStream = nodeChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [Text("nodes")],
        ),
        StreamBuilder(
            stream: _nodeStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final nodes = snapshot.data as List<Node>;
                return Expanded(
                  child: ListView.builder(
                    itemCount: nodes.length,
                    itemBuilder: (context, index) {
                      final node = nodes[index];
                      return Card(
                        child: ListTile(
                          title: Text(node.alias),
                          subtitle: Text(node.address),
                        ),
                      );
                    },
                  ),
                );
              }
              return Container();
            }),
      ],
    );
  }
}
