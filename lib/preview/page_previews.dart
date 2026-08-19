import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/providers/session_providers.dart';
import '../core/rust/actor/model.dart';
import '../view/pages/home_page.dart';
import '../view/pages/send_page.dart';
import '../view/pages/transfers_page.dart';
import 'preview_scaffold.dart';

/// Aggregate progress page with sessions in several states (pending
/// receive first, then active, then terminal).
@Preview(name: 'Transfers page')
Widget transfersPagePreview() => previewShell(
      width: 460,
      height: 760,
      overrides: previewOverrides(
        sessions: [
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
        ],
        extras: const {
          'preview-sending': SessionExtras(
            progress: {'id-photo.jpg': 512 * 1024},
          ),
        },
      ),
      child: const TransfersPage(embedded: true),
    );

@Preview(name: 'Transfers page (empty)')
Widget transfersPageEmptyPreview() => previewShell(
      overrides: previewOverrides(),
      child: const TransfersPage(embedded: true),
    );

/// Send page with staged files and two discovered devices (provider
/// overrides supply both).
@Preview(name: 'Send page')
Widget sendPagePreview() => previewShell(
      width: 460,
      height: 760,
      overrides: previewOverrides(
        selectedFiles: const ['/tmp/photo.jpg', '/tmp/notes.txt'],
      ),
      child: const SendPage(),
    );

@Preview(name: 'Home page')
Widget homePagePreview() => previewShell(
      width: 460,
      height: 760,
      overrides: previewOverrides(
        selectedFiles: const ['/tmp/photo.jpg'],
      ),
      child: const HomePage(),
    );
