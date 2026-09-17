# 226 — S3, WebDAV and folder destinations

**Phase** 21 · Cloud upload  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [065](../05-file-storage/065-storage-root.md), [224](224-destination-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three `CloudDestination` backends that need no OAuth: an S3-compatible bucket with user-supplied keys, a WebDAV or
generic HTTPS endpoint with basic or token authentication, and a folder on the device or an SD card chosen with the
system picker.

## Files

- `frontend/lib/core/cloud/s3_destination.dart` (new)
- `frontend/lib/core/cloud/webdav_destination.dart` (new)
- `frontend/lib/core/cloud/local_destination.dart` (new)

## Steps

1. S3 fields: access key, secret, region, bucket, optional prefix, optional endpoint. Sign requests for the
   configured endpoint so non-AWS stores work, and support multipart upload for large files.
2. WebDAV fields: base URL plus basic or bearer credentials. `PUT` the object, creating the collection when absent,
   and treat a redirect to a different host as a failure rather than following it.
3. Local folder: hold the picker's persisted directory grant, resolve paths through the storage root (115), and write
   through a temporary name then rename so an interruption leaves no partial file.
4. Each backend's `check` writes then deletes a small probe object, so a wrong key, bucket, URL or revoked folder
   grant is caught before a real upload.
5. Map provider errors onto the shared failures: unreachable and 5xx are retryable, 401/403 and a missing bucket are
   not.

## Constraints

- HTTP clients stay inside `core/cloud/`; each call reads its credential from secure storage rather than caching it in
  a field (FE-SEC-01, FE-SEC-03).
- A signing, WebDAV or picker package goes through the dependency allowlist (task 005) before it is added.
- The folder backend makes no network call at all and streams file bytes rather than reading them whole (FE-PERF-07).

## Definition of done

- [ ] A test upload of a small file proves each configuration before any real upload is offered.
- [ ] The folder destination completes with the device fully offline, and works on removable storage.
- [ ] A cancelled or failed send leaves no partial object at the destination and no partial file in the folder.
- [ ] Tests: unit tests of `s3_destination.dart`, `webdav_destination.dart` and `local_destination.dart` against
      fakes, covering signature and auth headers, multipart resume from an offset, retryable versus fatal failures,
      and cancellation.
