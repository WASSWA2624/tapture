import 'package:tapture/core/files/storage_root.dart';

import 'evidence_purge.dart';
import 'file_writer_stub.dart' show projectFileStore;

/// Neither a file system nor a browser: the purge removes from the
/// in-memory project files the writer keeps for this run.
EvidencePurge openEvidencePurge({required StorageRoot storageRoot}) {
  return EvidencePurge.store(projectFileStore());
}
