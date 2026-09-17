import 'dart:io';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/storage_root.dart';

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
    final String base = sanitiseSegment(project.name);
    return '${base}__${_idSuffix(project.id)}';
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

String _idSuffix(String id) {
  final String hex = id.replaceAll(_notAlnum, '');
  final int length = AppConstants.folders.idSuffixLength;
  if (hex.length <= length) {
    return hex.padLeft(length, '0').toLowerCase();
  }
  return hex.substring(hex.length - length).toLowerCase();
}

StorageFailure _missing(String path) {
  return StorageFailure(
    message: 'Tapture could not find $path.',
    recoveryAction: 'Recreate the project folder, then try again.',
  );
}

final RegExp _drive = RegExp(r'^[A-Za-z]:');
final RegExp _notAlnum = RegExp(r'[^A-Za-z0-9]');

const String _projects = 'projects';

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
