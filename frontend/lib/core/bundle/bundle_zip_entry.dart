import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;

/// Immutable checked ZIP offsets, with no file handle or inflated-byte cache.
/// Native inspection transfers these values once to subsequent entry workers.
final class BundleZipEntry {
  BundleZipEntry._({
    required this.path,
    required this.size,
    required this.compression,
    required this.crc32,
    required this.sourceLength,
    required this.headerOffset,
    required this.dataOffset,
    required this.compressedSize,
    required this.headerDigest,
    required this.descriptorLength,
    required this.descriptorDigest,
  });

  /// Manifest-relative entry name, also checked against the local header.
  final String path;

  /// Central-directory uncompressed byte count.
  final int size;

  /// Supported STORE or DEFLATE method.
  final int compression;

  /// Central-directory checksum, checked against the actual decoded output.
  final int crc32;

  /// Checked total archive length.
  final int sourceLength;

  /// Local-header offset within the checked archive.
  final int headerOffset;

  /// First compressed data byte, after the local name and extra fields.
  final int dataOffset;

  /// Exact central-directory compressed length.
  final int compressedSize;

  /// Digest of the bounded local header, including its name and extra fields.
  final String headerDigest;

  /// Length of the optional trailing ZIP data descriptor.
  final int descriptorLength;

  /// Digest of the descriptor, checked against its central-directory values.
  final String? descriptorDigest;

  /// Captures consistent local and central metadata without inflating bytes.
  static BundleZipEntry capture(
    ZipFileHeader header,
    InputStreamBase input,
    int sourceLength,
  ) {
    final int offset = header.localHeaderOffset!;
    final ByteData local = ByteData.sublistView(
      _slice(input, offset, 30, sourceLength),
    );
    final int flags = local.getUint16(6, Endian.little);
    final int method = local.getUint16(8, Endian.little);
    final int localCrc = local.getUint32(14, Endian.little);
    final int localCompressed = local.getUint32(18, Endian.little);
    final int localSize = local.getUint32(22, Endian.little);
    final int nameLength = local.getUint16(26, Endian.little);
    final int extraLength = local.getUint16(28, Endian.little);
    final int dataOffset = offset + 30 + nameLength + extraLength;
    final Uint8List localHeader = _slice(
      input,
      offset,
      dataOffset - offset,
      sourceLength,
    );
    if (local.getUint32(0, Endian.little) != 0x04034b50 ||
        flags != header.generalPurposeBitFlag ||
        method != header.compressionMethod ||
        utf8.decode(Uint8List.sublistView(localHeader, 30, 30 + nameLength)) !=
            header.filename) {
      throw const FormatException('Inconsistent package ZIP headers.');
    }
    final int compressed = header.compressedSize!;
    final int size = header.uncompressedSize!;
    final int crc = header.crc32!;
    if (compressed < 0 || size < 0 || dataOffset + compressed > sourceLength) {
      throw const FormatException('Invalid package ZIP entry bounds.');
    }
    // With bit 3, local sizes/CRC can be zero until the trailing descriptor.
    // ZIP64 sentinel fields are resolved from the local extended-size record.
    final bool deferred = flags & 8 != 0;
    int localSize64 = localSize;
    int localCompressed64 = localCompressed;
    if (localSize == 0xffffffff || localCompressed == 0xffffffff) {
      final InputStream extra = InputStream(
        Uint8List.sublistView(localHeader, 30 + nameLength),
      );
      bool found = false;
      while (extra.length >= 4) {
        final int id = extra.readUint16();
        final int count = extra.readUint16();
        if (count > extra.length) {
          throw const FormatException('Truncated ZIP64 entry size.');
        }
        final InputStreamBase field = extra.readBytes(count);
        if (id == 1) {
          final int needed =
              (localSize == 0xffffffff ? 8 : 0) +
              (localCompressed == 0xffffffff ? 8 : 0);
          if (field.length < needed) {
            throw const FormatException('Missing ZIP64 entry size.');
          }
          if (localSize == 0xffffffff) localSize64 = field.readUint64();
          if (localCompressed == 0xffffffff) {
            localCompressed64 = field.readUint64();
          }
          found = true;
          break;
        }
      }
      if (!found) throw const FormatException('Missing ZIP64 entry size.');
    }
    if ((localCrc != crc && !(deferred && localCrc == 0)) ||
        (localSize64 != size && !(deferred && localSize64 == 0)) ||
        (localCompressed64 != compressed &&
            !(deferred && localCompressed64 == 0))) {
      throw const FormatException('Inconsistent package ZIP entry sizes.');
    }
    int descriptorLength = 0;
    String? descriptorDigest;
    if (deferred) {
      final int descriptorOffset = dataOffset + compressed;
      final ByteData prefix = ByteData.sublistView(
        _slice(input, descriptorOffset, 4, sourceLength),
      );
      final bool signature = prefix.getUint32(0, Endian.little) == 0x08074b50;
      final bool zip64 =
          localSize == 0xffffffff || localCompressed == 0xffffffff;
      descriptorLength = (signature ? 4 : 0) + (zip64 ? 20 : 12);
      final Uint8List raw = _slice(
        input,
        descriptorOffset,
        descriptorLength,
        sourceLength,
      );
      final ByteData values = ByteData.sublistView(raw);
      final int start = signature ? 4 : 0;
      final int actualCompressed = zip64
          ? values.getUint64(start + 4, Endian.little)
          : values.getUint32(start + 4, Endian.little);
      final int actualSize = zip64
          ? values.getUint64(start + 12, Endian.little)
          : values.getUint32(start + 8, Endian.little);
      if (values.getUint32(start, Endian.little) != crc ||
          actualCompressed != compressed ||
          actualSize != size) {
        throw const FormatException('Inconsistent package ZIP descriptor.');
      }
      descriptorDigest = crypto.sha256.convert(raw).toString();
    }
    return BundleZipEntry._(
      path: header.filename,
      size: size,
      compression: method,
      crc32: crc,
      sourceLength: sourceLength,
      headerOffset: offset,
      dataOffset: dataOffset,
      compressedSize: compressed,
      headerDigest: crypto.sha256.convert(localHeader).toString(),
      descriptorLength: descriptorLength,
      descriptorDigest: descriptorDigest,
    );
  }

  /// Opens only this checked range, rejecting changed local metadata or bounds.
  /// Actual decoded length, CRC and manifest SHA are still checked separately.
  ArchiveFile open(InputStreamBase input) {
    if (input.length != sourceLength ||
        crypto.sha256
                .convert(
                  _slice(
                    input,
                    headerOffset,
                    dataOffset - headerOffset,
                    sourceLength,
                  ),
                )
                .toString() !=
            headerDigest ||
        (descriptorLength != 0 &&
            crypto.sha256
                    .convert(
                      _slice(
                        input,
                        dataOffset + compressedSize,
                        descriptorLength,
                        sourceLength,
                      ),
                    )
                    .toString() !=
                descriptorDigest)) {
      throw const FormatException('The package ZIP entry changed.');
    }
    return ArchiveFile(
      path,
      size,
      input.subset(dataOffset, compressedSize),
      compression,
    )..crc32 = crc32;
  }
}

Uint8List _slice(InputStreamBase input, int offset, int count, int length) {
  if (offset < 0 || count < 0 || offset + count > length) {
    throw const FormatException('Truncated package ZIP entry.');
  }
  final Uint8List bytes = input.subset(offset, count).toUint8List();
  if (bytes.length != count) {
    throw const FormatException('Truncated package ZIP entry.');
  }
  return bytes;
}
