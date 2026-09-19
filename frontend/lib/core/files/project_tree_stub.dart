import 'package:tapture/core/errors/result.dart';

/// Web stand-in: the project folder tree is a native filesystem.
Future<Result<void>> writeProjectTree({
  required String id,
  required String name,
  required String folderName,
}) async {
  return const Success<void>(null);
}

/// Web stand-in: there is no folder tree to remove.
Future<Result<void>> discardProjectTree({
  required String id,
  required String name,
  required String folderName,
}) async {
  return const Success<void>(null);
}

/// Web stand-in: there is no folder tree to recycle.
Future<Result<void>> recycleProjectTree({
  required String id,
  required String name,
  required String folderName,
}) async {
  return const Success<void>(null);
}
