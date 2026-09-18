import 'blob_store.dart';

/// Neither a file system nor a browser: the in-memory store is all there is.
BlobStore openBlobStore(String name) {
  assert(name.isNotEmpty, 'a store needs a name');
  return BlobStore.memory();
}
