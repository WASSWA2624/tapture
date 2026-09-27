import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/file_writer_web.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'package_files.dart';

/// A browser keeps project files in its one IndexedDB store, the one the
/// project's writer and reader use.
PackageFiles openPackageFiles({
  required StorageRoot storageRoot,
  FileWriter? writer,
}) {
  return PackageFiles.blobs(projectFileStore(), writer: writer);
}
