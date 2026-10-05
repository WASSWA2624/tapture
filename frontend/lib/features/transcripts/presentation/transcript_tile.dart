import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';

import '../domain/transcript_owner_kind.dart';
import '../domain/transcript_status.dart';
import '../domain/transcript_summary.dart';

/// One transcript in a list: its name, when it was recorded and how it
/// starts, with chips for where it came from, a recording still running,
/// an interrupted one and an edit (FE-CONS-06).
class TranscriptTile extends StatelessWidget {
  /// A row for [summary]; [onTap] opens it. With [showOrigin] the row says
  /// whether it came from a capture, a meeting or the Transcribe screen.
  const TranscriptTile({
    required this.summary,
    this.onTap,
    this.showOrigin = false,
    super.key,
  });

  /// The transcript shown.
  final TranscriptSummary summary;

  /// Opens the transcript; null leaves the row untappable.
  final VoidCallback? onTap;

  /// Whether the origin chip is shown.
  final bool showOrigin;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);
    return AppListTile(
      key: ValueKey<String>('transcript-row-${summary.id}'),
      leading: const Icon(AppIcons.transcript),
      title: summary.title.isEmpty
          ? localCopy.liveTranscriptUntitled
          : UntrustedText(summary.title).forDisplay(),
      subtitle: localCopy.liveTranscriptRow(
        summary.startedAt,
        UntrustedText(summary.preview).forDisplay(),
      ),
      trailing: _marks(localCopy),
      wrapText: true,
      onTap: onTap,
    );
  }

  /// Chips for the origin, a transcript still recording or interrupted,
  /// and an edit.
  Widget? _marks(LocalizedCopy localCopy) {
    final List<String> labels = <String>[
      if (showOrigin) originLabel(localCopy, summary.ownerKind),
      if (summary.status == TranscriptStatus.live)
        localCopy.liveTranscriptRecording,
      if (summary.status == TranscriptStatus.interrupted)
        localCopy.liveTranscriptInterrupted,
      if (summary.edited) localCopy.liveTranscriptEdited,
    ];
    if (labels.isEmpty) {
      return null;
    }
    return Wrap(
      spacing: Space.x1,
      runSpacing: Space.x1,
      children: <Widget>[
        for (final String label in labels) AppChip(label: label),
      ],
    );
  }

  /// Where a transcript of [kind] came from, as its chip reads.
  static String originLabel(LocalizedCopy localCopy, TranscriptOwnerKind kind) {
    return switch (kind) {
      TranscriptOwnerKind.capture => localCopy.transcriptOriginCapture,
      TranscriptOwnerKind.meeting => localCopy.transcriptOriginMeeting,
      TranscriptOwnerKind.standalone => localCopy.transcriptOriginStandalone,
    };
  }
}
