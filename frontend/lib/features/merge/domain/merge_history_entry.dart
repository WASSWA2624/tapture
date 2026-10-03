/// Durable facts about an import or merge and its retained undo snapshot.
final class MergeHistoryEntry {
  /// Copies the summary maps so callers cannot mutate persisted view state.
  MergeHistoryEntry({
    required this.id,
    required this.projectId,
    required this.bundleId,
    required this.bundleName,
    required this.sourceDevice,
    required this.at,
    required this.status,
    required Map<String, int> counts,
    required Map<String, int> resolutions,
    this.undoUntil,
  }) : counts = Map<String, int>.unmodifiable(counts),
       resolutions = Map<String, int>.unmodifiable(resolutions);

  /// Durable merge session identifier.
  final String id;

  /// Project that received the package.
  final String projectId;

  /// Identifier written in the package manifest.
  final String bundleId;

  /// Original package filename, treated as data.
  final String bundleName;

  /// Device that produced the incoming package.
  final String sourceDevice;

  /// When the import or merge committed.
  final DateTime at;

  /// Imported, applied, undone or failed.
  final String status;

  /// Entity counts per merge category.
  final Map<String, int> counts;

  /// Conflict counts per operator choice, including deferred choices.
  final Map<String, int> resolutions;

  /// Deadline while a retained snapshot can still be used.
  final DateTime? undoUntil;
}
