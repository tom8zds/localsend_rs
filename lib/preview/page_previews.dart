import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/providers/session_providers.dart';
import '../core/rust/actor/model.dart';
import '../view/pages/send_page.dart';
import '../view/pages/transfers_page.dart';
import 'preview_scaffold.dart';

List<SessionSummary> _previewSessions() => [
      mockSession(
        id: 'preview-pending',
        direction: SessionDirection.receive,
        state: MissionState.pending,
      ),
      mockSession(
        id: 'preview-sending',
        direction: SessionDirection.send,
        state: MissionState.transfering,
        files: [
          mockFile('photo.jpg', 1024 * 1024,
              state: const FileState.transfer()),
          mockFile('notes.txt', 2048, state: const FileState.finish()),
        ],
      ),
      mockSession(
        id: 'preview-done',
        direction: SessionDirection.receive,
        state: MissionState.finished,
        files: [
          mockFile('slides.pdf', 3 * 1024 * 1024,
              state: const FileState.finish()),
        ],
      ),
    ];

const _previewExtras = {
  'preview-sending': SessionExtras(
    progress: {'id-photo.jpg': 512 * 1024},
  ),
};

/// Merged main page, compact width: send area on top, session cards
/// below (pending receive first, then active, then terminal).
@Preview(name: 'Transfers page')
Widget transfersPagePreview() => previewShell(
      name: 'transfersPage',
      width: 460,
      height: 760,
      overrides: previewOverrides(
        sessions: _previewSessions(),
        extras: _previewExtras,
      ),
      child: const TransfersPage(),
    );

/// Empty state: no staged files and no sessions yet.
@Preview(name: 'Transfers page (empty)')
Widget transfersPageEmptyPreview() => previewShell(
      name: 'transfersPageEmpty',
      overrides: previewOverrides(),
      child: const TransfersPage(),
    );

/// Wide layout with staged files and discovered devices: the page
/// splits into a left send/devices pane and a right session list.
@Preview(name: 'Transfers page (wide, staged files)', size: Size(1000, 700))
Widget transfersPageStagedPreview() => previewShell(
      name: 'transfersPageStaged',
      width: 1000,
      height: 700,
      overrides: previewOverrides(
        sessions: _previewSessions(),
        extras: _previewExtras,
        selectedFiles: const ['/tmp/photo.jpg', '/tmp/notes.txt'],
      ),
      child: const TransfersPage(),
    );

/// Send page with staged files and two discovered devices (provider
/// overrides supply both).
@Preview(name: 'Send page')
Widget sendPagePreview() => previewShell(
      name: 'sendPage',
      width: 460,
      height: 760,
      overrides: previewOverrides(
        selectedFiles: const ['/tmp/photo.jpg', '/tmp/notes.txt'],
      ),
      child: const SendPage(),
    );
