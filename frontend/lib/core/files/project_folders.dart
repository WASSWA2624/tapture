import 'dart:io';

import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

export 'package:tapture/core/files/path_sanitizer.dart' show folderNameFor;

/// Creates and resolves the per-project folder tree under the storage root.
abstract interface class ProjectFolders {
  /// Writes under [storageRoot]. Tests pass [StorageRoot.fake].
  factory ProjectFolders({required StorageRoot storageRoot}) {
    return _ProjectFolders(storageRoot);
  }

  /// Creates `photos/`, `documents/`, `audio/`, `meetings/`, `reference/`,
  /// `templates/`, `exports/` and `imports/` under the project's folder.
  /// Idempotent: a second call leaves existing files in place.
  Future<Result<Directory>> create(Project project);

  /// The stored [Project.folderName] under the storage root. A rename of
  /// [Project.name] does not move this directory.
  Future<Result<Directory>> resolve(Project project);

  /// Removes the project folder after a failed create so no partial tree
  /// remains. Missing folders succeed.
  Future<Result<void>> discard(Project project);

  /// Moves the project folder into the recycle area. Missing folders
  /// succeed. Never unlinks a file.
  Future<Result<Directory>> recycle(Project project);
}

final class _ProjectFolders implements ProjectFolders {
  _ProjectFolders(this._storageRoot);

  final StorageRoot _storageRoot;

  @override
  Future<Result<Directory>> create(Project project) async {
    return _open(project, createTree: true);
  }

  @override
  Future<Result<Directory>> resolve(Project project) async {
    return _open(project, createTree: false);
  }

  @override
  Future<Result<void>> discard(Project project) async {
    try {
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final Failure failure):
          return FailureResult<void>(failure);
        case Success<Directory>(:final Directory value):
          final String folderName = project.folderName.trim();
          if (folderName.isEmpty) {
            return const Success<void>(null);
          }
          _assertSafeFolderName(folderName);
          final Directory projectDir = Directory(
            '${value.path}/$_projects/$folderName',
          );
          if (projectDir.existsSync()) {
            await projectDir.delete(recursive: true);
          }
          return const Success<void>(null);
      }
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The project folder could not be removed from this device.',
          recoveryAction: 'Delete the leftover folder, then try again.',
        ),
      );
    }
  }

  @override
  Future<Result<Directory>> recycle(Project project) async {
    try {
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final Failure failure):
          return FailureResult<Directory>(failure);
        case Success<Directory>(:final Directory value):
          final String folderName = project.folderName.trim();
          if (folderName.isEmpty) {
            return Success<Directory>(Directory('${value.path}/$_recycle'));
          }
          _assertSafeFolderName(folderName);
          final Directory source = Directory(
            '${value.path}/$_projects/$folderName',
          );
          final Directory dest = Directory(
            '${value.path}/$_recycle/$folderName',
          );
          if (!source.existsSync()) {
            return Success<Directory>(dest);
          }
          if (dest.existsSync()) {
            return const FailureResult<Directory>(
              StorageFailure(
                message:
                    'That project is already in the recycle area on this device.',
                recoveryAction:
                    'Restore it from the recycle area, then try again.',
              ),
            );
          }
          await dest.parent.create(recursive: true);
          await source.rename(dest.path);
          return Success<Directory>(dest);
      }
    } on Failure catch (failure) {
      return FailureResult<Directory>(failure);
    } on Object {
      return const FailureResult<Directory>(
        StorageFailure(
          message: 'The project folder could not be moved to the recycle area.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  Future<Result<Directory>> _open(
    Project project, {
    required bool createTree,
  }) async {
    try {
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<Directory>(failure);
        case Success<Directory>(:final value):
          final String stored = project.folderName.trim();
          if (!createTree && stored.isEmpty) {
            return const FailureResult<Directory>(
              ValidationFailure(
                message: 'This project has no folder on disk yet.',
                recoveryAction: 'Create the project folder, then try again.',
              ),
            );
          }
          final String folderName = stored.isEmpty
              ? _derivedFolderName(project)
              : stored;
          _assertSafeFolderName(folderName);
          final Directory projectDir = Directory(
            '${value.path}/$_projects/$folderName',
          );
          if (createTree) {
            await projectDir.create(recursive: true);
            for (final String child in _tree) {
              await Directory(
                '${projectDir.path}/$child',
              ).create(recursive: true);
            }
          } else if (!projectDir.existsSync()) {
            return FailureResult<Directory>(_missing(projectDir.path));
          }
          return Success<Directory>(projectDir);
      }
    } on Failure catch (failure) {
      return FailureResult<Directory>(failure);
    } on Object {
      return const FailureResult<Directory>(
        StorageFailure(
          message: 'The project folder could not be created on this device.',
          recoveryAction: 'Free space or allow storage access, then try again.',
        ),
      );
    }
  }

  String _derivedFolderName(Project project) {
    return folderNameFor(name: project.name, id: project.id);
  }
}

void _assertSafeFolderName(String folderName) {
  if (folderName.isEmpty ||
      folderName.contains('/') ||
      folderName.contains(r'\') ||
      folderName.contains('..') ||
      folderName.startsWith('.') ||
      _drive.hasMatch(folderName)) {
    throw const ValidationFailure(
      message: 'That project folder name is not a valid folder.',
      recoveryAction: 'Recreate the project so its folder can be rebuilt.',
    );
  }
}

StorageFailure _missing(String path) {
  return StorageFailure(
    message: 'Tapture could not find $path.',
    recoveryAction: 'Recreate the project folder, then try again.',
  );
}

final RegExp _drive = RegExp(r'^[A-Za-z]:');

const String _projects = 'projects';

const String _recycle = '.recycle';

const List<String> _tree = <String>[
  'photos',
  'documents',
  'audio',
  'meetings',
  'reference',
  'templates',
  'exports',
  'imports',
];
