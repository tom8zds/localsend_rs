import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/providers/session_providers.dart';
import '../core/rust/actor/model.dart';
import '../view/widget/session_card.dart';
import 'preview_scaffold.dart';

@Preview(name: 'Progress bar')
Widget fileProgressBarPreview() => previewShell(
      name: 'fileProgressBar',
      height: 60,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: FileProgressBar(bytes: 512, total: 1024),
      ),
    );

/// Receive confirmation: pending incoming session with per-file
/// selection and accept/decline actions.
@Preview(name: 'Session card (pending receive)')
Widget sessionCardPendingReceivePreview() => previewShell(
      name: 'sessionCardPendingReceive',
      child: SingleChildScrollView(
        child: SessionCard(
          summary: mockSession(
            id: 'preview-pending',
            direction: SessionDirection.receive,
            state: MissionState.pending,
          ),
        ),
      ),
    );

@Preview(name: 'Session card (transferring send)')
Widget sessionCardTransferringSendPreview() {
  final summary = mockSession(
    id: 'preview-sending',
    direction: SessionDirection.send,
    state: MissionState.transfering,
    files: [
      mockFile('photo.jpg', 1024 * 1024, state: const FileState.transfer()),
      mockFile('notes.txt', 2048, state: const FileState.finish()),
    ],
  );
  return previewShell(
    name: 'sessionCardTransferring',
    overrides: previewOverrides(
      extras: {
        'preview-sending': const SessionExtras(
          progress: {'id-photo.jpg': 512 * 1024},
        ),
      },
    ),
    child: SingleChildScrollView(child: SessionCard(summary: summary)),
  );
}

@Preview(name: 'Session card (failed)')
Widget sessionCardFailedPreview() {
  final summary = mockSession(
    id: 'preview-failed',
    direction: SessionDirection.receive,
    state: MissionState.failed,
    files: [
      mockFile('photo.jpg', 1024 * 1024, state: const FileState.finish()),
      mockFile(
        'video.mp4',
        8 * 1024 * 1024,
        state: const FileState.fail(msg: 'connection reset'),
      ),
    ],
  );
  return previewShell(
    name: 'sessionCardFailed',
    overrides: previewOverrides(
      extras: {
        'preview-failed':
            const SessionExtras(failureReason: 'connection reset'),
      },
    ),
    child: SingleChildScrollView(child: SessionCard(summary: summary)),
  );
}
