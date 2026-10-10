import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Unsupported platforms have no project files.
Future<Result<void>> purgeProjectTree(StorageRoot root, String folder) async =>
    const Success<void>(null);

/// Unsupported platforms have no retained merge files.
Future<Result<void>> purgeMergeTree(StorageRoot root, String id) async =>
    const Success<void>(null);
