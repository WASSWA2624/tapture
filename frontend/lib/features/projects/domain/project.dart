import 'project_settings.dart';
import 'project_status.dart';

/// Identity, listing status, dates and on-disk folder of a field project.
///
/// [folderName] is set at creation and has no setter: a rename of [name]
/// must not move files.
final class Project {
  /// Creates a project. [folderName] is stored as given and never
  /// recomputed from [name].
  const Project({
    required this.id,
    required this.name,
    required this.status,
    required this.folderName,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.organisation,
    this.startsOn,
    this.endsOn,
  });

  /// Merge identity. Stable across a rename.
  final String id;

  /// Display name. Changing this must not rewrite [folderName].
  final String name;

  /// Optional longer note shown on the project details screen.
  final String? description;

  /// Client or organisation the project is for.
  final String? organisation;

  /// Open, archived or soft-deleted.
  final ProjectStatus status;

  /// When fieldwork started, if known.
  final DateTime? startsOn;

  /// When fieldwork finished, if known.
  final DateTime? endsOn;

  /// On-disk folder. Stored at creation and never recomputed on read.
  final String folderName;

  /// Project-scoped switches persisted as the row's settings JSON.
  final ProjectSettings settings;

  /// When the row was first written.
  final DateTime createdAt;

  /// When the row last changed.
  final DateTime updatedAt;

  /// Returns a copy with the provided fields replaced. [folderName] and
  /// [id] stay put.
  Project copyWith({
    String? name,
    String? description,
    String? organisation,
    ProjectStatus? status,
    DateTime? startsOn,
    DateTime? endsOn,
    ProjectSettings? settings,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      folderName: folderName,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description ?? this.description,
      organisation: organisation ?? this.organisation,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    organisation,
    status,
    startsOn,
    endsOn,
    folderName,
    settings,
    createdAt,
    updatedAt,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Project &&
            other.id == id &&
            other.name == name &&
            other.description == description &&
            other.organisation == organisation &&
            other.status == status &&
            other.startsOn == startsOn &&
            other.endsOn == endsOn &&
            other.folderName == folderName &&
            other.settings == settings &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt);
  }
}
