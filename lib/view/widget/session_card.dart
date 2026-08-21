import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/spacing.dart';
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
    // M3 defaults: 4dp track height, fully rounded ends.
    return LinearProgressIndicator(value: value);
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
      child: Row(
        children: [
          if (onSelected != null)
            Checkbox(
              value: selected,
              onChanged: onSelected,
            )
          else
            const SizedBox(width: AppSpacing.x12),
          Icon(
            Icons.file_present,
            // Supporting icon: on-surface-variant, not an accent.
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${file.info.fileName} (${filesize(file.info.size.toInt())})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (transferring) ...[
                  const SizedBox(height: AppSpacing.x4),
                  FileProgressBar(bytes: bytes, total: file.info.size.toInt()),
                ] else
                  Text(
                    file.state.getName(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
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

/// Small "via relay" marker for sessions tunneled through the TURN
/// relay. Same tonal-container treatment as [Tag], on the secondary
/// container so it stays distinct from the primary tags.
class RelayBadge extends StatelessWidget {
  const RelayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        // M3 chip corner: small (8dp).
        borderRadius: BorderRadius.circular(AppSpacing.x8),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.alt_route,
            size: 16,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.x4),
          Text(
            context.t.transfers.viaRelay,
            // Tonal pairing: on-secondary-container on
            // secondary-container.
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
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
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  incoming ? Icons.download : Icons.upload,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.x8),
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
                if (summary.viaRelay) ...[
                  const RelayBadge(),
                  const SizedBox(width: AppSpacing.x8),
                ],
                // Flexible so the ellipsizing title and the relay badge
                // can never push the state label into overflow.
                Flexible(
                  child: Text(
                    summary.state.getName(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x8),
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
              const SizedBox(height: AppSpacing.x4),
              Text(
                t.transfers.failedReason(reason: extras.failureReason!),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (isPendingReceive || isActive) ...[
              const SizedBox(height: AppSpacing.x8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPendingReceive) ...[
                    TextButton(
                      onPressed: () =>
                          declineSession(sessionId: summary.id),
                      child: Text(t.transfers.decline),
                    ),
                    const SizedBox(width: AppSpacing.x8),
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
