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
  static String projectCapture(String projectId) =>
      '${project(projectId)}/capture';
  static String projectEdit(String projectId) => '${project(projectId)}/edit';
  static String projectSettings(String projectId) =>
      '${project(projectId)}/settings';
  static String projectContext(String projectId) =>
      '${project(projectId)}/context';
  static String projectTemplates(String projectId) =>
      '${project(projectId)}/templates';
  static String projectRecords(String projectId) =>
      '${project(projectId)}/records';
  static String projectQueue(String projectId) => '${project(projectId)}/queue';
  static String projectExports(String projectId) =>
      '${project(projectId)}/exports';

  /// One record.
  static String record(String id) => '$records/${Uri.encodeComponent(id)}';

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
