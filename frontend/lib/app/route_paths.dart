/// Dependency-free route path construction shared by routing metadata and
/// feature screens. The router adds declarations and query semantics; path
/// segments stay centralised here to avoid feature-to-router import cycles.
abstract final class RoutePaths {
  /// Root shell paths.
  static const String projects = '/projects';
  static const String captureRoot = '/capture';
  static const String records = '/records';
  static const String more = '/more';

  /// Shared navigation query names.
  static const String fromQuery = 'from';
  static const String filterQuery = 'filter';

  /// Create-form query names: the project whose structure is copied, and
  /// the editable suggested name.
  static const String sourceQuery = 'source';
  static const String nameQuery = 'name';

  /// Global operational destinations retained for deep-link compatibility.
  static const String templates = '$more/templates';
  static const String queue = '$more/queue';
  static const String exports = '$more/exports';

  /// Deleted records across projects, restorable until the purge (task 014).
  static const String recycleBin = '$more/recycle-bin';

  /// Transcripts across projects, newest first (task 123).
  static const String transcripts = '$more/transcripts';

  /// Records and transcribes in the open project (task 123). Listed before
  /// [transcript] so `new` is not taken for an id.
  static const String transcribe = '$transcripts/new';

  /// One transcript, from the transcripts across projects (task 123).
  static String transcript(String id) =>
      '$transcripts/${Uri.encodeComponent(id)}';

  /// Settings destinations.
  static const String settingsOperator = '$more/operator';
  static const String settingsCapture = '$more/capture';
  static const String settingsAi = '$more/ai';
  static const String settingsLanguage = '$more/language';
  static const String settingsAppearance = '$more/appearance';
  static const String settingsStorage = '$more/storage';

  /// Files checked against their records, under Storage (tasks 004, 005).
  static const String settingsStorageCheck = '$settingsStorage/check';
  static const String settingsDestinations = '$more/destinations';
  static const String settingsUploads = '$more/uploads';
  static const String settingsFiles = '$more/files';
  static const String settingsSecurity = '$more/security';
  static const String settingsPrivacy = '$more/privacy';
  static const String settingsAccount = '$more/account';
  static const String settingsRelay = '$more/relay';

  /// The one sign-in, outside the shell like the lock screen (task 024).
  static const String signIn = '/sign-in';
  static const String settingsAbout = '$more/about';
  static const String settingsLicences = '$settingsAbout/licences';

  /// One project and its capture/context/template descendants.
  static String project(String id) => '$projects/${Uri.encodeComponent(id)}';
  static const String projectCreate = '$projects/new';

  /// The import entry on the projects list (task 020).
  static const String projectImport = '$projects/import';

  /// Whether a chosen spreadsheet holds records or a register (task 020).
  static const String projectImportPurpose = '$projectImport/purpose';

  /// Matching a chosen spreadsheet's columns onto a template (task 020).
  static const String projectImportRecords = '$projectImport/records';

  /// What a record import did (task 020).
  static const String projectImportSummary = '$projectImport/summary';
  static const String projectFilters = '$projects/filters';
  static String projectCapture(String projectId) =>
      '${project(projectId)}/capture';

  /// Rapid mode for [projectId]: one tap saves an item raw and starts the
  /// next (task 012 step 20).
  static String projectCaptureRapid(String projectId) =>
      '${projectCapture(projectId)}/rapid';
  static String projectEdit(String projectId) => '${project(projectId)}/edit';

  /// The project's read-only details page (task 076, D8).
  static String projectDetails(String projectId) =>
      '${project(projectId)}/details';

  /// Merging an open package into the project (task 076, W21).
  static String projectMerge(String projectId) => '${project(projectId)}/merge';

  /// Durable merge history and safe undo for one project.
  static String projectMergeHistory(String projectId) =>
      '${project(projectId)}/merge-history';

  /// The merge's conflicts, one at a time. [conflictId] opens one.
  static String projectMergeConflicts(String projectId, {String? conflictId}) =>
      conflictId == null
      ? '${projectMerge(projectId)}/conflicts'
      : '${projectMerge(projectId)}/conflicts'
            '?conflict=${Uri.encodeQueryComponent(conflictId)}';
  static String projectSettings(String projectId) =>
      '${project(projectId)}/settings';

  /// Optional encrypted exchange controls for one project.
  static String projectRelay(String projectId) =>
      '${projectSettings(projectId)}/relay';
  static String projectContext(String projectId) =>
      '${project(projectId)}/context';
  static String projectContextPresets(String projectId) =>
      '${projectContext(projectId)}/presets';
  static String projectTemplates(String projectId) =>
      '${project(projectId)}/templates';

  /// Template destinations. [projectId] keeps them inside the project branch.
  static String templateRoot({String? projectId}) {
    if (projectId == null || projectId.isEmpty) {
      return templates;
    }
    return projectTemplates(projectId);
  }

  static String templateCreate({String? projectId}) =>
      '${templateRoot(projectId: projectId)}/new';

  static String templateLibrary({String? projectId}) =>
      '${templateRoot(projectId: projectId)}/library';

  static String templateImport({String? projectId}) =>
      '${templateRoot(projectId: projectId)}/import';

  /// A template made from a workbook's columns; the workbook's path is the
  /// route's extra.
  static String templateXlsx({String? projectId}) =>
      '${templateRoot(projectId: projectId)}/xlsx';

  static String templateDetail(String templateId, {String? projectId}) =>
      '${templateRoot(projectId: projectId)}/${Uri.encodeComponent(templateId)}';

  static String templateRequired(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/required';

  static String templateIdentity(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/identity';

  static String templateOutput(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/output';

  static String templateMigrate(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/migrate';

  static String templateAliases(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/aliases';

  static String templateChecklist(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/checklist';

  static String templateDetection(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/detection';

  static String templateFieldNew(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/fields/new';

  static String templateField(
    String templateId,
    String fieldKey, {
    String? projectId,
  }) =>
      '${templateDetail(templateId, projectId: projectId)}/fields/'
      '${Uri.encodeComponent(fieldKey)}';

  static String templateFieldLookup(
    String templateId,
    String fieldKey, {
    String? projectId,
  }) => '${templateField(templateId, fieldKey, projectId: projectId)}/lookup';
  static String projectRecords(String projectId) =>
      '${project(projectId)}/records';

  /// Unresolved duplicate pairs for [projectId] (task 015).
  static String projectDuplicates(String projectId) =>
      '${project(projectId)}/duplicates';

  /// The side-by-side comparison of pair [pairId], where an override
  /// happens (task 015).
  static String projectDuplicateCompare(String projectId, String pairId) =>
      '${projectDuplicates(projectId)}/${Uri.encodeComponent(pairId)}';

  /// Query naming the one record a variance view is limited to.
  static const String recordQuery = 'record';

  /// Variances for [projectId], or for one record of it when [recordId] is
  /// given (task 015).
  static String projectVariance(String projectId, {String? recordId}) =>
      recordId == null
      ? '${project(projectId)}/variance'
      : '${project(projectId)}/variance?$recordQuery='
            '${Uri.encodeQueryComponent(recordId)}';

  /// What still blocks a clean export of [projectId] (task 015).
  static String projectQuality(String projectId) =>
      '${project(projectId)}/quality';

  /// The batch review queue for [projectId] (task 016).
  static String projectBatchReview(String projectId) =>
      '${project(projectId)}/review';

  /// Starts a meeting on [projectId] (task 017).
  static String projectMeetingCreate(String projectId) =>
      '${project(projectId)}/meetings/new';

  /// Reviews one meeting on [projectId] (task 017).
  static String projectMeetingReview(String projectId, String meetingId) =>
      '${project(projectId)}/meetings/${Uri.encodeComponent(meetingId)}/review';

  /// The transcripts of [projectId], newest first (task 123).
  static String projectTranscripts(String projectId) =>
      '${project(projectId)}/transcripts';

  /// Records and transcribes in [projectId] (task 123).
  static String projectTranscribe(String projectId) =>
      '${projectTranscripts(projectId)}/new';

  /// One transcript of [projectId] (task 123).
  static String projectTranscript(String projectId, String transcriptId) =>
      '${projectTranscripts(projectId)}/${Uri.encodeComponent(transcriptId)}';

  /// Review of one record inside its project (task 016).
  static String projectRecordReview(String projectId, String recordId) =>
      '${projectRecord(projectId, recordId)}/review';

  /// One record's page inside its project.
  static String projectRecord(String projectId, String recordId) =>
      '${projectRecords(projectId)}/${Uri.encodeComponent(recordId)}';

  /// Capture page that edits one saved record's photos and captions.
  static String projectRecordEdit(String projectId, String recordId) =>
      '${projectRecord(projectId, recordId)}/edit';

  /// The page that edits one record's values inside its project (task 014).
  static String projectRecordValuesEdit(String projectId, String recordId) =>
      '${projectRecord(projectId, recordId)}/values';

  /// One record's history inside its project (task 014).
  static String projectRecordHistory(String projectId, String recordId) =>
      '${projectRecord(projectId, recordId)}/history';
  static String projectQueue(String projectId) => '${project(projectId)}/queue';
  static String projectExports(String projectId) =>
      '${project(projectId)}/exports';

  /// Choose report formats and record scope for a project's deliverables.
  static String projectDeliverables(String projectId) =>
      '${projectExports(projectId)}/deliverable';

  /// One record.
  static String record(String id) => '$records/${Uri.encodeComponent(id)}';

  /// The page that edits one record's values, from the Records destination
  /// (task 014).
  static String recordValuesEdit(String id) => '${record(id)}/values';

  /// One record's history, from the Records destination (task 014).
  static String recordHistory(String id) => '${record(id)}/history';

  /// Dataset paths within a project.
  static String projectDatasets(String projectId) =>
      '${project(projectId)}/datasets';
  static String projectDatasetImport(String projectId) =>
      '${projectDatasets(projectId)}/import';
  static String projectDataset(String projectId, String datasetId) =>
      '${projectDatasets(projectId)}/${Uri.encodeComponent(datasetId)}';
  static String projectDatasetRow(
    String projectId,
    String datasetId,
    String rowId,
  ) =>
      '${projectDataset(projectId, datasetId)}/rows/'
      '${Uri.encodeComponent(rowId)}';

  /// Whether [path] is capture inside a project branch.
  static bool isProjectCapture(String path) {
    return path.startsWith('$projects/') && path.endsWith('/capture');
  }
}
