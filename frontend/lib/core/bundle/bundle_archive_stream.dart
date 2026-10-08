import 'dart:convert';
import 'dart:io' show File, FileMode, RandomAccessFile;
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:tapture/core/constants/app_constants.dart';

import 'bundle_zip_entry.dart';

export 'bundle_zip_entry.dart';

/// Bounded ZIP entry decoding without ArchiveFile.content's persistent cache.
/// Each use gets an independent view of the compressed source.
abstract final class BundleArchiveStream {
  /// Opens only ordinary stored/DEFLATE ZIP entries. Password protection uses
  /// the authenticated bundle envelope, never opaque entry-level encryption.
  static Archive decode(
    InputStream input, {
    Map<String, BundleZipEntry>? inventory,
    void Function()? checkpoint,
  }) {
    checkpoint?.call();
    final int sourceLength = input.length;
    final ZipDecoder decoder = ZipDecoder();
    final Archive archive = decoder.decodeStream(input);
    final Set<String> names = <String>{};
    for (final ZipFileHeader header in decoder.directory.fileHeaders) {
      checkpoint?.call();
      if (!names.add(header.filename) ||
          header.generalPurposeBitFlag & 1 != 0 ||
          header.file!.flags & 1 != 0 ||
          (header.compressionMethod != ZipFile.zipCompressionStore &&
              header.compressionMethod != ZipFile.zipCompressionDeflate) ||
          header.file!.compressionMethod !=
              (header.compressionMethod == ZipFile.zipCompressionStore
                  ? CompressionType.none
                  : CompressionType.deflate)) {
        throw const FormatException('Unsupported protected ZIP entry.');
      }
      final BundleZipEntry entry = BundleZipEntry.capture(
        header,
        input,
        sourceLength,
      );
      if (archive.findFile(entry.path)!.isFile) {
        inventory?[entry.path] = entry;
      }
    }
    return archive;
  }

  /// Hashes an entry using a fixed-size buffer, refusing actual-size overflow.
  static String checksum(ArchiveFile entry, {void Function()? checkpoint}) =>
      _decode(entry, null, null, checkpoint);

  /// Extracts into a generated sandbox file and hashes in the same bounded pass.
  static String extract(
    ArchiveFile entry,
    File target, {
    void Function()? checkpoint,
  }) => _decode(entry, target, null, checkpoint);

  /// Reads one metadata entry or compatibility byte request, with the actual
  /// output bounded by its declared size. The archive retains no inflated data.
  static Uint8List bytes(ArchiveFile entry, {int? maximum}) {
    if (entry.size > (maximum ?? AppConstants.imports.bundleMaxBytes)) {
      throw const FormatException('The package metadata entry is too large.');
    }
    final BytesBuilder bytes = BytesBuilder(copy: false);
    _decode(entry, null, bytes, null);
    return bytes.takeBytes();
  }
}

String _decode(
  ArchiveFile entry,
  File? target,
  BytesBuilder? bytes,
  void Function()? checkpoint,
) {
  checkpoint?.call();
  if (entry.compression != CompressionType.none &&
      entry.compression != CompressionType.deflate) {
    throw const FormatException('Unsupported package compression.');
  }
  final FileContent? raw = entry.rawContent;
  if (raw == null) {
    throw const FormatException('Missing compressed entry.');
  }
  final _EntryOutput output = _EntryOutput(
    entry.size,
    target,
    bytes,
    checkpoint,
  );
  try {
    final InputStream source = raw.getStream(decompress: false).subset();
    if (entry.compression == CompressionType.deflate) {
      // Archive's native ZLibDecoder collects expanded bytes before dispatch.
      // The maintained Dart inflater writes directly into our bounded output.
      Inflate.stream(source, output: output);
    } else {
      output.writeStream(source);
    }
    if (output.length != entry.size) {
      throw const FormatException('Invalid package entry length.');
    }
    final String digest = output.finish();
    if (entry.crc32 != null && output.crc32 != entry.crc32) {
      throw const FormatException('Invalid package ZIP entry checksum.');
    }
    return digest;
  } finally {
    output.closeSync();
  }
}

final class _EntryOutput extends OutputStream {
  _EntryOutput(this.maximum, File? target, this.bytes, this.checkpoint)
    : file = target?.openSync(mode: FileMode.write),
      buffer = Uint8List(AppConstants.hashing.chunkBytes),
      super(byteOrder: ByteOrder.littleEndian) {
    sink = crypto.sha256.startChunkedConversion(digest);
  }
  final int maximum;
  final RandomAccessFile? file;
  final BytesBuilder? bytes;
  final void Function()? checkpoint;
  final Uint8List buffer;
  // DEFLATE dictionary lookbacks are bounded to 32 KiB. Inflate.stream uses
  // OutputFileStream's public subset contract; retaining that window avoids
  // reading back a temporary file or retaining the whole inflated entry.
  final Uint8List _history = Uint8List(32768);
  int _historyOffset = 0;
  final _DigestSink digest = _DigestSink();
  late final ByteConversionSink sink;
  int _used = 0;
  int _length = 0;
  bool _finished = false;
  int crc32 = 0;

  @override
  int get length => _length;

  void _reserve(int count) {
    if (count < 0 || _length + count > maximum) {
      throw const FormatException('Package entry exceeds its declared size.');
    }
    _length += count;
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    buffer[_used++] = value;
    _history[_historyOffset] = value;
    _historyOffset = (_historyOffset + 1) % _history.length;
    if (_used == buffer.length) {
      flush();
    }
  }

  @override
  void writeBytes(List<int> value, {int? length}) {
    final int count = length ?? value.length;
    _reserve(count);
    _remember(value, count);
    int offset = 0;
    while (offset < count) {
      final int available = buffer.length - _used;
      final int take = count - offset < available ? count - offset : available;
      buffer.setRange(_used, _used + take, value, offset);
      _used += take;
      offset += take;
      if (_used == buffer.length) {
        flush();
      }
    }
  }

  void _remember(List<int> value, int count) {
    int offset = 0;
    while (offset < count) {
      final int available = _history.length - _historyOffset;
      final int take = count - offset < available ? count - offset : available;
      _history.setRange(_historyOffset, _historyOffset + take, value, offset);
      _historyOffset = (_historyOffset + take) % _history.length;
      offset += take;
    }
  }

  /// Archive's Inflate.stream resolves dictionary ranges through this method.
  @override
  Uint8List subset(int start, [int? end]) {
    final int first = start < 0 ? _length + start : start;
    final int last = end == null
        ? _length
        : end < 0
        ? _length + end
        : end;
    if (first < 0 ||
        first < _length - _history.length ||
        last > _length ||
        last < first) {
      throw const FormatException('Invalid package compression dictionary.');
    }
    final Uint8List bytes = Uint8List(last - first);
    final int offset = first % _history.length;
    final int available = _history.length - offset;
    final int prefix = bytes.length < available ? bytes.length : available;
    bytes.setRange(0, prefix, _history, offset);
    if (prefix < bytes.length) {
      bytes.setRange(prefix, bytes.length, _history);
    }
    return bytes;
  }

  @override
  void writeStream(InputStream input) {
    while (!input.isEOS) {
      final int count = input.length < buffer.length
          ? input.length
          : buffer.length;
      writeBytes(input.readBytes(count).toUint8List());
    }
  }

  @override
  void writeUint16(int value) => _writeInteger(value, 2);

  @override
  void writeUint32(int value) => _writeInteger(value, 4);

  @override
  void writeUint64(int value) => _writeInteger(value, 8);

  void _writeInteger(int value, int count) {
    for (int byte = 0; byte < count; byte++) {
      writeByte((value >> (byte * 8)) & 0xff);
    }
  }

  @override
  void flush() {
    checkpoint?.call();
    if (_used == 0) {
      return;
    }
    final Uint8List chunk = Uint8List.sublistView(buffer, 0, _used);
    crc32 = getCrc32(chunk, crc32);
    sink.add(chunk);
    file?.writeFromSync(chunk);
    // Byte requests own their chunks; streamed checksum/extraction reuses one.
    bytes?.add(Uint8List.fromList(chunk));
    _used = 0;
  }

  String finish() {
    flush();
    sink.close();
    _finished = true;
    return digest.value.toString();
  }

  @override
  void clear() => throw UnsupportedError('Package streams cannot be reset.');

  @override
  Future<void> close() async => closeSync();

  @override
  void closeSync() {
    if (!_finished) {
      sink.close();
    }
    file?.closeSync();
  }
}

final class _DigestSink implements Sink<crypto.Digest> {
  late crypto.Digest value;
  @override
  void add(crypto.Digest data) => value = data;
  @override
  void close() {}
}
