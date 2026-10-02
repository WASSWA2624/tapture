import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:tapture/core/concurrency/cooperative_cancellation.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/concurrency/worker_cancellation.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_validation.dart';

import 'bundle_archive_stream.dart';
import 'bundle_entry.dart';

/// Owns a native package's bounded extraction worker and sandbox entry lease.
/// The parent creates [scratch] so killing a worker cannot orphan plaintext.
final class NativeBundleEntries {
  /// Reads [source] using expected manifest [entries], owning [scratch] until
  /// [close]. [inventory] reuses checked inspection offsets. Only one stream or
  /// extraction can be active at a time.
  NativeBundleEntries({
    required this.source,
    required this.scratch,
    required List<BundleEntry> entries,
    Map<String, BundleZipEntry>? inventory,
  }) : _entries = <String, BundleEntry>{
         for (final BundleEntry entry in entries) entry.path: entry,
       },
       _inventory = inventory == null
           ? null
           : Map<String, BundleZipEntry>.unmodifiable(inventory);

  /// Validated archive path, possibly a decrypted copy under [scratch].
  final String source;

  /// Parent-owned, generated temporary directory.
  final Directory scratch;
  final Map<String, BundleEntry> _entries;
  Map<String, BundleZipEntry>? _inventory;
  final CancellationToken _cancel = CancellationToken();
  Future<Result<Stream<List<int>>>>? _opening;
  _EntryFileStream? _active;
  bool _closed = false;
  int _sequence = 0;
  int _directoryReads = 0;

  /// Additional directory reads after inspection. Direct constructor callers
  /// need one lazy inventory; inspected bundles reuse the already-checked map.
  int get debugDirectoryReads => _directoryReads;

  /// Opens a checksum-verified stream backed by one bounded worker extraction.
  Future<Result<Stream<List<int>>>> openEntry(String path) {
    if (_closed) {
      return Future<Result<Stream<List<int>>>>.value(
        const FailureResult<Stream<List<int>>>(CancelledFailure()),
      );
    }
    if (_opening != null || _active != null) {
      return Future<Result<Stream<List<int>>>>.value(
        FailureResult<Stream<List<int>>>(
          ValidationFailure(
            localizedMessage:
                Copy.messages.failureFinishReadingTheCurrentPackageEntryFirst,
          ),
        ),
      );
    }
    final BundleEntry? entry = _entries[path];
    if (entry == null) {
      return Future<Result<Stream<List<int>>>>.value(
        FailureResult<Stream<List<int>>>(
          CorruptionFailure(
            localizedMessage: Copy.messages.failureThePackageEntryIsMissing,
          ),
        ),
      );
    }
    return _opening = _open(entry).whenComplete(() => _opening = null);
  }

  Future<Result<Stream<List<int>>>> _open(BundleEntry entry) async {
    final Directory directory = Directory(
      '${scratch.path}/entry-${++_sequence}',
    );
    bool keep = false;
    CooperativeCancellation? cancellation;
    try {
      await directory.create();
      final File lease = await File(
        '${directory.path}/active',
      ).create(exclusive: true);
      cancellation = CooperativeCancellation(
        _cancel,
        signal: () => lease.deleteSync(),
      );
      if (_inventory == null) {
        _directoryReads++;
        final Result<Map<String, BundleZipEntry>> inventory =
            await runIsolate<List<Object>, Map<String, BundleZipEntry>>(
              _readInventory,
              <Object>[source, cancellation.handshake, lease.path],
            );
        _inventory = Map<String, BundleZipEntry>.unmodifiable(
          inventory.getOrThrow(),
        );
      }
      if (_cancel.isCancelled) throw const CancelledFailure();
      final BundleZipEntry? checked = _inventory![entry.path];
      if (checked == null ||
          checked.path != entry.path ||
          checked.size != entry.byteLength) {
        throw CorruptionFailure(
          localizedMessage: Copy.messages.failureThePackageEntryChanged,
        );
      }
      final String target = '${directory.path}/payload';
      final Result<void> extracted = await runIsolate<List<Object>, void>(
        _extractEntry,
        <Object>[
          source,
          checked,
          entry.sha256,
          target,
          cancellation.handshake,
          lease.path,
        ],
      );
      if (extracted is FailureResult<void>) {
        return FailureResult<Stream<List<int>>>(extracted.failure);
      }
      if (_closed) {
        return const FailureResult<Stream<List<int>>>(CancelledFailure());
      }
      final _EntryFileStream active = _EntryFileStream(
        File(target),
        directory,
        () => _active = null,
      );
      _active = active;
      keep = true;
      return Success<Stream<List<int>>>(active.stream);
    } on Object catch (error) {
      return FailureResult<Stream<List<int>>>(Failure.from(error));
    } finally {
      cancellation?.close();
      if (!keep && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  /// Compatibility read for small entries. Production file imports use
  /// [openEntry], so a 4 GB attachment never takes this byte-buffering path.
  Future<Result<Uint8List>> readEntry(String path) async {
    if ((_entries[path]?.byteLength ?? 0) >
        AppConstants.imports.bundleMaxBytes) {
      return FailureResult<Uint8List>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureReadThisLargePackageEntryAsA,
        ),
      );
    }
    return Result.captureAsync<Uint8List>(() async {
      final Stream<List<int>> stream = (await openEntry(path)).getOrThrow();
      final BytesBuilder bytes = BytesBuilder(copy: false);
      await for (final List<int> chunk in stream) {
        bytes.add(chunk);
      }
      return bytes.takeBytes();
    });
  }

  /// Cancels workers and streams and releases all package-owned plaintext.
  Future<void> close() async {
    _closed = true;
    _cancel.cancel();
    await _opening;
    _inventory = null;
    await _active?.dispose();
    if (await scratch.exists()) {
      await scratch.delete(recursive: true);
    }
  }
}

void _extractEntry(List<Object> job) {
  final WorkerCancellation cancellation = WorkerCancellation(
    job[4] as SendPort,
    lease: File(job[5] as String),
  );
  InputFileStream? input;
  try {
    cancellation.check();
    input = InputFileStream(job[0] as String);
    final ArchiveFile entry = (job[1] as BundleZipEntry).open(input);
    final String actual = BundleArchiveStream.extract(
      entry,
      File(job[3] as String),
      checkpoint: cancellation.check,
    );
    cancellation.check();
    if (actual != job[2]) {
      throw CorruptionFailure(
        localizedMessage: Copy.messages.failureThePackageEntryChecksumChanged,
      );
    }
  } finally {
    input?.closeSync();
    cancellation.close();
  }
}

Map<String, BundleZipEntry> _readInventory(List<Object> job) {
  final String source = job[0] as String;
  final WorkerCancellation cancellation = WorkerCancellation(
    job[1] as SendPort,
    lease: File(job[2] as String),
  );
  RandomAccessFile? file;
  InputFileStream? input;
  try {
    cancellation.check();
    final RandomAccessFile reader = File(source).openSync();
    file = reader;
    final int length = reader.lengthSync();
    if (length > AppConstants.bundles.nativeMaxBytes ||
        checkZipDirectory(
              length: length,
              read: (int offset, int count) {
                cancellation.check();
                reader.setPositionSync(offset);
                return reader.readSync(count);
              },
              maxUncompressed: AppConstants.bundles.nativeMaxUncompressedBytes,
            ) !=
            null) {
      throw const FormatException('Unsafe package ZIP directory.');
    }
    final Map<String, BundleZipEntry> inventory = <String, BundleZipEntry>{};
    input = InputFileStream(source);
    BundleArchiveStream.decode(
      input,
      inventory: inventory,
      checkpoint: cancellation.check,
    );
    cancellation.check();
    return inventory;
  } finally {
    input?.closeSync();
    file?.closeSync();
    cancellation.close();
  }
}

final class _EntryFileStream {
  _EntryFileStream(this.file, this.directory, this.onDispose) {
    _events = StreamController<List<int>>(
      sync: true,
      onListen: _listen,
      onPause: () => _input?.pause(),
      onResume: () => _input?.resume(),
      onCancel: dispose,
    );
  }
  final File file;
  final Directory directory;
  final void Function() onDispose;
  late final StreamController<List<int>> _events;
  StreamSubscription<List<int>>? _input;
  Future<void>? _disposing;
  Stream<List<int>> get stream => _events.stream;

  void _listen() {
    if (_disposing != null) {
      unawaited(_events.close());
      return;
    }
    _input = file.openRead().listen(
      _events.add,
      onError: (Object error, StackTrace stack) {
        _events.addError(Failure.from(error), stack);
        unawaited(dispose());
      },
      onDone: () => unawaited(dispose()),
    );
  }

  Future<void> dispose() => _disposing ??= _dispose();
  Future<void> _dispose() async {
    await _input?.cancel();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    onDispose();
    if (!_events.isClosed) {
      unawaited(_events.close());
    }
  }
}
