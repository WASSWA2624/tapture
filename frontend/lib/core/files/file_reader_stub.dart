import 'package:tapture/core/files/storage_root.dart';

import 'blob_file_reader.dart';
import 'file_reader.dart';
import 'file_writer_stub.dart' show projectFileStore;

/// Neither a file system nor a browser: reads what the in-memory writer
/// holds for this run.
FileReader openFileReader({required StorageRoot storageRoot}) {
  return BlobFileReader(projectFileStore());
}
