import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/feedback/domain/feedback_origin.dart';
import 'package:tapture/features/projects/projects.dart';

import 'router.dart';

/// Route titles for the shell header and for feedback's screen name.
///
/// Every route names the screen, including the four branch roots. The status
/// line draws a back control only when [isRoot] is false (FE-CONS-02).
abstract final class ShellTitle {
  /// Capture branch. Matches the private path on the router.
  static const String capture = '/capture';

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

  /// Header text for [uri], including branch roots.
  static String? header(WidgetRef ref, Uri uri) {
    return screen(ref, uri);
  }

  /// Screen name for [uri], including branch roots.
  static String screen(WidgetRef ref, Uri uri) {
    final String path = uri.path;
    if (path == AppRoutes.projects || path == '/') {
      return Copy.navProjects;
    }
    if (path == AppRoutes.projectCreate) {
      final String? source = uri.queryParameters[AppRoutes.sourceQuery];
      if (source != null && source.isNotEmpty) {
        return Copy.projectDuplicateTitle;
      }
      return Copy.projectCreateTitle;
    }
    if (path == AppRoutes.records || path.startsWith('${AppRoutes.records}/')) {
      return Copy.navRecords;
    }
    if (path == AppRoutes.more) {
      return Copy.navMore;
    }
    if (path == AppRoutes.lock) {
      return Copy.appLockTitle;
    }
    if (path == AppRoutes.templates) {
      return Copy.navTemplates;
    }
    if (path == AppRoutes.queue) {
      return Copy.navQueue;
    }
    if (path == AppRoutes.settingsOperator) {
      return Copy.operatorProfileTitle;
    }
    if (path == AppRoutes.settingsCapture) {
      return Copy.navCapture;
    }
    if (path == AppRoutes.settingsAppearance) {
      return Copy.settingsAppearanceTitle;
    }
    if (path == AppRoutes.settingsStorage) {
      return Copy.settingsStorageTitle;
    }
    if (path == AppRoutes.settingsSecurity) {
      return Copy.appLockTitle;
    }
    if (path == AppRoutes.settingsAbout) {
      return Copy.settingsAboutTitle;
    }
    if (path == AppRoutes.settingsLicences) {
      return Copy.settingsLicences;
    }
    if (path == capture) {
      return Copy.navCapture;
    }
    if (path.startsWith('${AppRoutes.projects}/')) {
      return ref.watch(currentProjectDetailsProvider)?.name ?? Copy.navProjects;
    }
    return FeedbackOrigin.unknown.screen;
  }

  /// Path with the last segment removed. A single segment returns Projects.
  static String parentOf(String path) {
    final List<String> parts = path
        .split('/')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    if (parts.length <= 1) {
      return AppRoutes.projects;
    }
    parts.removeLast();
    return '/${parts.join('/')}';
  }
}
