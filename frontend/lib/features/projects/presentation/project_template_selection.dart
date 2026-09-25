import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_project.dart';

/// The template the home switcher last chose. Empty until the person picks.
final NotifierProvider<ProjectTemplateSelection, String>
projectTemplateSelectionProvider =
    NotifierProvider<ProjectTemplateSelection, String>(
      ProjectTemplateSelection.new,
      retry: (int _, Object _) => null,
    );

/// Ephemeral template choice for the open project (FE-STATE-02). Opening
/// another project clears it, so one project's template never applies to
/// another (FE-STATE-06).
final class ProjectTemplateSelection extends Notifier<String> {
  @override
  String build() {
    ref.watch(currentProjectProvider);
    return '';
  }

  /// Remembers [id] so capture can apply it.
  void select(String id) => state = id;
}
