import 'deleted_entity_kind.dart';

export 'deleted_entity_kind.dart';

/// A repository-owned deleted entity; storage paths and database rows stay private.
final class DeletedEntity {
  /// Creates a projection of a recoverable entity without exposing its storage.
  const DeletedEntity({
    required this.id,
    required this.kind,
    required this.name,
    required this.projectId,
    required this.projectName,
    required this.deletedAt,
    this.reason = '',
  });

  /// Stable identifier within the owning repository.
  final String id;

  /// Entity category used for labels and restoration dispatch.
  final DeletedEntityKind kind;

  /// Human-readable name of the deleted entity.
  final String name;

  /// Identifier of the project that owns the entity.
  final String projectId;

  /// Human-readable name of the owning project.
  final String projectName;

  /// Time at which the original tombstone was written.
  final DateTime deletedAt;

  /// Original deletion reason retained by the repository.
  final String reason;

  /// Stable activity identity even if two tables contain the same id.
  String get key => '${kind.name}:$id';
}
