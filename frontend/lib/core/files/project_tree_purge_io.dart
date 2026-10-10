import 'dart:io';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Removes only a validated project's live/recycled trees. Missing trees retry safely.
Future<Result<void>> purgeProjectTree(StorageRoot root, String folder) =>
    Result.captureAsync(() async {
      if (folder.isEmpty) {
        return;
      }
      // Apply the evidence path policy before resolving any filesystem path.
      EvidencePurge.evidencePath('projects/$folder/photos/probe');
      if (folder.contains('/') ||
          folder.contains(r'\') ||
          folder.startsWith('.')) {
        throw const FileSystemException('Invalid project folder');
      }
      (await _purgeDirectories(root, <(String, String)>[
        ('projects', folder),
        ('.recycle', folder),
      ])).getOrThrow();
    });

/// Purges retained merge undo evidence owned by a permanently removed project.
Future<Result<void>> purgeMergeTree(StorageRoot root, String id) =>
    Result.captureAsync(() async {
      EvidencePurge.cacheKey(id);
      (await _purgeDirectories(root, <(String, String)>[
        ('.recycle', 'merge-$id'),
      ])).getOrThrow();
    });

Future<Result<void>> _purgeDirectories(
  StorageRoot root,
  List<(String, String)> directories,
) => Result.captureAsync(() async {
  final Directory directory = (await root.resolve()).getOrThrow();
  final List<String> targets = <String>[];
  for (final (String parent, String folder) in directories) {
    final String base = '${directory.path}/$parent';
    final String target = '$base/$folder';
    for (final String path in <String>[base, target]) {
      final FileSystemEntityType type = await FileSystemEntity.type(
        path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound &&
          type != FileSystemEntityType.directory) {
        throw FileSystemException(
          'Project path is not a managed directory',
          path,
        );
      }
    }
    targets.add(target);
  }
  for (final String target in targets) {
    if (await Directory(target).exists()) {
      await Directory(target).delete(recursive: true);
    }
  }
});
