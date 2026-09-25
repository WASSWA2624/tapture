import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The template the home switcher last chose. Empty until the person picks.
final NotifierProvider<ProjectTemplateSelection, String>
projectTemplateSelectionProvider =
    NotifierProvider<ProjectTemplateSelection, String>(
      ProjectTemplateSelection.new,
      retry: (int _, Object _) => null,
    );

/// Ephemeral template choice for the open project (FE-STATE-02).
final class ProjectTemplateSelection extends Notifier<String> {
  @override
  String build() => '';

  /// Remembers [id] so capture can apply it.
  void select(String id) => state = id;
}
