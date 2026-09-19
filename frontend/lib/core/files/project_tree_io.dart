import 'dart:io';

import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Creates the eight-folder tree through [ProjectFolders] (FE-STR-11).
Future<Result<void>> writeProjectTree({
  required String id,
  required String name,
  required String folderName,
}) async {
  final Result<Directory> created = await ProjectFolders(
    storageRoot: StorageRoot(),
  ).create(_row(id: id, name: name, folderName: folderName));
  return created.map((Directory _) {});
}

/// Removes a half-written tree so a failed create leaves nothing behind.
Future<Result<void>> discardProjectTree({
  required String id,
  required String name,
  required String folderName,
}) {
  return ProjectFolders(
    storageRoot: StorageRoot(),
  ).discard(_row(id: id, name: name, folderName: folderName));
}

/// Moves a project folder into the recycle area. Missing folders succeed.
Future<Result<void>> recycleProjectTree({
  required String id,
  required String name,
  required String folderName,
}) async {
  final Result<Directory> moved = await ProjectFolders(
    storageRoot: StorageRoot(),
  ).recycle(_row(id: id, name: name, folderName: folderName));
  return moved.map((Directory _) {});
}

Project _row({
  required String id,
  required String name,
  required String folderName,
}) {
  final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return Project(
    id: id,
    createdAt: epoch,
    updatedAt: epoch,
    updatedByDevice: '',
    rev: 1,
    name: name,
    client: '',
    status: ProjectStatus.active,
    folderName: folderName,
    settings: '{}',
  );
}
