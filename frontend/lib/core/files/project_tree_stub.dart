import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Web stand-in: the project folder tree is a native filesystem.
Future<Result<void>> writeProjectTree({
  required String id,
  required String name,
  required String folderName,
  StorageRoot? storageRoot,
}) async {
  return const Success<void>(null);
}

/// Web stand-in: there is no folder tree to remove.
Future<Result<void>> discardProjectTree({
  required String id,
  required String name,
  required String folderName,
  StorageRoot? storageRoot,
}) async {
  return const Success<void>(null);
}

/// Web stand-in: there is no folder tree to recycle.
Future<Result<void>> recycleProjectTree({
  required String id,
  required String name,
  required String folderName,
  StorageRoot? storageRoot,
}) async {
  return const Success<void>(null);
}
