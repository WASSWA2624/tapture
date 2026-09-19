import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the landing list includes archived projects.
final class ProjectListFilter extends Notifier<bool> {
  /// Starts with archived projects hidden.
  @override
  bool build() => false;

  /// Shows or hides archived projects on the landing list.
  void set(bool value) => state = value;
}

/// Filter the landing list reads. Off by default so archived rows stay
/// hidden until the operator asks.
final NotifierProvider<ProjectListFilter, bool>
projectListShowArchivedProvider = NotifierProvider<ProjectListFilter, bool>(
  ProjectListFilter.new,
  retry: (int _, Object _) => null,
);
