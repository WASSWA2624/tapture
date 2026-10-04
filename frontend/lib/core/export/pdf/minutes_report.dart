import 'pdf_engine.dart';
import 'transcript_report.dart';

/// Meeting minutes (task 018 step 12, A52): attendance, agenda, the raw
/// notes and the refined minutes side by side and each labelled as what it
/// is, the meeting's transcripts heard on the device with any edit beside
/// each (task 127), decisions, the action register and a photo appendix
/// referenced from the discussion. Refined or edited text is never
/// presented as recorded speech.
final class MinutesReport {
  /// The minutes of [meeting] in [project].
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required MinutesContent meeting,
    int photoColumns = 2,
    List<String> cover = const <String>[],
  }) {
    final PdfLabels text = engine.labels;
    return engine.document(
      title: text.minutesReport,
      project: project,
      coverLines: <String>[
        ...cover,
        meeting.title,
        if (meeting.date.isNotEmpty) meeting.date,
        '${text.attendance}: ${meeting.present.length}',
      ],
      sections: <PdfSection>[
        engine.section(
          heading: text.attendance,
          lines: <String>[
            ...meeting.present,
            for (final String person in meeting.apologies)
              '$person (${text.apology})',
          ],
        ),
        engine.section(
          heading: text.agenda,
          lines: <String>[
            for (final MinutesTopic item in meeting.agenda)
              item.notes.isEmpty ? item.title : '${item.title}: ${item.notes}',
          ],
        ),
        engine.section(
          heading: text.rawNotes,
          lines: <String>[
            if (meeting.rawNotes.isNotEmpty) meeting.rawNotes,
            if (meeting.photos.isNotEmpty)
              text.photoReference(meeting.photos.length),
          ],
        ),
        ...TranscriptReport.sections(engine, meeting.transcripts),
        engine.section(
          heading: text.refinedMinutes,
          lines: <String>[
            if (meeting.refinedMinutes.isNotEmpty) meeting.refinedMinutes,
          ],
        ),
        engine.section(heading: text.decisions, lines: meeting.decisions),
        engine.section(
          heading: text.actions,
          lines: <String>[
            for (final MinutesAction action in meeting.actions)
              '${action.text} · ${text.owner}: ${action.owner} · '
                  '${text.due}: ${action.due} · ${text.status}: ${action.status}',
          ],
        ),
        if (meeting.photos.isNotEmpty)
          engine.section(
            heading: text.photoAppendix,
            photos: engine.photoBlock(<PdfPhoto>[
              for (int index = 0; index < meeting.photos.length; index++)
                (
                  caption: meeting.photos[index].caption.isEmpty
                      ? '${index + 1}'
                      : '${index + 1}. ${meeting.photos[index].caption}',
                  path: meeting.photos[index].path,
                ),
            ], columns: photoColumns),
          ),
      ],
    );
  }
}

/// What the minutes print, read from the stored meeting of task 017.
typedef MinutesContent = ({
  String title,
  String date,
  List<String> present,
  List<String> apologies,
  List<MinutesTopic> agenda,
  String rawNotes,
  List<TranscriptContent> transcripts,
  String refinedMinutes,
  List<String> decisions,
  List<MinutesAction> actions,
  List<PdfPhoto> photos,
});

/// One agenda item and the notes taken under it.
typedef MinutesTopic = ({String title, String notes});

/// One row of the action register: action, owner, due date and status.
typedef MinutesAction = ({
  String text,
  String owner,
  String due,
  String status,
});
