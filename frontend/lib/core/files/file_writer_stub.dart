import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'blob_file_writer.dart';
import 'file_writer.dart';

/// Neither a file system nor a browser: the project files are held in
/// memory for this run. The writer and the reader share them.
BlobStore projectFileStore() => _projectFiles;

final BlobStore _projectFiles = BlobStore.memory();

/// Neither a file system nor a browser: files are held in memory.
FileWriter openFileWriter({
  required StorageRoot storageRoot,
  int? failAfterBytes,
  bool fullDisk = false,
  bool permissionDenied = false,
  bool vanishedParent = false,
}) {
  return BlobFileWriter(projectFileStore());
}
