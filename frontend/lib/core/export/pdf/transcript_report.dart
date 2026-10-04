import 'pdf_engine.dart';

/// Transcripts heard on the device (task 127): each one's raw text exactly
/// as heard and, where the operator edited it, the edit beside it, each
/// labelled as what it is. An edit is never presented as recorded speech.
final class TranscriptReport {
  /// The sections of [transcripts] in order: each raw text, then its edit
  /// when one stands. Minutes print these beside the meeting's notes.
  static List<PdfSection> sections(
    PdfEngine engine,
    List<TranscriptContent> transcripts,
  ) {
    final PdfLabels text = engine.labels;
    return <PdfSection>[
      for (final TranscriptContent transcript in transcripts) ...<PdfSection>[
        engine.section(
          heading: text.transcriptRaw(transcript.title),
          lines: <String>[if (transcript.raw.isNotEmpty) transcript.raw],
        ),
        if (transcript.edited case final String edited)
          engine.section(
            heading: text.transcriptEdited(transcript.title),
            lines: <String>[if (edited.isNotEmpty) edited],
          ),
      ],
    ];
  }

  /// The transcripts of an export of [project] as one report.
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required List<TranscriptContent> transcripts,
    List<String> cover = const <String>[],
  }) {
    return engine.document(
      title: engine.labels.transcriptReport,
      project: project,
      coverLines: cover,
      sections: sections(engine, transcripts),
    );
  }
}

/// One finished transcript as an export prints it: its title, the raw text
/// as heard, and the operator's edit when one stands.
typedef TranscriptContent = ({String title, String raw, String? edited});
