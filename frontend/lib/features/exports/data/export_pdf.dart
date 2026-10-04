import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';

/// The PDF foundation as the app configures it: sizes from the type scale,
/// spacing from the spacing scale, colours from the daylight palette (a
/// printed page is light) and every word from [Copy] (FE-THEME-01,
/// FE-L10N-01).
PdfEngine exportPdfEngine() =>
    PdfEngine(style: _style, labels: exportPdfLabels);

/// Report words from the shared copy source.
final PdfLabels exportPdfLabels = PdfLabels(
  pageOf: Copy.pdfPageOf,
  missingPhoto: Copy.pdfMissingPhoto,
  recordReport: Copy.pdfRecordReport,
  context: Copy.recordDetailContextTitle,
  operator: Copy.recordHistoryOperator,
  captured: Copy.pdfCaptured,
  raw: Copy.pdfRaw,
  refined: Copy.pdfRefined,
  recordsCount: Copy.recordsCount,
  incomplete: Copy.exportIncompleteStamp,
  inspectionReport: Copy.pdfInspectionReport,
  notFound: Copy.pdfNotFound,
  checklistRows: Copy.pdfChecklistRows,
  notFoundCount: Copy.pdfNotFoundCount,
  compliance: Copy.pdfCompliance,
  summaryReport: Copy.pdfSummaryReport,
  byContext: Copy.pdfByContext,
  byTemplate: Copy.pdfByTemplate,
  byCondition: Copy.pdfByCondition,
  byStatus: Copy.pdfByStatus,
  noContext: Copy.pdfNoContext,
  noCondition: Copy.pdfNoCondition,
  unprocessed: Copy.pdfUnprocessed,
  needsReview: Copy.pdfNeedsReview,
  approved: Copy.pdfApproved,
  varianceReport: Copy.pdfVarianceReport,
  matched: Copy.pdfMatched,
  missing: Copy.varianceMissing,
  notInRegister: Copy.pdfNotInRegister,
  minutesReport: Copy.pdfMinutesReport,
  attendance: Copy.photoAttendance,
  apology: Copy.meetingApology,
  agenda: Copy.meetingAgenda,
  rawNotes: Copy.meetingNotes,
  refinedMinutes: Copy.meetingMinutes,
  transcriptReport: Copy.pdfTranscriptReport,
  transcriptRaw: Copy.pdfTranscriptRaw,
  transcriptEdited: Copy.pdfTranscriptEdited,
  decisions: Copy.meetingDecisions,
  actions: Copy.meetingActions,
  owner: Copy.meetingOwner,
  due: Copy.pdfDue,
  status: Copy.meetingStatus,
  photoAppendix: Copy.pdfPhotoAppendix,
  photoReference: Copy.pdfPhotoReference,
);

final PdfStyle _style = (
  title: AppText.display.fontSize!,
  heading: AppText.title.fontSize!,
  body: AppText.label.fontSize!,
  caption: AppText.caption.fontSize!,
  margin: Space.x9,
  gap: Space.x3,
  tight: Space.x1,
  ink: AppColors.light.onSurface.toARGB32(),
  muted: AppColors.light.onSurfaceMuted.toARGB32(),
  accent: AppColors.light.primary.toARGB32(),
  rule: AppColors.light.outline.toARGB32(),
);
