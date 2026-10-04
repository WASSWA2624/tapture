/// Every word the PDF reports print, supplied by the caller from the shared
/// copy source so no report hardcodes its language (FE-L10N-01). Pure data:
/// the functions are static tear-offs, so a whole set travels to the
/// rendering isolate.
final class PdfLabels {
  /// Creates the labels. Every field is required so no report prints a
  /// blank where a word belongs.
  const PdfLabels({
    required this.pageOf,
    required this.missingPhoto,
    required this.recordReport,
    required this.context,
    required this.operator,
    required this.captured,
    required this.raw,
    required this.refined,
    required this.recordsCount,
    required this.incomplete,
    required this.inspectionReport,
    required this.notFound,
    required this.checklistRows,
    required this.notFoundCount,
    required this.compliance,
    required this.summaryReport,
    required this.byContext,
    required this.byTemplate,
    required this.byCondition,
    required this.byStatus,
    required this.noContext,
    required this.noCondition,
    required this.unprocessed,
    required this.needsReview,
    required this.approved,
    required this.varianceReport,
    required this.matched,
    required this.missing,
    required this.notInRegister,
    required this.minutesReport,
    required this.attendance,
    required this.apology,
    required this.agenda,
    required this.rawNotes,
    required this.refinedMinutes,
    required this.transcriptReport,
    required this.transcriptHeard,
    required this.transcriptEdited,
    required this.decisions,
    required this.actions,
    required this.owner,
    required this.due,
    required this.status,
    required this.photoAppendix,
    required this.photoReference,
  });

  /// Footer page number, `n of m`.
  final String Function(int page, int pages) pageOf;

  /// Printed where a photo's bytes could not be read.
  final String missingPhoto;

  /// Title of the record report.
  final String recordReport;

  /// Label of a record's context path.
  final String context;

  /// Label of the operator who captured a record.
  final String operator;

  /// Label of when a record was captured.
  final String captured;

  /// A field label marked as the raw, as-captured value.
  final String Function(String label) raw;

  /// A field label marked as the refined value.
  final String Function(String label) refined;

  /// How many records a report holds.
  final String Function(int n) recordsCount;

  /// Stamped on a report exported despite incomplete records.
  final String incomplete;

  /// Title of the inspection report.
  final String inspectionReport;

  /// A checklist row never captured: a finding, not a gap.
  final String notFound;

  /// How many predefined rows a checklist has.
  final String Function(int n) checklistRows;

  /// How many checklist rows were not found.
  final String Function(int n) notFoundCount;

  /// How many captured rows comply, out of all rows.
  final String Function(int compliant, int total) compliance;

  /// Title of the project summary.
  final String summaryReport;

  /// Heading of the counts by context.
  final String byContext;

  /// Heading of the counts by template.
  final String byTemplate;

  /// Heading of the counts by condition.
  final String byCondition;

  /// Heading of the counts by status.
  final String byStatus;

  /// Group name for records captured with no context.
  final String noContext;

  /// Group name for records with no condition recorded.
  final String noCondition;

  /// Status group: waiting to be processed, being processed, or failed.
  final String unprocessed;

  /// Status group: waiting for a person to review.
  final String needsReview;

  /// Status group: approved.
  final String approved;

  /// Title of the variance report.
  final String varianceReport;

  /// Heading of register items that were found.
  final String matched;

  /// Heading of register items that were not found.
  final String missing;

  /// Heading of items found that the register does not list.
  final String notInRegister;

  /// Title of the meeting minutes.
  final String minutesReport;

  /// Heading of the people present.
  final String attendance;

  /// Marks a person who sent an apology; never counted as present.
  final String apology;

  /// Heading of the agenda.
  final String agenda;

  /// Label of the raw transcript and notes, as recorded.
  final String rawNotes;

  /// Label of the refined minutes, never presented as recorded speech.
  final String refinedMinutes;

  /// Title of the transcripts report.
  final String transcriptReport;

  /// Heading of a transcript's raw text, exactly as heard.
  final String Function(String title) transcriptHeard;

  /// Heading of the operator's edit of a transcript, never presented as
  /// recorded speech.
  final String Function(String title) transcriptEdited;

  /// Heading of the decisions.
  final String decisions;

  /// Heading of the action register.
  final String actions;

  /// Label of an action's owner.
  final String owner;

  /// Label of an action's due date.
  final String due;

  /// Label of an action's status.
  final String status;

  /// Heading of the photo appendix.
  final String photoAppendix;

  /// Points from the discussion to the [n] photos in the appendix.
  final String Function(int n) photoReference;
}
