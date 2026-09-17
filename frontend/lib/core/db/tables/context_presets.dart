part of 'context.dart';

/// A named snapshot of context values for one project.
@DataClassName('ContextPreset')
class ContextPresets extends Table with MergeColumns {
  /// Operator-facing name of the snapshot.
  TextColumn get name => text()();

  /// Project that owns this snapshot.
  TextColumn get projectId => text()();

  /// Values JSON. An object, stored as text.
  TextColumn get values => text()();
}
