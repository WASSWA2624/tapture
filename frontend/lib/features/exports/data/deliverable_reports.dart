import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/pdf/inspection_report.dart';
import 'package:tapture/core/export/pdf/minutes_report.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/record_report.dart';
import 'package:tapture/core/export/pdf/summary_report.dart';
import 'package:tapture/core/export/pdf/variance_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/meetings/meetings.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart' show RecordFilter;

/// Reads report inputs and turns them into the A52 report documents.
final class DeliverableReports {
  /// Reads through [meetings] and [quality] over [db].
  const DeliverableReports({
    required this._db,
    required this._meetings,
    required this._quality,
  });

  final sqlite.AppDatabase _db;
  final MeetingRepository _meetings;
  final QualityRepository _quality;

  /// The meetings filed on [recordIds] in [projectId], keyed by record id.
  Future<Map<String, MeetingRecord>> meetingsOf(
    String projectId,
    Set<String> recordIds,
  ) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT m.id AS id, m.record_id AS record_id FROM meetings m '
          'JOIN records r ON r.id = m.record_id WHERE r.project_id = ? '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = "
          "'meetings' AND t.entity_id = m.id)",
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final Map<String, MeetingRecord> found = <String, MeetingRecord>{};
    for (final QueryRow row in rows) {
      final String recordId = row.read<String>('record_id');
      if (!recordIds.contains(recordId)) {
        continue;
      }
      final Result<MeetingRecord?> read = await _meetings.read(
        row.read<String>('id'),
      );
      if (read case Success<MeetingRecord?>(:final MeetingRecord value?)) {
        found[recordId] = value;
      }
    }
    return found;
  }

  /// Everything the reports of [request] need. [operator] and [createdAt]
  /// go on every cover with the scope, so a reader knows who made the file,
  /// when, and from which records.
  Future<DeliverableReportInputs> load(
    ExportRequest request, {
    required String projectName,
    required String operator,
    required DateTime createdAt,
  }) async {
    final Set<String> ids = <String>{
      for (final ExportRecord record in request.records) record.id,
    };
    final Map<String, MeetingRecord> meetings = await meetingsOf(
      request.projectId,
      ids,
    );
    final List<DeliverableMeeting> minutes = <DeliverableMeeting>[
      for (final ExportRecord record in request.records)
        if (meetings[record.id] case final MeetingRecord meeting)
          (number: record.number, minutes: minutesOf(meeting, record)),
    ];
    return (
      projectName: projectName,
      cover: <String>[
        Copy.pdfExportedAt(
          _formatter.format(createdAt, 'dateTime', ExportFormat.pdf),
        ),
        if (operator.isNotEmpty) Copy.pdfExportedBy(operator),
        Copy.pdfScope(Copy.exportScopeName(request.scope.kind.name)),
      ],
      checklists: await _checklists(request.records),
      meetings: minutes,
      variance: await _variance(request),
      actionRegister: <List<String>>[
        if (minutes.any((DeliverableMeeting m) => m.minutes.actions.isNotEmpty))
          <String>[
            Copy.pdfMinutesReport,
            Copy.meetingActionText,
            Copy.meetingOwner,
            Copy.meetingDue,
            Copy.meetingStatus,
          ],
        for (final DeliverableMeeting meeting in minutes)
          for (final MinutesAction action in meeting.minutes.actions)
            <String>[
              meeting.minutes.title,
              action.text,
              action.owner,
              action.due,
              action.status,
            ],
      ],
    );
  }

  /// The minutes of [meeting], with the photos of its [record] as the
  /// appendix, in their persisted order.
  static MinutesContent minutesOf(MeetingRecord meeting, ExportRecord record) {
    final Meeting body = meeting.meeting;
    return (
      title: body.title,
      date: _formatter.format(body.startedAt, 'dateTime', ExportFormat.pdf),
      present: <String>[
        for (final Attendee person in body.attendees)
          if (person.countsAsAttendance)
            <String>[
              person.name,
              person.title,
              person.organisation,
            ].where((String part) => part.trim().isNotEmpty).join(', '),
      ],
      apologies: <String>[
        for (final Attendee person in body.attendees)
          if (!person.countsAsAttendance) person.name,
      ],
      agenda: <MinutesTopic>[
        for (final AgendaEntry item in body.agenda)
          (title: item.title, notes: item.notes),
      ],
      rawNotes: <String>[
        meeting.notes,
        meeting.transcript,
      ].where((String part) => part.trim().isNotEmpty).join('\n'),
      refinedMinutes: meeting.minutes,
      decisions: <String>[
        for (final Decision decision in body.decisions) decision.text,
      ],
      actions: <MinutesAction>[
        for (final ActionEntry action in body.actions)
          (
            text: action.text,
            owner: action.ownerName,
            due: _formatter.format(action.due, 'date', ExportFormat.pdf),
            status: Copy.pdfActionStatus(action.status.name),
          ),
      ],
      photos: <PdfPhoto>[
        for (final ExportPhoto photo in record.photos)
          (caption: photo.caption, path: photo.storedPath),
      ],
    );
  }

  /// The report documents of [request], keyed by their file name: the
  /// record report and project summary always, an inspection report per
  /// checklist, the variance report where the project checks a register,
  /// and minutes per meeting. Pure, so it runs on the isolate.
  static Map<String, PdfDocument> documents(
    ExportRequest request,
    DeliverableReportInputs inputs,
    PdfEngine engine,
  ) {
    final String project = inputs.projectName;
    final int columns = PdfPhotoLayout.columns(request.extras.pdfPhotos);
    final DeliverableVariance? variance = inputs.variance;
    final Set<String> taken = <String>{};
    String name(String stem) {
      final String base = _stem(stem);
      var candidate = '$base.pdf';
      for (int copy = 2; !taken.add(candidate); copy++) {
        candidate = '$base-$copy.pdf';
      }
      return candidate;
    }

    return <String, PdfDocument>{
      name('records'): RecordReport.build(
        request,
        engine: engine,
        project: project,
        cover: inputs.cover,
      ),
      name('summary'): SummaryReport.build(
        engine: engine,
        project: project,
        records: request.records,
        conditionKeys: RecordFilter.conditionFieldKeys,
        cover: inputs.cover,
      ).document,
      for (final DeliverableChecklist checklist in inputs.checklists)
        name('inspection-${checklist.name}'): _inspection(
          request,
          inputs,
          engine,
          checklist,
        ),
      if (variance != null)
        name('variance'): VarianceReport.build(
          engine: engine,
          project: project,
          matched: variance.matched,
          missing: variance.missing,
          notInRegister: variance.notInRegister,
          cover: inputs.cover,
        ),
      for (final DeliverableMeeting meeting in inputs.meetings)
        name('minutes-${meeting.number}'): MinutesReport.build(
          engine: engine,
          project: project,
          meeting: meeting.minutes,
          photoColumns: columns,
          cover: inputs.cover,
        ),
    };
  }

  /// The inspection report of [checklist]: its predefined rows in order,
  /// the exported records answering them, and the rows task 015's
  /// missing-item computation finds uncaptured printed as not found.
  static PdfDocument _inspection(
    ExportRequest request,
    DeliverableReportInputs inputs,
    PdfEngine engine,
    DeliverableChecklist checklist,
  ) {
    final List<ExportRecord> answers = <ExportRecord>[
      for (final ExportRecord record in request.records)
        if (record.templateId == checklist.templateId) record,
    ];
    return InspectionReport.build(
      engine: engine,
      project: inputs.projectName,
      checklist: checklist.name,
      rows: checklist.rows,
      records: answers,
      notFound: UncapturedRows.compute(
        registerIds: const <String>[],
        capturedRegisterIds: const <String>{},
        checklistIds: <String>[
          for (final InspectionRowSpec row in checklist.rows) row.id,
        ],
        capturedChecklistIds: <String>{
          for (final ExportRecord record in answers) ?record.templateRowId,
        },
      ).checklistNotCaptured.toSet(),
      columns: request.columns,
      photoColumns: PdfPhotoLayout.columns(request.extras.pdfPhotos),
      cover: inputs.cover,
    );
  }

  /// Checklist templates among [records], with their predefined rows read
  /// in order from the template's stored rows (task 009).
  Future<List<DeliverableChecklist>> _checklists(
    List<ExportRecord> records,
  ) async {
    final Map<String, String> templates = <String, String>{
      for (final ExportRecord record in records)
        record.templateId: record.templateName,
    };
    final List<DeliverableChecklist> checklists = <DeliverableChecklist>[];
    for (final MapEntry<String, String> template in templates.entries) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT tr.id AS id, tr.label AS label FROM template_rows tr '
            'WHERE tr.template_id = ? AND NOT EXISTS (SELECT 1 FROM '
            "tombstones t WHERE t.entity_type = 'template_rows' "
            'AND t.entity_id = tr.id) ORDER BY tr.output_row_number, tr.rowid',
            variables: <Variable<Object>>[Variable<String>(template.key)],
          )
          .get();
      if (rows.isNotEmpty) {
        checklists.add((
          templateId: template.key,
          name: template.value,
          rows: <InspectionRowSpec>[
            for (final QueryRow row in rows)
              (id: row.read<String>('id'), label: row.read<String>('label')),
          ],
        ));
      }
    }
    return checklists;
  }

  /// The variance sets of [request]'s records, or null when the project
  /// checks no register.
  Future<DeliverableVariance?> _variance(ExportRequest request) async {
    final List<RecordVariance> variances = await _quality
        .watchVariances(request.projectId)
        .first;
    final Result<UncapturedRows> missing = await _quality.missingItems(
      request.projectId,
    );
    final List<String> notFound = switch (missing) {
      Success<UncapturedRows>(:final UncapturedRows value) =>
        value.registerNotFound,
      FailureResult<UncapturedRows>() => const <String>[],
    };
    final Map<String, String> keys = await _registerKeys(request.projectId);
    if (keys.isEmpty && notFound.isEmpty && variances.isEmpty) {
      return null;
    }
    final Map<String, List<String>> details = <String, List<String>>{};
    for (final RecordVariance variance in variances) {
      final String? line = switch (variance.status) {
        VarianceStatus.match => null,
        VarianceStatus.changed => Copy.pdfVarianceChanged(
          variance.label,
          variance.recorded,
          variance.found,
        ),
        VarianceStatus.missing => Copy.pdfVarianceEmpty(
          variance.label,
          variance.recorded,
        ),
      };
      if (line != null) {
        details.putIfAbsent(variance.recordId, () => <String>[]).add(line);
      }
    }
    return (
      matched: <VarianceLine>[
        for (final ExportRecord record in request.records)
          if (keys[record.id] case final String key)
            (
              key: key,
              label: '${record.templateName} ${record.number}',
              detail: details[record.id] ?? const <String>[],
            ),
      ],
      missing: <VarianceLine>[
        for (final String key in notFound)
          (key: key, label: '', detail: const <String>[]),
      ],
      notInRegister: <VarianceLine>[
        for (final ExportRecord record in request.records)
          if (!keys.containsKey(record.id))
            (
              key: record.number,
              label: record.templateName,
              detail: const <String>[],
            ),
      ],
    );
  }

  /// The register key each live record of [projectId] was filled from.
  Future<Map<String, String>> _registerKeys(String projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT f.record_id AS record_id, rr.key_value AS register_key '
          'FROM record_fields f JOIN records r ON r.id = f.record_id '
          'JOIN reference_rows rr ON f.method = ? || rr.id '
          'WHERE r.project_id = ? AND r.status <> ? '
          'AND f.retired_at IS NULL',
          variables: <Variable<Object>>[
            const Variable<String>(VarianceWriter.registerMethod),
            Variable<String>(projectId),
            Variable<String>(RecordStatus.deleted.stored),
          ],
        )
        .get();
    return <String, String>{
      for (final QueryRow row in rows)
        row.read<String>('record_id'): row.read<String>('register_key'),
    };
  }
}

/// A report's file stem: [name] as a file name keeps it, or `report`.
String _stem(String name) {
  try {
    return sanitiseSegment(name);
  } on Object {
    return 'report';
  }
}

/// The single formatter every export writer calls (FE-CONS-09).
const ExportValueFormatter _formatter = ExportValueFormatter(<String>{});

/// What the PDF reports need beyond the exported records, read once from
/// the stores that own it: checklist rows (task 009), meetings (task 017),
/// and variances and missing items (task 015). Plain data, so the reports
/// are built on the isolate with the rest of the render.
typedef DeliverableReportInputs = ({
  String projectName,
  List<String> cover,
  List<DeliverableChecklist> checklists,
  List<DeliverableMeeting> meetings,
  DeliverableVariance? variance,
  List<List<String>> actionRegister,
});

/// One checklist template among the exported records and its predefined
/// rows, in their order.
typedef DeliverableChecklist = ({
  String templateId,
  String name,
  List<InspectionRowSpec> rows,
});

/// One exported meeting record and the minutes it prints.
typedef DeliverableMeeting = ({String number, MinutesContent minutes});

/// The three variance sets, each item with its register key.
typedef DeliverableVariance = ({
  List<VarianceLine> matched,
  List<VarianceLine> missing,
  List<VarianceLine> notInRegister,
});
