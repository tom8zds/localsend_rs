import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/spacing.dart';
import '../../core/providers/core_provider.dart';
import '../../core/providers/selection_providers.dart';
import '../../core/providers/session_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import '../widget/discover_widget.dart';
import '../widget/session_card.dart';
import 'send_page.dart';

int _fileSize(String path) {
  try {
    return File(path).lengthSync();
  } catch (_) {
    return 0;
  }
}

/// Placeholder shown while there is nothing to transfer.
class IdlePage extends StatelessWidget {
  const IdlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Image.asset("assets/icon/logo_512.png"),
          ),
          const AppTitle(),
          const SizedBox(height: AppSpacing.x8),
          Text(context.t.transfers.empty),
        ],
      ),
    );
  }
}

/// Main page: file staging + nearby devices on top (former HomePage),
/// with every send/receive session as a card below/beside it.
///
/// Narrow layouts get a single scrollable column (send area, then
/// devices, then sessions); wide layouts split into a left column
/// (send area + device list) and a right session list.
class TransfersPage extends ConsumerStatefulWidget {
  static int _diagBuilds = 0;

  const TransfersPage({super.key});

  /// Pending receive sessions first (they need a decision), then
  /// active transfers, then everything else; stable by id within a
  /// group.
  static List<SessionSummary> sortSessions(List<SessionSummary> sessions) {
    int rank(SessionSummary s) {
      if (s.direction == SessionDirection.receive &&
          s.state == MissionState.pending) {
        return 0;
      }
      if (s.state == MissionState.pending ||
          s.state == MissionState.transfering) {
        return 1;
      }
      return 2;
    }

    final sorted = [...sessions]
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.id.compareTo(b.id);
      });
    return sorted;
  }

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
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

  Widget _sendButtons(BuildContext context) {
    final t = context.t;
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        children: [
          ElevatedButton(
            onPressed: pickFiles,
            child: Text(t.home.sendFile),
          ),
          const SizedBox(width: AppSpacing.x8),
          ElevatedButton(
            onPressed: pickFolder,
            child: Text(t.home.sendFolder),
          ),
        ],
      ),
    );
  }

  Widget _filesSummary(BuildContext context, List<String> selectedFiles) {
    final t = context.t;
    final selectedFileSize =
        selectedFiles.fold<int>(0, (sum, path) => sum + _fileSize(path));
    return SizedBox(
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
          const SizedBox(height: AppSpacing.x8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final path in selectedFiles)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Tooltip(
                      message: fileBaseName(path),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.x12),
                        ),
                        height: 40,
                        width: 40,
                        child: const Icon(Icons.file_present),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: selectedFiles.isEmpty
                    ? null
                    : () =>
                        ref.read(selectedFilesProvider.notifier).clear(),
                icon: const Icon(Icons.clear_all),
                label: Text(t.home.clear),
              ),
              const SizedBox(width: AppSpacing.x8),
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
    );
  }

  Widget _devicesHeader(BuildContext context, List<String> selectedFiles) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x8),
      child: Row(
        children: [
          // Section header: title-medium per M3 typography scale.
          Text(
            t.home.nearbyDevices,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: AppSpacing.x8),
          // Default IconButton keeps the 48dp minimum touch target.
          IconButton(
            onPressed: () {
              refresh();
            },
            icon: const Icon(Icons.sync),
          ),
          if (selectedFiles.isNotEmpty)
            Expanded(
              child: Text(
                t.home.tapToSend,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x8,
      ),
      child: Text(
        context.t.transfers.title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFiles = ref.watch(selectedFilesProvider);
    final sessions = ref.watch(sessionIndexProvider);
    // TEMPORARY flicker diagnosis: correlate page rebuilds with the
    // discover widget counter below
    TransfersPage._diagBuilds++;
    debugPrint(
        'TRANSFERS-BUILD #${TransfersPage._diagBuilds} devices-hash='
        '${ref.watch(devicesProvider).hasValue}');


    final sessionCards = switch (sessions) {
      AsyncData(:final value) when value.isNotEmpty => [
          for (final summary in TransfersPage.sortSessions(value))
            SessionCard(key: ValueKey(summary.id), summary: summary),
        ],
      AsyncError(:final error) => [
          Center(child: Text('$error')),
        ],
      _ => null,
    };

    final sendArea = [
      _sendButtons(context),
      _filesSummary(context, selectedFiles),
      const SizedBox(height: AppSpacing.x8),
      _devicesHeader(context, selectedFiles),
      if (refreshing)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.x8),
          child: LinearProgressIndicator(),
        ),
    ];

    return Scaffold(
      // LayoutBuilder (not MediaQuery): the split decision follows the
      // space actually given to this page, so it stays correct inside
      // panes and the fixed-size widget previews.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // M3 expanded window class: two panes from 840dp.
            final wide = constraints.maxWidth >= AppBreakpoints.expanded;
            if (wide) {
              // Two panes: send area + device list on the left, session
              // cards on the right.
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x16,
                      ),
                      child: Column(
                        children: [
                          ...sendArea,
                          Expanded(
                            child: DiscoverWidget(onDeviceTap: quickSend),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x16,
                      ),
                      children: [
                        _sessionsHeader(context),
                        ...(sessionCards ?? [const IdlePage()]),
                        const SizedBox(height: AppSpacing.x16),
                      ],
                    ),
                  ),
                ],
              );
            }
            // Single scrollable column: send area, devices, sessions.
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
              children: [
                ...sendArea,
                SizedBox(
                  height: 280,
                  child: DiscoverWidget(onDeviceTap: quickSend),
                ),
                _sessionsHeader(context),
                ...(sessionCards ?? [const IdlePage()]),
                const SizedBox(height: AppSpacing.x16),
              ],
            );
          },
        ),
      ),
    );
  }
}
