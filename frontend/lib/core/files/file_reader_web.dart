import 'package:tapture/core/files/storage_root.dart';

import 'blob_file_reader.dart';
import 'file_reader.dart';
import 'file_writer_web.dart' show projectFileStore;

/// A browser reads its project files from the store [FileWriter] keeps them
/// in. [storageRoot] is a device concern and is not read here.
FileReader openFileReader({required StorageRoot storageRoot}) {
  return BlobFileReader(projectFileStore());
}
