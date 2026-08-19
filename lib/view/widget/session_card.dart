import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/utils.dart';
import '../../core/providers/session_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../core/rust/bridge.dart';
import '../../i18n/strings.g.dart';

/// Determinate progress bar for one file transfer.
class FileProgressBar extends StatelessWidget {
  final int bytes;
  final int total;

  const FileProgressBar({super.key, required this.bytes, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = total > 0 ? (bytes / total).clamp(0.0, 1.0) : null;
    return LinearProgressIndicator(
      value: value,
      minHeight: 6,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

/// One file row inside a [SessionCard]: icon, name, size, state and —
/// while transferring — a live progress bar.
class SessionFileTile extends StatelessWidget {
  final MissionFileInfo file;
  final int bytes;
  final bool selected;
  final ValueChanged<bool?>? onSelected;

  const SessionFileTile({
    super.key,
    required this.file,
    this.bytes = 0,
    this.selected = true,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final transferring = file.state == const FileState.transfer();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (onSelected != null)
            Checkbox(
              value: selected,
              onChanged: onSelected,
            )
          else
            const SizedBox(width: 12),
          Icon(
            Icons.file_present,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${file.info.fileName} (${filesize(file.info.size)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transferring) ...[
                  const SizedBox(height: 4),
                  FileProgressBar(bytes: bytes, total: file.info.size),
                ] else
                  Text(
                    file.state.getName(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aggregate card for one transfer session: direction, peer, per-file
/// progress/state, failure reason and the actions valid for the current
/// state (accept/decline while pending, cancel while active).
class SessionCard extends ConsumerStatefulWidget {
  final SessionSummary summary;

  const SessionCard({super.key, required this.summary});

  @override
  ConsumerState<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<SessionCard> {
  /// Files selected for acceptance (pending receive sessions only).
  final Set<String> _selected = {};

  SessionSummary get summary => widget.summary;

  bool get isPendingReceive =>
      summary.direction == SessionDirection.receive &&
      summary.state == MissionState.pending;

  bool get isActive =>
      summary.state == MissionState.pending ||
      summary.state == MissionState.transfering;

  @override
  void initState() {
    super.initState();
    _selected.addAll(summary.files.map((f) => f.info.id));
  }

  @override
  void didUpdateWidget(SessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Newly arrived files of a still-pending session default to
    // selected.
    _selected.addAll(summary.files.map((f) => f.info.id));
  }

  @override
  Widget build(BuildContext context) {
    final extras = ref.watch(sessionExtrasProvider(summary.id));
    final incoming = summary.direction == SessionDirection.receive;
    final t = context.t;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  incoming ? Icons.download : Icons.upload,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPendingReceive
                        ? t.transfers.peerWantsToSend(
                            alias: summary.peer.alias,
                            count: summary.fileCount,
                          )
                        : incoming
                            ? '${t.transfers.incoming} · ${summary.peer.alias}'
                            : t.transfers.toPeer(alias: summary.peer.alias),
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  summary.state.getName(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final file in summary.files)
              SessionFileTile(
                file: file,
                bytes: extras.bytesFor(file.info.id),
                selected: _selected.contains(file.info.id),
                onSelected: isPendingReceive
                    ? (value) {
                        setState(() {
                          if (value ?? false) {
                            _selected.add(file.info.id);
                          } else {
                            _selected.remove(file.info.id);
                          }
                        });
                      }
                    : null,
              ),
            if (extras.failureReason != null) ...[
              const SizedBox(height: 4),
              Text(
                t.transfers.failedReason(reason: extras.failureReason!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (isPendingReceive || isActive) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPendingReceive) ...[
                    TextButton(
                      onPressed: () =>
                          declineSession(sessionId: summary.id),
                      child: Text(t.transfers.decline),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => acceptSession(
                                sessionId: summary.id,
                                fileIds:
                                    _selected.length == summary.files.length
                                        ? null
                                        : _selected.toList(),
                              ),
                      child: Text(t.transfers.accept),
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: () => cancelSession(sessionId: summary.id),
                      icon: const Icon(Icons.cancel),
                      label: Text(t.transfers.cancel),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
