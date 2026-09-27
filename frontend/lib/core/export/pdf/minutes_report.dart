import 'pdf_engine.dart';

/// Meeting minutes with raw and refined text labelled apart (task 018).
final class MinutesReport {
  /// Attendance, agenda, decisions, actions and a photo appendix.
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required List<String> attendance,
    required List<MinutesSection> agenda,
    required List<({String caption, String path})> photos,
  }) {
    return engine.document(
      title: 'Meeting minutes',
      project: project,
      coverLines: <String>['attendance ${attendance.length}'],
      bodyLines: <String>[
        'Attendance',
        ...attendance,
        for (final MinutesSection section in agenda) ...<String>[
          'Agenda ${section.title}',
          'Raw notes ${section.raw}',
          'Refined minutes ${section.refined}',
          for (final String decision in section.decisions) 'Decision $decision',
          for (final String action in section.actions) 'Action $action',
        ],
      ],
      photos: engine.photoBlock(photos, columns: 2),
    );
  }
}

/// One agenda section with both passages labelled.
typedef MinutesSection = ({
  String title,
  String raw,
  String refined,
  List<String> decisions,
  List<String> actions,
});
