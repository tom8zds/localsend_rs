import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_rs/src/rust/api/simple.dart';
import 'package:localsend_rs/src/rust/core/model.dart';
import 'package:localsend_rs/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  String storePath;
  if (Platform.isAndroid) {
    storePath = "/storage/emulated/0/Download";
  } else {
    storePath = (await getDownloadsDirectory())!.absolute.path;
  }
  initServer(
    device: DeviceConfig(
      alias: "test",
      fingerprint: "fingerprint",
      deviceModel: "rust",
      deviceType: "mobile",
      storePath: storePath,
    ),
  );
  await rustSetUp(isDebug: kDebugMode);
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
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const ServerStatusWidget(),
                  ElevatedButton(
                    onPressed: () {
                      startServer(
                        config: const ServerConfig(
                          multicastAddr: "224.0.0.167",
                          port: 53317,
                          protocol: "http",
                          download: false,
                          announcement: true,
                          announce: true,
                        ),
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
                      await stopServer();
                    },
                    child: const Text("stop server"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await discover();
                    },
                    child: const Text("discover"),
                  ),
                  Container(
                    child: Row(
                      children: [
                        const Text("send request"),
                        ElevatedButton(
                            onPressed: () async {
                              if (await Permission.manageExternalStorage
                                  .request()
                                  .isGranted) {
                                accept(isAccept: true);
                              }
                            },
                            child: Text("accept")),
                        ElevatedButton(
                            onPressed: () {
                              accept(isAccept: false);
                            },
                            child: Text("reject")),
                      ],
                    ),
                  ),
                  const ProgressWidget(),
                ],
              ),
            ),
            SliverFillRemaining(
              child: const DiscoverWidget(),
            )
          ],
        ),
      ),
    );
  }
}

class ServerStatusWidget extends StatefulWidget {
  const ServerStatusWidget({super.key});

  @override
  State<ServerStatusWidget> createState() => _ServerStatusWidgetState();
}

class _ServerStatusWidgetState extends State<ServerStatusWidget> {
  late Stream<ServerStatus> statusStream;

  @override
  void initState() {
    super.initState();
    statusStream = serverStatus();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: statusStream,
      builder: (context, snapshot) {
        print("snap shot income");
        if (snapshot.hasData) {
          return Text("server status: ${snapshot.data}");
        } else {
          return const Text("server status: unknown");
        }
      },
    );
  }
}

class DiscoverWidget extends StatefulWidget {
  const DiscoverWidget({super.key});

  @override
  State<DiscoverWidget> createState() => _DiscoverWidgetState();
}

class _DiscoverWidgetState extends State<DiscoverWidget> {
  late Stream<DiscoverState> discoverStream;

  @override
  void initState() {
    super.initState();
    discoverStream = listenDiscover();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: discoverStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("discover state income");
            var state = snapshot.data;
            return state?.when(
                  discovering: (devices) {
                    return ListView(
                      children: devices
                          .map((e) => ListTile(
                                title: Text(e.alias),
                                subtitle: Text(e.address ?? "unknown"),
                              ))
                          .toList(),
                    );
                  },
                  done: () {
                    return const Text("discover state: done");
                  },
                ) ??
                const Text("discover state: unknown");
          } else {
            return const Text("discover state: unknown");
          }
        });
  }
}

class ProgressWidget extends StatefulWidget {
  const ProgressWidget({super.key});

  @override
  State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> {
  late Stream<Progress> progressStream;

  @override
  void initState() {
    super.initState();
    progressStream = listenProgress();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: progressStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print("progress state income");
            var state = snapshot.data;
            return state?.when(
                  idle: () {
                    return Container();
                  },
                  progress: (progress, total) {
                    return Container(
                      margin: EdgeInsets.all(16),
                      height: kToolbarHeight,
                      child: Center(
                        child: LinearProgressIndicator(
                          value: (progress / total),
                        ),
                      ),
                    );
                  },
                  done: () {
                    return Container();
                  },
                  prepare: () {
                    return Container(
                      child: Row(
                        children: [
                          const Text("send request"),
                          ElevatedButton(
                              onPressed: () async {
                                if (await Permission.manageExternalStorage
                                    .request()
                                    .isGranted) {
                                  accept(isAccept: true);
                                }
                              },
                              child: Text("accept")),
                          ElevatedButton(
                              onPressed: () {
                                accept(isAccept: false);
                              },
                              child: Text("reject")),
                        ],
                      ),
                    );
                  },
                ) ??
                Container();
          } else {
            return Container();
          }
        });
  }
}
