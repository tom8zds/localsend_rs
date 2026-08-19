import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/selection_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/discover_widget.dart';
import 'send_page.dart';

int _fileSize(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return 0;
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool refreshing = false;

  Future<void> refresh() async {
    setState(() {
      refreshing = true;
    });
    await announce();
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      setState(() {
        refreshing = false;
      });
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.pickFiles();
    final paths = result.map((file) => file.path).whereType<String>();
    if (paths.isNotEmpty) {
      ref.read(selectedFilesProvider.notifier).addAll(paths);
    }
  }

  Future<void> pickFolder() async {
    final selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory == null) {
      return;
    }
    final files = Directory(selectedDirectory)
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .toList();
    if (files.isNotEmpty) {
      ref.read(selectedFilesProvider.notifier).addAll(files);
    }
  }

  /// Quick single-send: tapping a device while files are staged sends
  /// them straight away.
  Future<void> quickSend(NodeDevice device) async {
    final files = ref.read(selectedFilesProvider);
    if (files.isEmpty) {
      return;
    }
    final failures =
        await sendFilesToTargets(targets: [device], files: files);
    if (!mounted) {
      return;
    }
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    final failure = failures[device];
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(t.send.sendFailed(alias: device.alias, reason: '$failure')),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(t.send.sentTo(count: files.length, alias: device.alias)),
        ),
      );
      ref.read(selectedFilesProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    final selectedFileSize =
        selectedFiles.fold<int>(0, (sum, path) => sum + _fileSize(path));
    final t = context.t;

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickFiles,
                      child: Text(t.home.sendFile),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    ElevatedButton(
                      onPressed: pickFolder,
                      child: Text(t.home.sendFolder),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.home.filesSummary(
                        count: selectedFiles.length,
                        size: filesize(selectedFileSize),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final path in selectedFiles)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Tooltip(
                                message:
                                    path.split(Platform.pathSeparator).last,
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      borderRadius: BorderRadius.circular(12)),
                                  height: 40,
                                  width: 40,
                                  child: const Icon(Icons.file_present),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: selectedFiles.isEmpty
                              ? null
                              : () => ref
                                  .read(selectedFilesProvider.notifier)
                                  .clear(),
                          icon: const Icon(Icons.clear_all),
                          label: Text(t.home.clear),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        FilledButton.icon(
                          onPressed: selectedFiles.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SendPage(),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.navigate_next),
                          label: Text(t.home.next),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Text(
                      t.home.nearbyDevices,
                      style: const TextStyle(
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
                        )),
                    if (selectedFiles.isNotEmpty)
                      Expanded(
                        child: Text(
                          t.home.tapToSend,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (refreshing)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              Expanded(child: DiscoverWidget(onDeviceTap: quickSend)),
            ],
          ),
        ),
      ),
    );
  }
}
