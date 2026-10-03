import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Opens the create form with a suggested, editable copy name.
class ProjectDuplicateAction extends StatelessWidget {
  /// Creates the action for [sourceId] named [sourceName].
  const ProjectDuplicateAction({
    super.key,
    required this.sourceId,
    required this.sourceName,
  });

  /// Project whose structure is copied.
  final String sourceId;

  /// Display name used to build the suggested copy name.
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppButton(
      label: localCopy.projectsDuplicate,
      variant: AppButtonVariant.secondary,
      onPressed: () =>
          open(context, sourceId: sourceId, sourceName: sourceName),
    );
  }

  /// Opens the create form prefilled from [sourceId] named [sourceName].
  static void open(
    BuildContext context, {
    required String sourceId,
    required String sourceName,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    context.go(
      Uri(
        path: RoutePaths.projectCreate,
        queryParameters: <String, String>{
          RoutePaths.sourceQuery: sourceId,
          RoutePaths.nameQuery: localCopy.projectCopyName(sourceName),
        },
      ).toString(),
    );
  }
}
