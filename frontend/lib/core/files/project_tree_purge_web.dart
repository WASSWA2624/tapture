import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/file_writer_web.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Removes every durable browser blob belonging to this exact project prefix.
Future<Result<void>> purgeProjectTree(StorageRoot root, String folder) =>
    Result.captureAsync(() async {
      if (folder.isEmpty) {
        return;
      }
      EvidencePurge.cacheKey(folder);
      (await projectFileStore().removeTree('projects/$folder')).getOrThrow();
    });

/// Removes retained undo files without touching another merge's prefix.
Future<Result<void>> purgeMergeTree(StorageRoot root, String id) =>
    Result.captureAsync(() async {
      EvidencePurge.cacheKey(id);
      (await projectFileStore().removeTree('.recycle/merge-$id')).getOrThrow();
    });
