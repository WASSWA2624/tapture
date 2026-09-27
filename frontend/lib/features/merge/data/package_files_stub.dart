import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/file_writer_stub.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'package_files.dart';

/// Neither a file system nor a browser: the files the other writers hold in
/// memory for this run.
PackageFiles openPackageFiles({
  required StorageRoot storageRoot,
  FileWriter? writer,
}) {
  return PackageFiles.blobs(projectFileStore(), writer: writer);
}
