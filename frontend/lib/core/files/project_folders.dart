import 'dart:io';

import 'package:tapture/core/copy/copy.dart';
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

  /// Restores a managed tree without replacing a live path. A retry after a
  /// successful move succeeds; a missing tree or path collision remains an error.
  Future<Result<Directory>> restore(Project project);
}

final class _ProjectFolders implements ProjectFolders {
  _ProjectFolders(this._storageRoot);

  final StorageRoot _storageRoot;

  @override
  Future<Result<Directory>> restore(Project project) async {
    try {
      final Result<Directory> resolved = await _storageRoot.resolve();
      if (resolved case FailureResult<Directory>(:final failure)) {
        return FailureResult<Directory>(failure);
      }
      final Directory root = (resolved as Success<Directory>).value;
      final String folder = project.folderName.trim();
      if (folder.isEmpty) return Success<Directory>(root);
      _assertSafeFolderName(folder);
      final Directory recycled = Directory('${root.path}/$_recycle');
      final Directory live = Directory('${root.path}/$_projects');
      // Reject links before following a path, including either managed parent.
      for (final Directory parent in <Directory>[recycled, live]) {
        await _assertDirectoryOrAbsent(parent.path);
      }
      final Directory source = Directory('${recycled.path}/$folder');
      final Directory destination = Directory('${live.path}/$folder');
      final FileSystemEntityType sourceType = await _assertDirectoryOrAbsent(
        source.path,
      );
      final FileSystemEntityType destinationType =
          await _assertDirectoryOrAbsent(destination.path);
      if (sourceType == FileSystemEntityType.notFound) {
        if (destinationType == FileSystemEntityType.directory) {
          return Success<Directory>(destination);
        }
        return FailureResult<Directory>(_missing(source.path));
      }
      if (destinationType != FileSystemEntityType.notFound) {
        throw _restoreFailure();
      }
      await live.create();
      await source.rename(destination.path);
      return Success<Directory>(destination);
    } on Failure catch (failure) {
      return FailureResult<Directory>(failure);
    } on Object {
      return FailureResult<Directory>(_restoreFailure());
    }
  }

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
      return FailureResult<void>(
        StorageFailure(
          localizedMessage:
              Copy.messages.failureTheProjectFolderCouldNotBeRemoved,
          localizedRecovery:
              Copy.messages.failureDeleteTheLeftoverFolderThenTryAgain,
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
            return FailureResult<Directory>(
              StorageFailure(
                localizedMessage:
                    Copy.messages.failureThatProjectIsAlreadyInTheRecycle,
                localizedRecovery:
                    Copy.messages.failureRestoreItFromTheRecycleAreaThen,
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
      return FailureResult<Directory>(
        StorageFailure(
          localizedMessage:
              Copy.messages.failureTheProjectFolderCouldNotBeMoved,
          localizedRecovery:
              Copy.messages.failureFreeSpaceOrAllowStorageAccessThen,
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
            return FailureResult<Directory>(
              ValidationFailure(
                localizedMessage:
                    Copy.messages.failureThisProjectHasNoFolderOnDisk,
                localizedRecovery:
                    Copy.messages.failureCreateTheProjectFolderThenTryAgain,
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
      return FailureResult<Directory>(
        StorageFailure(
          localizedMessage:
              Copy.messages.failureTheProjectFolderCouldNotBeCreated,
          localizedRecovery:
              Copy.messages.failureFreeSpaceOrAllowStorageAccessThen,
        ),
      );
    }
  }

  String _derivedFolderName(Project project) {
    return folderNameFor(name: project.name, id: project.id);
  }
}

Future<FileSystemEntityType> _assertDirectoryOrAbsent(String path) async {
  final FileSystemEntityType type = await FileSystemEntity.type(
    path,
    followLinks: false,
  );
  if (type != FileSystemEntityType.directory &&
      type != FileSystemEntityType.notFound) {
    throw _restoreFailure();
  }
  return type;
}

StorageFailure _restoreFailure() => StorageFailure(
  localizedMessage: Copy.messages.recycleFolderRestoreFailed,
  localizedRecovery: Copy.messages.recycleFolderRestoreRecovery,
);

void _assertSafeFolderName(String folderName) {
  if (folderName.isEmpty ||
      folderName.contains('/') ||
      folderName.contains(r'\') ||
      folderName.contains('..') ||
      folderName.startsWith('.') ||
      _drive.hasMatch(folderName)) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatProjectFolderNameIsNotA,
      localizedRecovery: Copy.messages.failureRecreateTheProjectSoItsFolderCan,
    );
  }
}

StorageFailure _missing(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotFindValue(
      (path).toString(),
    ),
    localizedRecovery:
        Copy.messages.failureRecreateTheProjectFolderThenTryAgain,
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
