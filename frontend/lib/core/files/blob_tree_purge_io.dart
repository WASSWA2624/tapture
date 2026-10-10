import 'dart:io';

import 'blob_store.dart';

/// Removes a validated blob subtree beneath a trusted store root.
/// Rejects links in every parent and never follows links during recursion.
Future<void> purgeBlobTree(Directory root, String prefix) async {
  if (!BlobStore.isValidKey(prefix)) {
    throw const FileSystemException('Invalid stored tree');
  }
  String target = root.absolute.path;
  for (final String part in prefix.split('/')) {
    target = '$target/$part';
    final FileSystemEntityType type = await FileSystemEntity.type(
      target,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link) {
      throw const FileSystemException('Stored tree contains a link');
    }
  }
  final FileSystemEntityType type = await FileSystemEntity.type(
    target,
    followLinks: false,
  );
  if (type == FileSystemEntityType.directory) {
    await Directory(target).delete(recursive: true);
  } else if (type == FileSystemEntityType.file) {
    await File(target).delete();
  }
}
