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

  /// Global operational destinations retained for deep-link compatibility.
  static const String templates = '$more/templates';
  static const String queue = '$more/queue';
  static const String exports = '$more/exports';

  /// Deleted records across projects, restorable until the purge (task 014).
  static const String recycleBin = '$more/recycle-bin';

  /// Settings destinations.
  static const String settingsOperator = '$more/operator';
  static const String settingsCapture = '$more/capture';
  static const String settingsAi = '$more/ai';
  static const String settingsLanguage = '$more/language';
  static const String settingsAppearance = '$more/appearance';
  static const String settingsStorage = '$more/storage';
  static const String settingsFiles = '$more/files';
  static const String settingsSecurity = '$more/security';
  static const String settingsAbout = '$more/about';
  static const String settingsLicences = '$settingsAbout/licences';

  /// One project and its capture/context/template descendants.
  static String project(String id) => '$projects/${Uri.encodeComponent(id)}';
  static const String projectCreate = '$projects/new';
  static const String projectFilters = '$projects/filters';
  static String projectCapture(String projectId) =>
      '${project(projectId)}/capture';
  static String projectEdit(String projectId) => '${project(projectId)}/edit';

  /// The project's read-only details page (task 076, D8).
  static String projectDetails(String projectId) =>
      '${project(projectId)}/details';

  /// Merging an open package into the project (task 076, W21).
  static String projectMerge(String projectId) => '${project(projectId)}/merge';

  /// The merge's conflicts, one at a time. [conflictId] opens one.
  static String projectMergeConflicts(String projectId, {String? conflictId}) =>
      conflictId == null
      ? '${projectMerge(projectId)}/conflicts'
      : '${projectMerge(projectId)}/conflicts'
            '?conflict=${Uri.encodeQueryComponent(conflictId)}';
  static String projectSettings(String projectId) =>
      '${project(projectId)}/settings';
  static String projectContext(String projectId) =>
      '${project(projectId)}/context';
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

  static String templateDetail(String templateId, {String? projectId}) =>
      '${templateRoot(projectId: projectId)}/${Uri.encodeComponent(templateId)}';

  static String templateExport(String templateId, {String? projectId}) =>
      '${templateDetail(templateId, projectId: projectId)}/export';

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

  /// Variances for [projectId] (task 015).
  static String projectVariance(String projectId) =>
      '${project(projectId)}/variance';

  /// What still blocks a clean export of [projectId] (task 015).
  static String projectQuality(String projectId) =>
      '${project(projectId)}/quality';

  /// The batch review queue for [projectId] (task 016).
  static String projectBatchReview(String projectId) =>
      '${project(projectId)}/review';

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
