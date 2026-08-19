import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/session_providers.dart';
import '../../core/rust/actor/model.dart';
import '../../i18n/strings.g.dart';
import '../widget/common_widget.dart';
import '../widget/session_card.dart';

/// Placeholder shown while there is nothing to transfer.
class IdlePage extends StatelessWidget {
  const IdlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: Image.asset("assets/icon/logo_512.png"),
        ),
        const AppTitle(),
        const SizedBox(height: 8),
        Text(context.t.transfers.empty),
      ],
    );
  }
}

/// Aggregate progress page: every send/receive session as a card with
/// per-file progress, state, failure reason and actions. Replaces the
/// old single-mission page.
class TransfersPage extends ConsumerWidget {
  /// True when rendered inside the side pane of the wide layout
  /// (transparent background, no back button).
  final bool embedded;

  const TransfersPage({super.key, this.embedded = false});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionIndexProvider);

    final body = switch (sessions) {
      AsyncData(:final value) when value.isNotEmpty => ListView(
          children: [
            for (final summary in sortSessions(value))
              SessionCard(key: ValueKey(summary.id), summary: summary),
            const SizedBox(height: 16),
          ],
        ),
      AsyncError(:final error) => Center(child: Text('$error')),
      _ => const IdlePage(),
    };

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: embedded
          ? null
          : AppBar(title: Text(context.t.transfers.title)),
      body: SafeArea(child: body),
    );
  }
}
