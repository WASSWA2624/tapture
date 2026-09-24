import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';

/// Template paths that stay inside the branch that opened them.
abstract final class TemplateLocations {
  /// Project id carried by the current template route, when there is one.
  static String? projectIdOf(BuildContext context) {
    final String path = GoRouterState.of(context).uri.path;
    final Match? match = RegExp(
      r'^/projects/([^/]+)/templates(?:/|$)',
    ).firstMatch(path);
    if (match == null) {
      return null;
    }
    return Uri.decodeComponent(match.group(1)!);
  }

  static String root(BuildContext context, {String? projectId}) {
    return RoutePaths.templateRoot(projectId: projectId ?? projectIdOf(context));
  }

  static String create(BuildContext context, {String? projectId}) {
    return RoutePaths.templateCreate(
      projectId: projectId ?? projectIdOf(context),
    );
  }

  static String library(BuildContext context, {String? projectId}) {
    return RoutePaths.templateLibrary(
      projectId: projectId ?? projectIdOf(context),
    );
  }

  static String import(BuildContext context, {String? projectId}) {
    return RoutePaths.templateImport(
      projectId: projectId ?? projectIdOf(context),
    );
  }

  static String detail(
    BuildContext context,
    String templateId, {
    String? projectId,
  }) {
    return RoutePaths.templateDetail(
      templateId,
      projectId: projectId ?? projectIdOf(context),
    );
  }

  static String child(
    BuildContext context,
    String templateId,
    String segment, {
    String? projectId,
  }) {
    return '${detail(context, templateId, projectId: projectId)}/$segment';
  }
}
