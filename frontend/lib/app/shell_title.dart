import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/projects/projects.dart';

import 'route_paths.dart';
import 'router.dart';
import 'shell_destination.dart';

/// Route titles for the shell header and for feedback's screen name.
///
/// Every route names the screen, including the four branch roots. A page
/// is titled by its own name, the same `Copy` key as the row that opens
/// it, so Templates reads Templates wherever it was opened from. The status
/// line draws a back control only when [isRoot] is false (FE-CONS-02).
abstract final class ShellTitle {
  /// Capture branch. Matches the private path on the router.
  static const String capture = RoutePaths.captureRoot;

  /// True for the four destinations, unless a filter has drilled in.
  static bool isRoot(Uri uri) {
    final String path = uri.path;
    final bool root =
        path == AppRoutes.projects ||
        path == capture ||
        path == AppRoutes.records ||
        path == AppRoutes.more;
    if (!root) {
      return false;
    }
    return !uri.queryParameters.containsKey(AppRoutes.filterQuery);
  }

  /// Screen name for [uri], including branch roots. Never empty: a path
  /// with no title of its own takes its destination's name.
  static String screen(WidgetRef ref, Uri uri, {LocalizedCopy? localizedCopy}) {
    final LocalizedCopy localCopy = localizedCopy ?? Copy.english;
    final String path = uri.path;
    if (path == '/') {
      return localCopy.navProjects;
    }
    if (path == AppRoutes.projectCreate) {
      final String? source = uri.queryParameters[AppRoutes.sourceQuery];
      if (source != null && source.isNotEmpty) {
        return localCopy.projectDuplicateTitle;
      }
      return localCopy.projectCreateTitle;
    }
    if (path.startsWith('${AppRoutes.records}/')) {
      return localCopy.navRecords;
    }
    if (path.startsWith('${AppRoutes.templates}/')) {
      return localCopy.navTemplates;
    }
    if (path.startsWith('${RoutePaths.transcripts}/')) {
      return path == RoutePaths.transcribe
          ? localCopy.transcribeTitle
          : localCopy.transcriptDetailTitle;
    }
    final String? titled = _titles(localCopy)[path];
    if (titled != null) {
      return titled;
    }
    if (path.startsWith('${AppRoutes.projects}/')) {
      final String project =
          ref.watch(currentProjectDetailsProvider)?.name ??
          localCopy.navProjects;
      final List<String> segments = uri.pathSegments;
      final String leaf = segments.length < 3
          ? ''
          : _projectLeaf(segments.skip(2).toList(growable: false), localCopy);
      return <String>[
        localCopy.navProjects,
        project,
        if (leaf.isNotEmpty) leaf,
      ].join(' › ');
    }
    return shellDestinationFor(uri)?.labelFor(localCopy) ??
        localCopy.navProjects;
  }

  /// Fallback after navigators and their guards decline to handle Back.
  /// Projects is the native exit boundary; clearing a filter stays on its page.
  static String? backLocation(Uri uri) {
    if (uri.queryParameters.containsKey(RoutePaths.filterQuery)) {
      final Map<String, List<String>> query = Map<String, List<String>>.of(
        uri.queryParametersAll,
      )..remove(RoutePaths.filterQuery);
      return Uri(
        path: uri.path,
        queryParameters: query.isEmpty ? null : query,
        fragment: uri.hasFragment ? uri.fragment : null,
      ).toString();
    }
    return uri.path == RoutePaths.projects ? null : parentOf(uri.path);
  }

  /// The nearest declared parent, skipping grouping segments without a page.
  static String parentOf(String path) {
    final List<String> parts = path
        .split('/')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    if (parts.length <= 1) {
      return AppRoutes.projects;
    }
    if (parts.first == 'projects' && parts.length > 2) {
      final String projectId = Uri.decodeComponent(parts[1]);
      if (parts[2] == 'meetings') {
        return RoutePaths.project(projectId);
      }
      if (parts[2] == 'datasets' && parts.length == 6 && parts[4] == 'rows') {
        return RoutePaths.projectDataset(
          projectId,
          Uri.decodeComponent(parts[3]),
        );
      }
    }
    // Template field routes are declared as fields/:id and fields/new,
    // without an intermediate fields screen in either template branch.
    final int templates = parts.indexOf('templates');
    if (templates >= 0 &&
        parts.length == templates + 4 &&
        parts[templates + 2] == 'fields') {
      return RoutePaths.templateDetail(
        Uri.decodeComponent(parts[templates + 1]),
        projectId: parts.first == 'projects'
            ? Uri.decodeComponent(parts[1])
            : null,
      );
    }
    parts.removeLast();
    return '/${parts.join('/')}';
  }
}

/// One title per fixed path: the destinations, the secondary destinations
/// and every settings page.
Map<String, String> _titles(LocalizedCopy localCopy) => <String, String>{
  RoutePaths.projects: localCopy.navProjects,
  RoutePaths.projectImport: localCopy.importTitle,
  RoutePaths.projectImportPurpose: localCopy.importPurposeTitle,
  RoutePaths.projectImportRecords: localCopy.importMappingTitle,
  RoutePaths.projectImportSummary: localCopy.importSummaryTitle,
  RoutePaths.captureRoot: localCopy.navCapture,
  RoutePaths.records: localCopy.navRecords,
  RoutePaths.more: localCopy.navMore,
  AppRoutes.lock: localCopy.appLockTitle,
  RoutePaths.signIn: localCopy.signInTitle,
  RoutePaths.templates: localCopy.navTemplates,
  RoutePaths.recycleBin: localCopy.recycleBinTitle,
  RoutePaths.transcripts: localCopy.transcriptsTitle,
  RoutePaths.settingsOperator: localCopy.operatorProfileTitle,
  RoutePaths.settingsRelay: localCopy.relayTitle,
  RoutePaths.settingsCapture: localCopy.settingsCaptureTitle,
  RoutePaths.settingsAi: localCopy.settingsAiTitle,
  RoutePaths.settingsLanguage: localCopy.settingsLanguageTitle,
  RoutePaths.settingsAppearance: localCopy.settingsAppearanceTitle,
  RoutePaths.settingsStorage: localCopy.settingsStorageTitle,
  RoutePaths.settingsFiles: localCopy.settingsFilesTitle,
  RoutePaths.settingsDestinations: localCopy.destinationTitle,
  RoutePaths.settingsUploads: localCopy.uploadHistoryTitle,
  RoutePaths.settingsSecurity: localCopy.appLockTitle,
  RoutePaths.settingsPrivacy: localCopy.privacyScreenTitle,
  RoutePaths.settingsAbout: localCopy.settingsAboutTitle,
  RoutePaths.settingsLicences: localCopy.settingsLicences,
};

String _projectLeaf(List<String> segments, LocalizedCopy localCopy) {
  if (segments.isEmpty) {
    return '';
  }
  return switch (segments.first) {
    'capture' => localCopy.navCapture,
    'context' =>
      segments.length >= 2 && segments[1] == 'presets'
          ? localCopy.contextPresetsTitle
          : localCopy.contextHierarchyTitle,
    'templates' => localCopy.navTemplates,
    'records' =>
      segments.length >= 3 && segments[2] == 'edit'
          ? '${localCopy.navRecords} › ${localCopy.recordEditTitle}'
          : localCopy.navRecords,
    'queue' => localCopy.navQueue,
    'exports' => localCopy.projectExportTitle,
    'datasets' => localCopy.navDatasets,
    'edit' => localCopy.projectEditTitle,
    'settings' =>
      segments.length >= 2 && segments[1] == 'relay'
          ? localCopy.relayTitle
          : localCopy.projectSettingsTitle,
    'details' => localCopy.projectEditTitle,
    'merge' => localCopy.mergePackage,
    'duplicates' => localCopy.duplicatesTitle,
    'variance' => localCopy.varianceTitle,
    'quality' => localCopy.qualitySummaryTitle,
    'review' => localCopy.reviewTitle,
    'transcripts' => switch (segments.length) {
      1 => localCopy.transcriptsTitle,
      _ when segments[1] == 'new' => localCopy.transcribeTitle,
      _ => localCopy.transcriptDetailTitle,
    },
    'meetings' =>
      segments.length >= 3 && segments.last == 'review'
          ? localCopy.meetingReviewTitle
          : localCopy.meetingTitle,
    _ => '',
  };
}
