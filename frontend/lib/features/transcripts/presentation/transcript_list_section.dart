import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

import '../domain/transcript_summary.dart';
import 'transcript_providers.dart';
import 'transcript_tile.dart';

/// The transcripts heard from a record's audio, or recorded for a meeting,
/// as a section a record or meeting page embeds.
///
/// It shows nothing until there is a transcript, so the page around it
/// keeps its own empty state. Each row names the transcript, when it was
/// recorded and how it starts, and marks one still recording, interrupted
/// or edited.
class TranscriptListSection extends ConsumerWidget {
  /// The transcripts of record [recordId], or of meeting [meetingId] when
  /// no record is given. [onOpen] opens a transcript; without it the rows
  /// are not tappable.
  const TranscriptListSection({
    this.recordId,
    this.meetingId,
    this.onOpen,
    super.key,
  }) : assert(
         recordId != null || meetingId != null,
         'a record or a meeting is named',
       );

  /// The record whose audio the transcripts were heard from.
  final String? recordId;

  /// The meeting the transcripts were recorded for.
  final String? meetingId;

  /// Opens a transcript.
  final ValueChanged<TranscriptSummary>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);
    final String? record = recordId;
    final String? meeting = meetingId;
    final AsyncValue<List<TranscriptSummary>> watched = record != null
        ? ref.watch(recordTranscriptsProvider(record))
        : ref.watch(meetingTranscriptsProvider(meeting ?? ''));
    final List<TranscriptSummary> transcripts =
        watched.value ?? const <TranscriptSummary>[];
    if (transcripts.isEmpty) {
      return const SizedBox.shrink();
    }
    final ValueChanged<TranscriptSummary>? open = onOpen;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(title: localCopy.liveTranscriptListTitle),
        for (final TranscriptSummary transcript in transcripts)
          TranscriptTile(
            summary: transcript,
            onTap: open == null ? null : () => open(transcript),
          ),
      ],
    );
  }
}
