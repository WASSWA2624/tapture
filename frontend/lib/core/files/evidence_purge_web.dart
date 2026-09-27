import 'package:tapture/core/files/storage_root.dart';

import 'evidence_purge.dart';
import 'file_writer_web.dart' show projectFileStore;

/// A browser keeps its evidence in the project-file store, keyed by path
/// under the storage root, so the purge removes those keys. [storageRoot]
/// is a device concern and is not read here.
EvidencePurge openEvidencePurge({required StorageRoot storageRoot}) {
  return EvidencePurge.store(projectFileStore());
}
