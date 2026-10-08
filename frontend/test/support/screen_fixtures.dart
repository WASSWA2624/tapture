import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';

import 'screen_fixture.dart';

/// Empty repositories, with only the owning project/template/record retained.
abstract final class ScreenFixtures {
  static const String project = 'created-1';
  static const String template = 'template-1';
  static const String record = 'record-1';

  static final List<ScreenFixture> collections = <ScreenFixture>[
    ScreenFixture(
      'ProjectListScreen',
      RoutePaths.projects,
      project: false,
      action: Copy.projectsCreate,
    ),
    ScreenFixture(
      'RecordsListScreen',
      RoutePaths.projectRecords(project),
      action: Copy.recordsEmptyAction,
    ),
    ScreenFixture(
      'RecycleBinScreen',
      RoutePaths.recycleBin,
      action: Copy.navRecords,
    ),
    ScreenFixture(
      'TranscriptsScreen',
      RoutePaths.transcripts,
      action: Copy.transcriptsNew,
    ),
    ScreenFixture(
      'RecordHistoryScreen',
      RoutePaths.recordHistory(record),
      record: true,
      action: Copy.recordHistoryBackToRecord,
    ),
    ScreenFixture(
      'ProjectMergeHistoryScreen',
      RoutePaths.projectMergeHistory(project),
      action: Copy.importTitle,
    ),
    ScreenFixture(
      'QueueScreen',
      RoutePaths.projectQueue(project),
      action: Copy.recordsEmptyAction,
    ),
    ScreenFixture(
      'BatchReviewScreen',
      RoutePaths.projectBatchReview(project),
      action: Copy.reviewBackToRecords,
    ),
    ScreenFixture(
      'DuplicatesScreen',
      RoutePaths.projectDuplicates(project),
      action: Copy.duplicatesScan,
    ),
    ScreenFixture(
      'VarianceScreen',
      RoutePaths.projectVariance(project),
      action: Copy.varianceOpenRecords,
    ),
    ScreenFixture(
      'TemplateListScreen',
      RoutePaths.projectTemplates(project),
      action: Copy.templatesCreate,
    ),
    ScreenFixture(
      'FieldListScreen',
      RoutePaths.templateDetail(template),
      template: true,
      action: Copy.templatesAddField,
    ),
    ScreenFixture(
      'RequiredColumnsScreen',
      RoutePaths.templateRequired(template),
      template: true,
      action: Copy.templatesAddField,
    ),
    ScreenFixture(
      'IdentityFieldsScreen',
      RoutePaths.templateIdentity(template),
      template: true,
      action: Copy.templatesAddField,
    ),
    ScreenFixture(
      'OutputMappingScreen',
      RoutePaths.templateOutput(template),
      template: true,
      action: Copy.templatesAddField,
    ),
    ScreenFixture(
      'ChecklistScreen',
      RoutePaths.templateChecklist(template),
      template: true,
      action: Copy.checklistImportRows,
    ),
    ScreenFixture(
      'RowAliasesScreen',
      RoutePaths.templateAliases(template),
      template: true,
      action: Copy.templateFieldsTitle,
    ),
    ScreenFixture(
      'TemplateMigrationScreen',
      RoutePaths.templateMigrate(template),
      template: true,
      action: Copy.templateFieldsTitle,
    ),
    ScreenFixture(
      'LookupBindingScreen',
      RoutePaths.templateFieldLookup(template, 'serial'),
      template: true,
      action: Copy.templateFieldsTitle,
    ),
    ScreenFixture(
      'ContextHierarchyScreen',
      RoutePaths.projectContext(project),
      action: Copy.contextOpenTemplates,
    ),
    ScreenFixture(
      'ContextPresetList',
      RoutePaths.projectContextPresets(project),
      action: Copy.contextPresetSave,
    ),
    ScreenFixture(
      'DatasetListScreen',
      RoutePaths.projectDatasets(project),
      action: Copy.datasetsImport,
    ),
    ScreenFixture(
      'DatasetBrowserScreen',
      RoutePaths.projectDataset(project, 'ds'),
      dataset: true,
      action: Copy.datasetsImport,
    ),
    ScreenFixture(
      'DestinationListScreen',
      RoutePaths.settingsDestinations,
      action: Copy.destinationAdd,
    ),
    ScreenFixture(
      'UploadHistoryScreen',
      RoutePaths.settingsUploads,
      action: Copy.uploadHistoryEmptyAction,
    ),
    ScreenFixture('SettingsScreen', RoutePaths.more, action: Copy.tryAgain),
    ScreenFixture(
      'LicencesScreen',
      RoutePaths.settingsLicences,
      action: Copy.settingsAboutTitle,
    ),
    ScreenFixture(
      'AboutScreen',
      RoutePaths.settingsAbout,
      action: Copy.tryAgain,
    ),
    ScreenFixture(
      'XlsxMappingScreen',
      RoutePaths.templateXlsx(),
      action: Copy.templatesImport,
    ),
    ScreenFixture(
      'RecordMappingScreen',
      RoutePaths.projectImportRecords,
      action: Copy.importChooseFile,
    ),
    ScreenFixture(
      'ImportSummaryScreen',
      RoutePaths.projectImportSummary,
      action: Copy.importChooseFile,
    ),
    ScreenFixture(
      'RapidModeScreen',
      '${RoutePaths.projectCapture(project)}/rapid',
      action: Copy.captureTakePhoto,
    ),
    ScreenFixture(
      'CaptureScreen',
      RoutePaths.projectCapture(project),
      action: Copy.captureAddPhoto,
    ),
    ScreenFixture(
      'ProjectExportScreen',
      RoutePaths.projectExports(project),
      action: Copy.recordsEmptyAction,
    ),
    ScreenFixture(
      'ExportWorkflowScreen',
      RoutePaths.projectDeliverables(project),
      action: Copy.recordsEmptyAction,
    ),
    ScreenFixture(
      'ShippedPickerScreen',
      RoutePaths.templateLibrary(),
      action: Copy.navTemplates,
    ),
  ];

  /// Every routed collection fixture participates; new routes cannot be waived.
  static Iterable<ScreenFixture> get primary => collections;
}
