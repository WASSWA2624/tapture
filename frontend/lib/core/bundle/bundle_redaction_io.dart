import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/file_validation.dart';

import 'bundle_payload_scanner.dart';
import 'bundle_redaction.dart';

/// Scans ZIP attachments through bounded temporary streams in a worker.
/// Nested content uses generated local names and is always removed, including
/// on cancellation. Opaque encrypted archives cannot pass the secret check.
void scanNestedBundleArchive(
  File source,
  BundleRedaction redaction, {
  required void Function() check,
  Directory? temporaryRoot,
}) {
  final RandomAccessFile handle = source.openSync();
  final bool archive;
  try {
    archive = looksLikeZip(handle.readSync(4));
  } finally {
    handle.closeSync();
  }
  if (!archive) {
    return;
  }
  final Directory temporary = (temporaryRoot ?? Directory.systemTemp)
      .createTempSync('tapture-scan-');
  try {
    _ArchiveScanner(redaction, temporary, check).scan(source, 0);
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

final class _ArchiveScanner {
  _ArchiveScanner(this.redaction, this.temporary, this.check);
  final BundleRedaction redaction;
  final Directory temporary;
  final void Function() check;
  int _expanded = 0;

  void scan(File file, int depth) {
    check();
    if (depth >= 4) {
      throw ValidationFailure(
        localizedMessage:
            Copy.messages.failureTheBundleHasTooManyNestedArchives,
      );
    }
    final RandomAccessFile directory = file.openSync();
    try {
      final ArchiveProblem? problem = checkZipDirectory(
        length: directory.lengthSync(),
        read: (int offset, int length) {
          check();
          directory.setPositionSync(offset);
          return directory.readSync(length);
        },
        maxUncompressed:
            AppConstants.imports.archiveUncompressedMaxBytes - _expanded,
      );
      if (problem != null) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureANestedBundleArchiveCouldNotBe,
        );
      }
    } finally {
      directory.closeSync();
    }
    final InputFileStream input = InputFileStream(file.path);
    try {
      final ZipDecoder decoder = ZipDecoder();
      final Archive archive = decoder.decodeStream(input);
      for (final ZipFileHeader header in decoder.directory.fileHeaders) {
        if (header.generalPurposeBitFlag & 1 != 0 ||
            header.file!.flags & 1 != 0 ||
            (header.compressionMethod != ZipFile.zipCompressionStore &&
                header.compressionMethod != ZipFile.zipCompressionDeflate)) {
          throw ValidationFailure(
            localizedMessage:
                Copy.messages.failureAnEncryptedOrUnsupportedAttachmentCouldNot,
          );
        }
      }
      for (final ArchiveFile entry in archive.files) {
        check();
        redaction.assertClean(entry.name);
        if (!entry.isFile) {
          continue;
        }
        _expanded += entry.size;
        if (_expanded > AppConstants.imports.archiveUncompressedMaxBytes) {
          throw ValidationFailure(
            localizedMessage:
                Copy.messages.failureANestedBundleArchiveIsTooLarge,
          );
        }
        final Directory entryScratch = temporary.createTempSync('entry-');
        final File extracted = File('${entryScratch.path}/content');
        final _LimitedOutput output = _LimitedOutput(
          extracted.path,
          entry.size,
          check,
        );
        try {
          try {
            // Reuse the compressed stream, bypassing ArchiveFile.content, which
            // would inflate the entire attachment in memory.
            entry.rawContent!.decompress(output);
            if (output.length != entry.size) {
              throw ValidationFailure(
                localizedMessage:
                    Copy.messages.failureANestedBundleEntryHasAnInvalid,
              );
            }
          } finally {
            output.closeSync();
          }
          _scanPlain(extracted);
          final RandomAccessFile prefix = extracted.openSync();
          final bool nested;
          try {
            nested = looksLikeZip(prefix.readSync(4));
          } finally {
            prefix.closeSync();
          }
          if (nested) {
            scan(extracted, depth + 1);
          }
        } finally {
          entryScratch.deleteSync(recursive: true);
        }
      }
    } finally {
      input.closeSync();
    }
  }

  void _scanPlain(File file) {
    final RandomAccessFile input = file.openSync();
    try {
      final BundlePayloadScanner scanner = redaction.payloadScanner();
      while (true) {
        check();
        final Uint8List chunk = input.readSync(AppConstants.hashing.chunkBytes);
        if (chunk.isEmpty) {
          break;
        }
        scanner.add(chunk);
      }
      scanner.finish();
    } finally {
      input.closeSync();
    }
  }
}

final class _LimitedOutput extends OutputFileStream {
  _LimitedOutput(String path, this.maximum, this.check)
    : super.withFileHandle(
        FileHandle(path, mode: FileAccess.write),
        bufferSize: AppConstants.hashing.chunkBytes,
      );
  final int maximum;
  final void Function() check;

  void _reserve(int count) {
    if (length + count > maximum) {
      throw ValidationFailure(
        localizedMessage:
            Copy.messages.failureANestedBundleEntryExceedsItsDeclared,
      );
    }
    if (length ~/ AppConstants.hashing.chunkBytes !=
        (length + count) ~/ AppConstants.hashing.chunkBytes) {
      check();
    }
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _reserve(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      check();
      writeBytes(
        stream
            .readBytes(stream.length.clamp(0, AppConstants.hashing.chunkBytes))
            .toUint8List(),
      );
    }
  }
}
