import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'archive_problem.dart';
import 'picked_document.dart';

export 'archive_problem.dart';

/// Supported photo format from its bytes, shared with capture intake.
String? imageExtensionFromHeader(Uint8List header) {
  for (final String extension in const <String>['jpg', 'png', 'webp']) {
    if (_magicMatches(ImportKind.image, extension, header)) return extension;
  }
  return null;
}

/// Checks image metadata and an optional bounded prefix before a full read.
Result<ImportKind> validatePickedImage({
  required String name,
  required int byteLength,
  Uint8List? header,
}) => Result.capture(() {
  final ImportKind kind = _metadataKind(name, byteLength, const <ImportKind>{
    ImportKind.image,
  });
  if (header != null && !_magicMatches(kind, _extension(name), header)) {
    throw _mismatch(name);
  }
  return kind;
});

/// The one gate every file from outside the app passes before a parser sees
/// it: extension, magic bytes, size and archive structure (FE-SEC-06).
abstract interface class FileValidation {
  /// Creates the validator. It never copies [file] and never opens a parser.
  factory FileValidation() = _FileValidation;

  /// Extension, size and magic bytes. [allowed] is the kinds this call will
  /// accept. Archives are walked for traversal, links and zip-bomb size.
  Future<Result<ImportKind>> validate(
    File file, {
    required Set<ImportKind> allowed,
  });

  /// The same gate for a document the operator picked: a file on a device,
  /// judged by the name they chose rather than the picker's copy, or the
  /// bytes a browser hands over. Nothing is parsed before this passes.
  Future<Result<ImportKind>> validateDocument(
    PickedDocument document, {
    required Set<ImportKind> allowed,
  });

  /// Walks a ZIP central directory. Rejects absolute paths, `..` segments,
  /// symlinks and a declared uncompressed total above the ceiling.
  /// [maxBytes] and [maxUncompressed] replace the import ceilings for a
  /// caller with its own, such as a project package (task 076, D6).
  Future<Result<void>> validateArchive(
    File archive, {
    int? maxBytes,
    int? maxUncompressed,
  });
}

/// Walks the ZIP central directory of the [length] bytes [read] returns
/// (`read(offset, count)` hands back exactly [count] bytes or fewer at the
/// end), and reports the first [ArchiveProblem], or null when the directory
/// is safe to extract. The one walk behind [FileValidation.validateArchive]
/// and the project package reader, over a file or over bytes in memory.
ArchiveProblem? checkZipDirectory({
  required int length,
  required Uint8List Function(int offset, int count) read,
  required int maxUncompressed,
}) {
  if (length < _eocdMin) {
    return ArchiveProblem.notArchive;
  }
  final ({int offset, int size, int entries})? eocd = _eocdOf(read, length);
  if (eocd == null ||
      eocd.offset < 0 ||
      eocd.size < 0 ||
      eocd.offset + eocd.size > length) {
    return ArchiveProblem.notArchive;
  }
  var position = eocd.offset;
  var totalUncompressed = 0;
  for (var seen = 0; seen < eocd.entries; seen++) {
    final Uint8List head = read(position, _cdHead);
    if (head.length < _cdHead || !_prefix(head, _cdSig)) {
      return ArchiveProblem.notArchive;
    }
    final int madeBy = _u16(head, 4);
    final int nameLen = _u16(head, 28);
    final int extraLen = _u16(head, 30);
    final int commentLen = _u16(head, 32);
    final int external = _u32(head, 38);
    final int uncompressed = _u32(head, 24);
    final Uint8List nameBytes = nameLen == 0
        ? Uint8List(0)
        : read(position + _cdHead, nameLen);
    if (nameBytes.length < nameLen) {
      return ArchiveProblem.notArchive;
    }
    position += _cdHead + nameLen + extraLen + commentLen;
    final String name;
    try {
      name = utf8.decode(nameBytes);
    } on FormatException {
      return ArchiveProblem.unsafePath;
    }
    if (_escapes(name)) {
      return ArchiveProblem.unsafePath;
    }
    if (_isSymlink(madeBy, external)) {
      return ArchiveProblem.link;
    }
    if (uncompressed == 0xFFFFFFFF) {
      return ArchiveProblem.tooLarge;
    }
    totalUncompressed += uncompressed;
    if (totalUncompressed > maxUncompressed) {
      return ArchiveProblem.tooLarge;
    }
  }
  return null;
}

/// Whether [header] opens the way a ZIP file does.
bool looksLikeZip(Uint8List header) => _isZip(header);

/// Kinds an imported file may claim, from its extension then its bytes.
enum ImportKind {
  /// A photograph (JPEG, PNG or WebP).
  image,

  /// A PDF document.
  document,

  /// An XLSX workbook, or a CSV or JSON table.
  spreadsheet,

  /// Recorded audio (WAV, M4A or MP3).
  audio,

  /// A project bundle ZIP.
  bundle,
}

final class _FileValidation implements FileValidation {
  const _FileValidation();

  @override
  Future<Result<ImportKind>> validate(
    File file, {
    required Set<ImportKind> allowed,
  }) {
    return Result.captureAsync(() async {
      return _fileGate(file, name: _basename(file.path), allowed: allowed);
    });
  }

  @override
  Future<Result<ImportKind>> validateDocument(
    PickedDocument document, {
    required Set<ImportKind> allowed,
  }) {
    return Result.captureAsync(() async {
      switch (document) {
        case PickedFile(:final File file):
          return _fileGate(file, name: document.name, allowed: allowed);
        case PickedBytes(:final Uint8List bytes):
          return _gate(
            name: document.name,
            length: bytes.length,
            allowed: allowed,
            header: () => Uint8List.sublistView(
              bytes,
              0,
              min(AppConstants.imports.sniffHeaderBytes, bytes.length),
            ),
            walk: (int maxUncompressed) => _throwOn(
              checkZipDirectory(
                length: bytes.length,
                read: (int offset, int count) => Uint8List.sublistView(
                  bytes,
                  offset,
                  min(offset + count, bytes.length),
                ),
                maxUncompressed: maxUncompressed,
              ),
              document.name,
            ),
          );
      }
    });
  }

  @override
  Future<Result<void>> validateArchive(
    File archive, {
    int? maxBytes,
    int? maxUncompressed,
  }) {
    return Result.captureAsync(() async {
      final String name = _basename(archive.path);
      if (!archive.existsSync()) {
        throw _missing(name);
      }
      final int length = archive.lengthSync();
      if (length < _eocdMin) {
        throw _notArchive(name);
      }
      if (length > (maxBytes ?? AppConstants.imports.bundleMaxBytes)) {
        throw _oversized(name, ImportKind.bundle);
      }
      final Uint8List header = _sniff(archive, length);
      if (!_isZip(header)) {
        throw _notArchive(name);
      }
      _walkZip(
        archive,
        name,
        length,
        maxUncompressed ?? AppConstants.imports.archiveUncompressedMaxBytes,
      );
    });
  }
}

/// [_gate] over a file on disk, reported under [name].
ImportKind _fileGate(
  File file, {
  required String name,
  required Set<ImportKind> allowed,
}) {
  if (!file.existsSync()) {
    throw _missing(name);
  }
  final int length = file.lengthSync();
  return _gate(
    name: name,
    length: length,
    allowed: allowed,
    header: () => _sniff(file, length),
    walk: (int maxUncompressed) =>
        _walkZip(file, name, length, maxUncompressed),
  );
}

/// The one rule every source passes: not empty, a kind [allowed] by its
/// extension, within that kind's ceiling, magic bytes that agree with the
/// name, and for an archive a safe central directory ([walk]). [header]
/// reads a bounded prefix only (FE-PERF-07).
ImportKind _gate({
  required String name,
  required int length,
  required Set<ImportKind> allowed,
  required Uint8List Function() header,
  required void Function(int maxUncompressed) walk,
}) {
  final ImportKind kind = _metadataKind(name, length, allowed);
  final String ext = _extension(name);
  if (!_magicMatches(kind, ext, header())) {
    throw _mismatch(name);
  }
  if (_isArchiveKind(kind, ext)) {
    walk(AppConstants.imports.archiveUncompressedMaxBytes);
  }
  return kind;
}

ImportKind _metadataKind(String name, int length, Set<ImportKind> allowed) {
  if (length <= 0) {
    throw _empty(name);
  }
  final String ext = _extension(name);
  final ImportKind? kind = _kinds[ext];
  if (kind == null || !allowed.contains(kind)) {
    throw _unsupported(name);
  }
  if (length > _ceiling(kind)) {
    throw _oversized(name, kind);
  }
  return kind;
}

int _ceiling(ImportKind kind) {
  switch (kind) {
    case ImportKind.image:
      return AppConstants.imports.imageMaxBytes;
    case ImportKind.document:
      return AppConstants.imports.documentMaxBytes;
    case ImportKind.spreadsheet:
      return AppConstants.imports.spreadsheetMaxBytes;
    case ImportKind.audio:
      return AppConstants.imports.audioMaxBytes;
    case ImportKind.bundle:
      return AppConstants.imports.bundleMaxBytes;
  }
}

bool _isArchiveKind(ImportKind kind, String ext) {
  return kind == ImportKind.bundle ||
      (kind == ImportKind.spreadsheet && ext == 'xlsx');
}

Uint8List _sniff(File file, int length) {
  final int n = min(AppConstants.imports.sniffHeaderBytes, length);
  final RandomAccessFile raf = file.openSync();
  try {
    final Uint8List buffer = Uint8List(n);
    var filled = 0;
    while (filled < n) {
      final int got = raf.readIntoSync(buffer, filled);
      if (got == 0) {
        break;
      }
      filled += got;
    }
    if (filled == n) {
      return buffer;
    }
    return Uint8List.sublistView(buffer, 0, filled);
  } finally {
    raf.closeSync();
  }
}

bool _magicMatches(ImportKind kind, String ext, Uint8List header) {
  switch (kind) {
    case ImportKind.image:
      if (ext == 'png') {
        return _prefix(header, _png);
      }
      if (ext == 'jpg' || ext == 'jpeg') {
        return _prefix(header, _jpeg);
      }
      if (ext == 'webp') {
        return _isWebp(header);
      }
      return false;
    case ImportKind.document:
      return _prefix(header, _pdf);
    case ImportKind.spreadsheet:
      if (ext == 'xlsx') {
        return _isZip(header);
      }
      return !_isZip(header) &&
          !_prefix(header, _mz) &&
          !_prefix(header, _pdf) &&
          !_prefix(header, _jpeg) &&
          !_prefix(header, _png);
    case ImportKind.audio:
      if (ext == 'wav') {
        return _isWav(header);
      }
      if (ext == 'm4a') {
        return _isFtyp(header);
      }
      if (ext == 'mp3') {
        return _isMp3(header);
      }
      return false;
    case ImportKind.bundle:
      return _isZip(header);
  }
}

void _walkZip(File archive, String name, int length, int maxUncompressed) {
  final RandomAccessFile raf = archive.openSync();
  try {
    _throwOn(
      checkZipDirectory(
        length: length,
        read: (int offset, int count) => _readAt(raf, offset, count),
        maxUncompressed: maxUncompressed,
      ),
      name,
    );
  } finally {
    raf.closeSync();
  }
}

/// Throws the refusal [problem] names for the archive called [name].
void _throwOn(ArchiveProblem? problem, String name) {
  switch (problem) {
    case null:
      return;
    case ArchiveProblem.notArchive:
      throw _notArchive(name);
    case ArchiveProblem.unsafePath:
      throw _traversal(name);
    case ArchiveProblem.link:
      throw _symlink(name);
    case ArchiveProblem.tooLarge:
      throw _bomb(name);
  }
}

({int offset, int size, int entries})? _eocdOf(
  Uint8List Function(int offset, int count) read,
  int length,
) {
  final int window = min(length, _eocdMin + _maxComment);
  final Uint8List tail = read(length - window, window);
  for (var i = tail.length - _eocdMin; i >= 0; i--) {
    if (!_prefixAt(tail, i, _eocdSig)) {
      continue;
    }
    final int comment = _u16(tail, i + 20);
    if (i + _eocdMin + comment != tail.length) {
      continue;
    }
    return (
      entries: _u16(tail, i + 10),
      size: _u32(tail, i + 12),
      offset: _u32(tail, i + 16),
    );
  }
  return null;
}

/// Up to [count] bytes of [raf] from [offset]; fewer only at the end.
Uint8List _readAt(RandomAccessFile raf, int offset, int count) {
  if (count <= 0) {
    return Uint8List(0);
  }
  raf.setPositionSync(offset);
  final Uint8List buffer = Uint8List(count);
  var filled = 0;
  while (filled < count) {
    final int got = raf.readIntoSync(buffer, filled);
    if (got == 0) {
      return Uint8List.sublistView(buffer, 0, filled);
    }
    filled += got;
  }
  return buffer;
}

bool _escapes(String name) {
  if (name.contains('\u0000')) {
    return true;
  }
  final String norm = name.replaceAll(r'\', '/');
  if (norm.startsWith('/') || _drive.hasMatch(norm)) {
    return true;
  }
  for (final String part in norm.split('/')) {
    if (part == '..') {
      return true;
    }
  }
  return false;
}

bool _isSymlink(int madeBy, int external) {
  if (madeBy >> 8 != _unixHost) {
    return false;
  }
  return ((external >> 16) & _ifmt) == _iflnk;
}

bool _prefix(Uint8List bytes, List<int> magic) {
  return _prefixAt(bytes, 0, magic);
}

bool _prefixAt(Uint8List bytes, int offset, List<int> magic) {
  if (offset < 0 || offset + magic.length > bytes.length) {
    return false;
  }
  for (var i = 0; i < magic.length; i++) {
    if (bytes[offset + i] != magic[i]) {
      return false;
    }
  }
  return true;
}

bool _isZip(Uint8List header) {
  return _prefix(header, _localSig) || _prefix(header, _eocdSig);
}

bool _isWebp(Uint8List header) {
  return _prefix(header, _riff) && _prefixAt(header, 8, _webp);
}

bool _isWav(Uint8List header) {
  return _prefix(header, _riff) && _prefixAt(header, 8, _wave);
}

bool _isFtyp(Uint8List header) {
  return _prefixAt(header, 4, _ftyp);
}

bool _isMp3(Uint8List header) {
  if (_prefix(header, _id3)) {
    return true;
  }
  if (header.length < 2 || header[0] != 0xFF) {
    return false;
  }
  final int b = header[1];
  return b == 0xFB || b == 0xF3 || b == 0xF2;
}

int _u16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _u32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

String _extension(String name) {
  final String base = _basename(name);
  final int dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) {
    return '';
  }
  return base.substring(dot + 1).toLowerCase();
}

String _basename(String path) {
  final String n = path.replaceAll(r'\', '/');
  final int slash = n.lastIndexOf('/');
  return slash == -1 ? n : n.substring(slash + 1);
}

/// [name]'s base name in quotes, as data (FE-SEC-05).
String _quoted(String name) {
  return '"${_basename(name).replaceAll('"', "'")}"';
}

ValidationFailure _empty(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages.failureTheFileValueIsEmpty(
      (_quoted(name)).toString(),
    ),
    localizedRecovery: DomainCopy.messages.failureChooseAFileThatHasContentsAnd,
  );
}

ValidationFailure _unsupported(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages.failureTheFileValueIsNotASupported(
      (_quoted(name)).toString(),
    ),
    localizedRecovery:
        DomainCopy.messages.failureChooseAnImageDocumentSpreadsheetAudioFile,
  );
}

ValidationFailure _mismatch(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages.failureTheFileValueDoesNotMatchIts(
      (_quoted(name)).toString(),
    ),
    localizedRecovery: DomainCopy.messages.failureChooseAFileOfTheExpectedType,
  );
}

ValidationFailure _oversized(String name, ImportKind kind) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages.failureTheFileValueIsLargerThanThe(
      (_quoted(name)).toString(),
      (_label(kind)).toString(),
    ),
    localizedRecovery: DomainCopy.messages.failureChooseASmallerFileAndTryAgain,
  );
}

ValidationFailure _traversal(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages
        .failureTheArchiveValueContainsAPathThat((_quoted(name)).toString()),
    localizedRecovery:
        DomainCopy.messages.failureChooseADifferentFileAndTryAgain,
  );
}

ValidationFailure _symlink(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages
        .failureTheArchiveValueContainsALinkInstead((_quoted(name)).toString()),
    localizedRecovery:
        DomainCopy.messages.failureChooseADifferentFileAndTryAgain,
  );
}

ValidationFailure _bomb(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages
        .failureTheArchiveValueDeclaresMoreUncompressedData(
          (_quoted(name)).toString(),
        ),
    localizedRecovery:
        DomainCopy.messages.failureChooseADifferentFileAndTryAgain,
  );
}

ValidationFailure _notArchive(String name) {
  return ValidationFailure(
    localizedMessage: DomainCopy.messages.failureTheFileValueIsNotAnArchive(
      (_quoted(name)).toString(),
    ),
    localizedRecovery:
        DomainCopy.messages.failureChooseAZIPBundleOrSpreadsheetAnd,
  );
}

StorageFailure _missing(String name) {
  return StorageFailure(
    localizedMessage: DomainCopy.messages.failureTaptureCouldNotFindValue(
      (_quoted(name)).toString(),
    ),
    localizedRecovery:
        DomainCopy.messages.failureChooseTheFileAgainThenTryAgain,
  );
}

String _label(ImportKind kind) {
  switch (kind) {
    case ImportKind.image:
      return 'image';
    case ImportKind.document:
      return 'document';
    case ImportKind.spreadsheet:
      return 'spreadsheet';
    case ImportKind.audio:
      return 'audio file';
    case ImportKind.bundle:
      return 'bundle';
  }
}

const Map<String, ImportKind> _kinds = <String, ImportKind>{
  'jpg': ImportKind.image,
  'jpeg': ImportKind.image,
  'png': ImportKind.image,
  'webp': ImportKind.image,
  'pdf': ImportKind.document,
  'xlsx': ImportKind.spreadsheet,
  'csv': ImportKind.spreadsheet,
  'json': ImportKind.spreadsheet,
  'wav': ImportKind.audio,
  'm4a': ImportKind.audio,
  'mp3': ImportKind.audio,
  'zip': ImportKind.bundle,
};

final RegExp _drive = RegExp(r'^[A-Za-z]:');

const List<int> _png = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const List<int> _jpeg = <int>[0xFF, 0xD8, 0xFF];
const List<int> _pdf = <int>[0x25, 0x50, 0x44, 0x46, 0x2D];
const List<int> _mz = <int>[0x4D, 0x5A];
const List<int> _riff = <int>[0x52, 0x49, 0x46, 0x46];
const List<int> _webp = <int>[0x57, 0x45, 0x42, 0x50];
const List<int> _wave = <int>[0x57, 0x41, 0x56, 0x45];
const List<int> _ftyp = <int>[0x66, 0x74, 0x79, 0x70];
const List<int> _id3 = <int>[0x49, 0x44, 0x33];
const List<int> _localSig = <int>[0x50, 0x4B, 0x03, 0x04];
const List<int> _cdSig = <int>[0x50, 0x4B, 0x01, 0x02];
const List<int> _eocdSig = <int>[0x50, 0x4B, 0x05, 0x06];

const int _eocdMin = 22;
const int _cdHead = 46;
const int _maxComment = 65535;
const int _unixHost = 3;
const int _ifmt = 0xF000;
const int _iflnk = 0xA000;
