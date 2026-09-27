/// One photo path a renamer may move (task 018).
final class RenameablePhoto {
  /// Creates a photo row.
  RenameablePhoto({
    required this.recordId,
    required this.path,
    required this.type,
    required this.sequence,
    this.originalName = '',
    this.provisional = true,
    List<String>? references,
  }) : references = references ?? <String>[path];

  /// Record the photo belongs to.
  final String recordId;

  /// Current stored path.
  String path;

  /// Photo type token.
  final String type;

  /// Sequence on the record.
  final int sequence;

  /// Name before the first rename. Never cleared.
  String originalName;

  /// Whether the name is still provisional.
  bool provisional;

  /// Paths that must keep resolving, including this photo's own path.
  final List<String> references;

  /// Previous paths, oldest first.
  final List<String> history = <String>[];
}
