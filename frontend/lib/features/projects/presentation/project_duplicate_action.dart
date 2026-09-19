import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return AppButton(
      label: Copy.projectsDuplicate,
      variant: AppButtonVariant.secondary,
      onPressed: () => context.go(_location()),
    );
  }

  String _location() {
    return Uri(
      path: '$_projectsRoot/$_newSegment',
      queryParameters: <String, String>{
        _sourceQuery: sourceId,
        _nameQuery: Copy.projectCopyName(sourceName),
      },
    ).toString();
  }
}

/// Must match [AppRoutes.projects], [AppRoutes.sourceQuery] and
/// [AppRoutes.nameQuery]. This file cannot import `router.dart`.
const String _projectsRoot = '/projects';
const String _newSegment = 'new';
const String _sourceQuery = 'source';
const String _nameQuery = 'name';
